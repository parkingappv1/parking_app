use actix_web::dev::Payload;
use actix_web::{
    Error, FromRequest, HttpMessage, HttpRequest,
    dev::{Service, ServiceRequest, ServiceResponse, Transform, forward_ready},
};
use futures_util::future::{Ready, ready};
use serde::{Deserialize, Serialize};
use std::{
    future::{Ready as StdReady, ready as std_ready},
    pin::Pin,
    rc::Rc,
};
use tracing::{debug, error, info, instrument, warn};

use crate::{controllers::api_error::ApiError, middlewares::jwt::verify_jwt};

/// ユーザー認証情報を表す構造体
///
/// JWT認証後にリクエストに挿入されるユーザー情報
/// コントローラーでFromRequestトレイトを使用して取得可能
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UserIdentity {
    /// ユーザーID (例: user_000001, owner_000001)
    pub user_id: String,
    /// ユーザータイプ (0: 一般ユーザー, 1: オーナー, 2: 管理者)
    pub user_type: String,
    /// ログインID (オプション)
    pub login_id: Option<String>,
}

impl UserIdentity {
    /// 新しいUserIdentityインスタンスを作成
    pub fn new(user_id: String, user_type: String, login_id: Option<String>) -> Self {
        Self {
            user_id,
            user_type,
            login_id,
        }
    }

    /// オーナーかどうかを判定
    pub fn is_owner(&self) -> bool {
        self.user_type == "1"
    }

    /// 一般ユーザーかどうかを判定
    pub fn is_user(&self) -> bool {
        self.user_type == "0"
    }

    /// 管理者かどうかを判定
    pub fn is_admin(&self) -> bool {
        self.user_type == "2"
    }
}

/// FromRequestトレイトの実装
///
/// コントローラーでUserIdentityを引数として使用可能にする
impl FromRequest for UserIdentity {
    type Error = ApiError;
    type Future = StdReady<Result<Self, Self::Error>>;

    fn from_request(req: &HttpRequest, _: &mut Payload) -> Self::Future {
        if let Some(user_identity) = req.extensions().get::<UserIdentity>() {
            debug!("ユーザー認証情報を取得: {:?}", user_identity);
            std_ready(Ok(user_identity.clone()))
        } else {
            warn!("リクエストにユーザー認証情報が見つかりません");
            std_ready(Err(ApiError::AuthenticationError(
                "認証が必要です".to_string(),
            )))
        }
    }
}

/// JWT認証ミドルウェア
///
/// リクエストのAuthorizationヘッダーからJWTトークンを取得し、
/// 有効性を検証してユーザー情報をリクエストに挿入する
pub struct JwtAuthMiddleware {
    /// 認証をスキップするかどうか（デバッグ用）
    pub skip_auth: bool,
}

impl JwtAuthMiddleware {
    /// 新しいJwtAuthMiddlewareインスタンスを作成
    pub fn new() -> Self {
        let skip_auth = is_debug_mode();
        if skip_auth {
            info!("デバッグモードが有効です。JWT認証をスキップします");
        } else {
            info!("本番モードです。JWT認証を実行します");
        }

        Self { skip_auth }
    }
}

impl Default for JwtAuthMiddleware {
    fn default() -> Self {
        Self::new()
    }
}

/// デバッグモードかどうかを判定
///
/// 環境変数ENVIRONMENT=developmentかつSKIP_JWT_AUTH=trueの場合にtrue
fn is_debug_mode() -> bool {
    std::env::var("ENVIRONMENT")
        .unwrap_or_else(|_| "development".to_string())
        .to_lowercase()
        == "development"
        && std::env::var("SKIP_JWT_AUTH")
            .unwrap_or_else(|_| "false".to_string())
            .to_lowercase()
            == "true"
}

/// 認証が不要なパスをチェックする関数
///
/// パブリックエンドポイントのパス一覧をチェック
pub fn is_public_path(path: &str) -> bool {
    let public_paths = [
        "/api/auth/signin",
        "/api/auth/signup",
        "/api/auth/password-reset/request",
        "/api/auth/password-reset/verify",
        "/api/auth/password-reset/complete",
        "/api/auth/refresh",
        "/health",
        "/docs",
        "/api-docs",
    ];

    public_paths
        .iter()
        .any(|&public_path| path.starts_with(public_path))
}

/// ミドルウェアファクトリーの実装
impl<S, B> Transform<S, ServiceRequest> for JwtAuthMiddleware
where
    S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error> + 'static,
    S::Future: 'static,
    B: 'static,
{
    type Response = ServiceResponse<B>;
    type Error = Error;
    type Transform = JwtAuthMiddlewareService<S>;
    type InitError = ();
    type Future = Ready<Result<Self::Transform, Self::InitError>>;

    fn new_transform(&self, service: S) -> Self::Future {
        ready(Ok(JwtAuthMiddlewareService {
            service: Rc::new(service),
            skip_auth: self.skip_auth,
        }))
    }
}

/// ミドルウェアサービスの実装
pub struct JwtAuthMiddlewareService<S> {
    service: Rc<S>,
    skip_auth: bool,
}

impl<S, B> Service<ServiceRequest> for JwtAuthMiddlewareService<S>
where
    S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error> + 'static,
    S::Future: 'static,
    B: 'static,
{
    type Response = ServiceResponse<B>;
    type Error = Error;
    type Future = Pin<Box<dyn std::future::Future<Output = Result<Self::Response, Self::Error>>>>;

    forward_ready!(service);

    #[instrument(skip(self, req), fields(path = %req.path()))]
    fn call(&self, req: ServiceRequest) -> Self::Future {
        let skip_auth = self.skip_auth;
        let path = req.path().to_string();
        let service = self.service.clone(); // Clone the Rc, not the service

        Box::pin(async move {
            // パブリックパスをチェック
            if is_public_path(&path) {
                debug!("パブリックパス: {} - 認証をスキップ", path);
                return service.call(req).await;
            }

            // デバッグモードで認証をスキップする場合
            if skip_auth {
                info!("デバッグモード: JWT認証をスキップし、ダミーユーザーを設定");

                let dummy_user = UserIdentity::new(
                    "user_000001".to_string(),
                    "0".to_string(),
                    Some("dummy-login-id".to_string()),
                );

                req.extensions_mut().insert(dummy_user);
                return service.call(req).await;
            }

            // Authorizationヘッダーからトークンを取得
            let token = match extract_bearer_token(&req) {
                Ok(token) => token,
                Err(error_response) => {
                    return Err(error_response);
                }
            };

            // JWTトークンを検証してユーザー情報を設定
            match verify_jwt(&token) {
                Ok(claims) => {
                    info!(
                        "JWT検証成功: user_id={}, user_type={}",
                        claims.sub, claims.user_type
                    );

                    let user_identity = UserIdentity::new(
                        claims.sub,
                        claims.user_type,
                        None, // login_idは必要に応じて設定
                    );

                    req.extensions_mut().insert(user_identity);
                    service.call(req).await
                }
                Err(api_error) => {
                    error!("JWT検証失敗: {:?}", api_error);
                    Err(actix_web::error::ErrorUnauthorized(
                        serde_json::json!({
                            "code": 401,
                            "message": "無効な認証トークンです",
                            "data": Option::<()>::None
                        })
                        .to_string(),
                    ))
                }
            }
        })
    }
}

/// リクエストからBearerトークンを抽出する
///
/// # Errors
///
/// * Authorizationヘッダーがない場合
/// * ヘッダー形式が無効な場合
/// * Bearer形式でない場合
fn extract_bearer_token(req: &ServiceRequest) -> Result<String, Error> {
    // デバッグモードの場合、固定トークンを返す
    if is_debug_mode() {
        info!("デバッグモード: 固定のBearerトークンを使用します");
        return Ok("dummy-token-for-development".to_string());
    }

    let auth_header = req.headers().get("Authorization").ok_or_else(|| {
        warn!("Authorizationヘッダーが見つかりません");
        actix_web::error::ErrorUnauthorized(
            serde_json::json!({
                "code": 401,
                "message": "認証トークンが必要です",
                "data": Option::<()>::None
            })
            .to_string(),
        )
    })?;

    let auth_str = auth_header.to_str().map_err(|_| {
        warn!("Authorizationヘッダーが無効な文字列です");
        actix_web::error::ErrorUnauthorized(
            serde_json::json!({
                "code": 401,
                "message": "無効な認証ヘッダーです",
                "data": Option::<()>::None
            })
            .to_string(),
        )
    })?;

    if !auth_str.starts_with("Bearer ") {
        warn!("Authorizationヘッダーの形式が無効です");
        return Err(actix_web::error::ErrorUnauthorized(
            serde_json::json!({
                "code": 401,
                "message": "無効な認証ヘッダー形式です",
                "data": Option::<()>::None
            })
            .to_string(),
        ));
    }
    // "Bearer " プレフィックスを削除
    Ok(auth_str[7..].to_owned())
}

// ================================
// テスト用のヘルパー関数
// ================================

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_user_identity_types() {
        let user = UserIdentity::new("user_000001".to_string(), "0".to_string(), None);
        assert!(user.is_user());
        assert!(!user.is_owner());
        assert!(!user.is_admin());

        let owner = UserIdentity::new("owner_000001".to_string(), "1".to_string(), None);
        assert!(!owner.is_user());
        assert!(owner.is_owner());
        assert!(!owner.is_admin());

        let admin = UserIdentity::new("admin_000001".to_string(), "2".to_string(), None);
        assert!(!admin.is_user());
        assert!(!admin.is_owner());
        assert!(admin.is_admin());
    }

    #[test]
    fn test_public_paths() {
        assert!(is_public_path("/api/auth/signin"));
        assert!(is_public_path("/api/auth/signup"));
        assert!(is_public_path("/health"));
        assert!(!is_public_path("/api/users"));
        assert!(!is_public_path("/api/parking"));
    }
}
