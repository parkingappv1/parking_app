use actix_web::{
    Error, HttpRequest, ResponseError,
    body::EitherBody,
    cookie::{Cookie, SameSite},
    dev::{Service, ServiceRequest, ServiceResponse, Transform, forward_ready},
};
use futures::future::{LocalBoxFuture, Ready, ready};
use rand::Rng;
use rand::distr::Alphanumeric;
use std::collections::HashSet;
use std::env;
use std::sync::OnceLock;
use std::time::{SystemTime, UNIX_EPOCH};
use tracing::{debug, error, warn};

/// CSRF 配置常量
const CSRF_TOKEN_LENGTH: usize = 32;
// 24小时
const CSRF_TOKEN_EXPIRY_SECONDS: u64 = 86400;
const CSRF_HEADER_NAME: &str = "X-CSRF-Token";
const CSRF_COOKIE_NAME: &str = "csrf_token";
const FIXED_DEV_TOKEN: &str = "BlShzBuQSbEmx9jJictkKeKEUpa9OYmH-1747923404";

/// 环境检测结果缓存（线程安全）
static DEV_MODE_CACHE: OnceLock<bool> = OnceLock::new();

/// CSRFミドルウェア - クロスサイトリクエストフォージェリ攻撃を防御
#[derive(Debug, Clone)]
pub struct CsrfMiddleware {
    exempt_paths: HashSet<String>,
}

impl Default for CsrfMiddleware {
    fn default() -> Self {
        Self::new()
    }
}

impl CsrfMiddleware {
    /// 新しいCSRFミドルウェアインスタンスを作成
    pub fn new() -> Self {
        Self {
            exempt_paths: HashSet::new(),
        }
    }

    /// 指定されたパスをCSRFチェックから除外
    pub fn exempt<S: Into<String>>(mut self, path: S) -> Self {
        self.exempt_paths.insert(path.into());
        self
    }

    /// 複数のパスを一括で除外
    pub fn exempt_paths<I, S>(mut self, paths: I) -> Self
    where
        I: IntoIterator<Item = S>,
        S: Into<String>,
    {
        for path in paths {
            self.exempt_paths.insert(path.into());
        }
        self
    }

    /// 開発モードかどうかを判定（結果をキャッシュ）
    fn is_dev_mode() -> bool {
        *DEV_MODE_CACHE.get_or_init(|| {
            env::var("ENVIRONMENT")
                .map(|env| env.to_lowercase() == "development")
                .unwrap_or_else(|_| {
                    env::var("DEBUG_MODE")
                        .map(|debug| debug.to_lowercase() == "true")
                        .unwrap_or(false)
                })
        })
    }

    /// 新しいCSRFトークンを生成
    pub fn generate_token() -> String {
        if Self::is_dev_mode() {
            debug!("開発環境: 固定CSRFトークンを使用");
            return FIXED_DEV_TOKEN.to_string();
        }

        // 32文字のランダム文字列を生成
        let rand_string: String = rand::rng()
            .sample_iter(&Alphanumeric)
            .take(CSRF_TOKEN_LENGTH)
            .map(char::from)
            .collect();

        // 現在のタイムスタンプを取得
        let timestamp = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .map(|d| d.as_secs())
            .unwrap_or_default();

        let token = format!("{}-{}", rand_string, timestamp);
        debug!("新しいCSRFトークンを生成: 長さ={}", token.len());
        token
    }

    /// リクエストからCSRFトークンを取得（ヘッダーまたはクッキーから）
    pub fn extract_tokens_from_request(req: &HttpRequest) -> (Option<String>, Option<String>) {
        let header_token = req
            .headers()
            .get(CSRF_HEADER_NAME)
            .and_then(|h| h.to_str().ok())
            .map(String::from);

        let cookie_token = req.cookie(CSRF_COOKIE_NAME).map(|c| c.value().to_string());

        if header_token.is_some() {
            debug!("CSRFトークンをヘッダーから取得");
        }
        if cookie_token.is_some() {
            debug!("CSRFトークンをクッキーから取得");
        }
        if header_token.is_none() && cookie_token.is_none() {
            debug!("CSRFトークンが見つかりませんでした");
        }

        (header_token, cookie_token)
    }

    /// 開発モード用のトークン検証
    fn validate_dev_token(token: &str) -> bool {
        if token == FIXED_DEV_TOKEN {
            debug!("開発環境: 固定CSRFトークンが検証されました");
            true
        } else {
            false
        }
    }

    /// CSRFトークンを検証（ヘッダーとクッキーの一致を確認）
    pub fn validate_tokens(header_token: Option<&str>, cookie_token: Option<&str>) -> bool {
        if Self::is_dev_mode() {
            // 開発モードでは、どちらか一方が固定トークンであればOK
            return header_token.map_or(false, Self::validate_dev_token)
                || cookie_token.map_or(false, Self::validate_dev_token);
        }

        // 本番環境での検証
        match (header_token, cookie_token) {
            (Some(h), Some(c)) if !h.is_empty() && h == c => {
                if Self::validate_token_with_expiry(h) {
                    debug!("CSRFトークンが正常に検証されました");
                    true
                } else {
                    warn!("CSRFトークンが無効または期限切れです");
                    false
                }
            }
            (None, None) => {
                warn!("CSRFトークンが提供されていません");
                false
            }
            _ => {
                warn!("CSRFトークンが一致しないか不足しています");
                false
            }
        }
    }

    /// リクエストからCSRFトークンを検証
    pub fn validate_request(req: &HttpRequest) -> bool {
        let (header_token, cookie_token) = Self::extract_tokens_from_request(req);
        Self::validate_tokens(header_token.as_deref(), cookie_token.as_deref())
    }

    /// CSRFトークンクッキーを構築
    pub fn build_csrf_cookie(token: &str) -> Cookie<'static> {
        let is_dev = Self::is_dev_mode();
        debug!("CSRFクッキーを構築中（開発モード: {}）", is_dev);

        let max_age = if is_dev {
            actix_web::cookie::time::Duration::days(365)
        } else {
            actix_web::cookie::time::Duration::hours(24)
        };

        Cookie::build(CSRF_COOKIE_NAME, token.to_string())
            .http_only(false) // JavaScriptからアクセス可能
            .same_site(SameSite::Lax) // CSRF攻撃を防ぐ
            .path("/")
            .max_age(max_age)
            .secure(!is_dev) // 開発環境では false、本番では true
            .finish()
    }

    /// トークンの形式を検証
    pub fn is_valid_format(token: &str) -> bool {
        if token.is_empty() {
            return false;
        }

        // 開発モードの固定トークンは常に有効
        if Self::is_dev_mode() && token == FIXED_DEV_TOKEN {
            return true;
        }

        let parts: Vec<&str> = token.split('-').collect();
        if parts.len() != 2 {
            return false;
        }

        // 最初の部分は指定長の英数字である必要がある
        let token_part = parts[0];
        if token_part.len() != CSRF_TOKEN_LENGTH || !token_part.chars().all(|c| c.is_alphanumeric())
        {
            return false;
        }

        // 2番目の部分は有効なタイムスタンプである必要がある
        parts[1].parse::<u64>().is_ok()
    }

    /// トークンの有効期限をチェック
    pub fn is_token_expired(token: &str) -> bool {
        if !Self::is_valid_format(token) {
            return true;
        }

        // 開発モードの固定トークンは期限なし
        if Self::is_dev_mode() && token == FIXED_DEV_TOKEN {
            return false;
        }

        let parts: Vec<&str> = token.split('-').collect();
        if let Ok(token_timestamp) = parts[1].parse::<u64>() {
            let current_timestamp = SystemTime::now()
                .duration_since(UNIX_EPOCH)
                .map(|d| d.as_secs())
                .unwrap_or_default();

            let is_expired =
                current_timestamp.saturating_sub(token_timestamp) > CSRF_TOKEN_EXPIRY_SECONDS;
            if is_expired {
                debug!(
                    "CSRFトークンの有効期限が切れています (age: {}秒)",
                    current_timestamp.saturating_sub(token_timestamp)
                );
            }
            is_expired
        } else {
            true
        }
    }

    /// 有効期限チェック付きでトークンを検証
    pub fn validate_token_with_expiry(token: &str) -> bool {
        if !Self::is_valid_format(token) {
            warn!(
                "無効なCSRFトークン形式: {}",
                token.chars().take(10).collect::<String>()
            );
            return false;
        }

        if Self::is_token_expired(token) {
            warn!("CSRFトークンの有効期限が切れています");
            return false;
        }

        debug!("CSRFトークンが有効期限チェック付きで検証されました");
        true
    }
}

/// CSRFミドルウェアサービス実装
pub struct CsrfMiddlewareService<S> {
    service: S,
    exempt_paths: HashSet<String>,
}

impl<S, B> Service<ServiceRequest> for CsrfMiddlewareService<S>
where
    S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error>,
    S::Future: 'static,
    B: 'static,
{
    type Response = ServiceResponse<EitherBody<B>>;
    type Error = Error;
    type Future = LocalBoxFuture<'static, Result<Self::Response, Self::Error>>;

    forward_ready!(service);

    fn call(&self, req: ServiceRequest) -> Self::Future {
        let path = req.path();
        let method = req.method().clone();

        debug!("CSRFミドルウェア処理開始: {} {}", method, path);

        // 除外パスのチェック
        if self.exempt_paths.contains(path) {
            debug!("除外パス - CSRFチェックをスキップ: {}", path);
            let fut = self.service.call(req);
            return Box::pin(async move {
                let res = fut.await?;
                Ok(res.map_into_left_body())
            });
        }

        // 安全なメソッド（GET, HEAD, OPTIONS）はCSRFチェックをスキップ
        if method.is_safe() {
            debug!("安全なメソッド - CSRFチェックをスキップ: {}", method);
            let fut = self.service.call(req);
            return Box::pin(async move {
                let res = fut.await?;
                Ok(res.map_into_left_body())
            });
        }

        // CSRF検証実行
        let is_valid = CsrfMiddleware::validate_request(req.request());

        if !is_valid {
            error!(
                "CSRF検証失敗: {} {} - 不正なリクエストをブロック",
                method, path
            );
            return Self::create_csrf_error_response(req);
        }

        debug!("CSRF検証成功: {} {}", method, path);
        let fut = self.service.call(req);
        Box::pin(async move {
            let res = fut.await?;
            Ok(res.map_into_left_body())
        })
    }
}

impl<S, B> CsrfMiddlewareService<S>
where
    S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error>,
{
    /// CSRF検証失敗時のエラーレスポンスを作成
    fn create_csrf_error_response(
        req: ServiceRequest,
    ) -> LocalBoxFuture<'static, Result<ServiceResponse<EitherBody<B>>, Error>> {
        Box::pin(async move {
            // ApiErrorを使用してエラーレスポンスを作成
            use crate::controllers::api_error::ApiError;

            let csrf_error = ApiError::CsrfValidationError(
                "CSRFトークンの検証に失敗しました。有効なCSRFトークンが必要です。".to_string(),
            );

            let error_response = csrf_error.error_response();
            Ok(req.into_response(error_response).map_into_right_body())
        })
    }
}

impl<S, B> Transform<S, ServiceRequest> for CsrfMiddleware
where
    S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error>,
    S::Future: 'static,
    B: 'static,
{
    type Response = ServiceResponse<EitherBody<B>>;
    type Error = Error;
    type InitError = ();
    type Transform = CsrfMiddlewareService<S>;
    type Future = Ready<Result<Self::Transform, Self::InitError>>;

    fn new_transform(&self, service: S) -> Self::Future {
        debug!(
            "CSRFミドルウェアを初期化 - 除外パス数: {}",
            self.exempt_paths.len()
        );
        ready(Ok(CsrfMiddlewareService {
            service,
            exempt_paths: self.exempt_paths.clone(),
        }))
    }
}
