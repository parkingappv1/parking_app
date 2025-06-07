//! # 认证登录控制器模块
//! 
//! 基于Flutter Dart代码的AuthSignIn API设计的Rust HTTP控制器实现
//! 处理用户登录、密码重置等HTTP请求，提供RESTful API端点
//! 
//! ## 主要功能
//! - 用户登录认证 (POST /api/auth/signin)
//! - 密码重置请求 (POST /api/auth/password-reset/request)
//! - 密码重置验证 (POST /api/auth/password-reset/verify)
//! - 密码重置完成 (POST /api/auth/password-reset/complete)
//! - 获取当前用户信息 (GET /api/auth/me)
//! - 用户登出 (POST /api/auth/signout)

use actix_web::{
    get, post, 
    web::{Data, Json},
    Responder, ResponseError,
};
use tracing::{debug, error, info, instrument, warn};

use crate::{
    controllers::{
        api_error::ApiError,
        api_response::ApiResponse,
    },
    middlewares::identity_middleware::UserIdentity,
    models::auth_signin_model::{
        AuthSigninRequest,
        PasswordResetRequest, PasswordResetVerification, PasswordResetCompletion,
        RefreshTokenRequest,
    },
    services::auth_signin_service::AuthSigninService,

};

// ================================
// 用户登录端点
// ================================

/// 用户登录端点
/// 
/// 处理来自Flutter客户端的登录请求，支持邮箱或电话号码登录
/// 对应Flutter中的AuthSignInApi.signin方法
/// 
/// # 端点
/// `POST /api/auth/signin`
/// 
/// # 请求体
/// ```json
/// {
///     "email": "user@example.com",
///     "password": "password123",
///     "remember_me": false
/// }
/// ```
/// 
/// # 响应
/// - 200: 登录成功，返回用户信息和JWT令牌
/// - 400: 请求参数错误
/// - 401: 认证失败（邮箱/密码错误）
/// - 422: 输入验证失败
/// - 500: 服务器内部错误
#[post("/signin")]
#[instrument(skip(service, request), fields(email = %request.email))]
pub async fn signin(
    service: Data<AuthSigninService>,
    request: Json<AuthSigninRequest>,
) -> impl Responder {
    info!("收到用户登录请求: {}", request.email);
    
    // 验证请求数据
    if let Err(validation_error) = request.validate() {
        warn!("登录请求验证失败: {}", validation_error);
        return ApiError::ValidationError(validation_error).error_response();
    }
    
    debug!("登录请求验证通过，开始认证流程");
    
    // 调用服务层进行认证
    match service.signin(&request).await {
        Ok(signin_response) => {
            info!("用户登录成功: {} (类型: {})", 
                signin_response.email, if signin_response.is_owner { "owner" } else { "user" });
            
            ApiResponse::success(
                signin_response,
                Some(200),
                Some("ログインに成功しました"),
                None,
            )
        }
        Err(ApiError::AuthenticationError(msg)) => {
            warn!("登录认证失败: {}", msg);
            ApiError::AuthenticationError(msg).error_response()
        }
        Err(ApiError::NotFoundError(msg)) => {
            warn!("用户不存在: {}", msg);
            ApiError::AuthenticationError("メールアドレスまたはパスワードが正しくありません".to_string()).error_response()
        }
        Err(err) => {
            error!("登录过程中发生服务器错误: {:?}", err);
            ApiError::InternalServerError.error_response()
        }
    }
}

// ================================
// 密码重置相关端点
// ================================

/// 密码重置请求端点
/// 
/// 发送密码重置邮件到指定邮箱地址
/// 对应Flutter中的AuthSignInApi.requestPasswordReset方法
/// 
/// # 端点
/// `POST /api/auth/password-reset/request`
/// 
/// # 请求体
/// ```json
/// {
///     "email": "user@example.com"
/// }
/// ```
#[post("/password-reset/request")]
#[instrument(skip(service), fields(email = %request.email))]
pub async fn request_password_reset(
    service: Data<AuthSigninService>,
    request: Json<PasswordResetRequest>,
) -> impl Responder {
    info!("收到密码重置请求: {}", request.email);
    
    // 验证请求数据
    if let Err(validation_error) = request.validate() {
        warn!("密码重置请求验证失败: {}", validation_error);
        return ApiError::ValidationError(validation_error).error_response();
    }
    
    debug!("密码重置请求验证通过，开始处理");
    
    match service.request_password_reset(&request.email).await {
        Ok(_) => {
            info!("密码重置邮件发送成功: {}", request.email);
            ApiResponse::success(
                serde_json::json!({"message": "パスワードリセットメールを送信しました"}),
                Some(200),
                Some("パスワードリセットメールを送信しました"),
                None,
            )
        }
        Err(ApiError::NotFoundError(_)) => {
            // 安全考虑：即使邮箱不存在也返回成功
            warn!("密码重置请求的邮箱不存在: {}", request.email);
            ApiResponse::success(
                serde_json::json!({"message": "パスワードリセットメールを送信しました"}),
                Some(200),
                Some("パスワードリセットメールを送信しました"),
                None,
            )
        }
        Err(err) => {
            error!("密码重置请求处理错误: {:?}", err);
            ApiError::InternalServerError.error_response()
        }
    }
}

/// 密码重置验证端点
/// 
/// 验证密码重置验证码的有效性
/// 对应Flutter中的AuthSignInApi.verifyPasswordReset方法
/// 
/// # 端点
/// `POST /api/auth/password-reset/verify`
#[post("/password-reset/verify")]
#[instrument(skip(service), fields(email = %request.email))]
pub async fn verify_password_reset(
    service: Data<AuthSigninService>,
    request: Json<PasswordResetVerification>,
) -> impl Responder {
    info!("收到密码重置验证请求: {}", request.email);
    
    debug!("开始验证密码重置验证码");
    
    match service.verify_password_reset(&request.email, &request.verification_code).await {
        Ok(true) => {
            info!("密码重置验证码验证成功: {}", request.email);
            ApiResponse::success(
                serde_json::json!({"valid": true}),
                Some(200),
                Some("認証コードが正しく確認されました"),
                None,
            )
        }
        Ok(false) => {
            warn!("密码重置验证码无效: {}", request.email);
            ApiError::BadRequestError("認証コードが無効または期限切れです".to_string()).error_response()
        }
        Err(err) => {
            error!("密码重置验证处理错误: {:?}", err);
            ApiError::InternalServerError.error_response()
        }
    }
}

/// 密码重置完成端点
/// 
/// 使用验证码完成密码重置操作
/// 对应Flutter中的AuthSignInApi.completePasswordReset方法
/// 
/// # 端点
/// `POST /api/auth/password-reset/complete`
#[post("/password-reset/complete")]
#[instrument(skip(service), fields(email = %request.email))]
pub async fn complete_password_reset(
    service: Data<AuthSigninService>,
    request: Json<PasswordResetCompletion>,
) -> impl Responder {
    info!("收到密码重置完成请求: {}", request.email);
    
    // 验证请求数据
    if let Err(validation_error) = request.validate() {
        warn!("密码重置完成请求验证失败: {}", validation_error);
        return ApiError::ValidationError(validation_error).error_response();
    }
    
    debug!("密码重置完成请求验证通过，开始处理");
    
    match service.complete_password_reset(&request).await {
        Ok(_) => {
            info!("密码重置完成成功: {}", request.email);
            ApiResponse::success(
                serde_json::json!({"message": "パスワードがリセットされました"}),
                Some(200),
                Some("パスワードがリセットされました"),
                None,
            )
        }
        Err(ApiError::BadRequest(msg)) => {
            warn!("密码重置完成失败: {}", msg);
            ApiError::BadRequest(msg).error_response()
        }
        Err(err) => {
            error!("密码重置完成处理错误: {:?}", err);
            ApiError::InternalServerError.error_response()
        }
    }
}

// ================================
// 用户信息相关端点
// ================================

/// 获取当前用户信息端点
/// 
/// 根据JWT令牌获取当前登录用户的详细信息
/// 需要有效的JWT认证
/// 
/// # 端点
/// `GET /api/auth/me`
/// 
/// # 请求头
/// - Authorization: Bearer <jwt_token>
#[get("/me")]
#[instrument(skip(service, claims))]
pub async fn get_current_user(
    service: Data<AuthSigninService>,
    claims: UserIdentity, // JWT中间件提取的用户声明
) -> impl Responder {
    info!("收到获取当前用户信息请求: user_id={}", claims.user_id);
    
    debug!("开始获取用户信息");
    
    match service.get_current_user(&claims.user_id).await {
        Ok(user_info) => {
            info!("成功获取用户信息: {} ({})", user_info.email, user_info.user_type);
            ApiResponse::success(
                user_info,
                Some(200),
                Some("ユーザー情報を取得しました"),
                None,
            )
        }
        Err(ApiError::NotFoundError(_)) => {
            warn!("用户不存在: user_id={}", claims.user_id);
            ApiError::NotFoundError("ユーザーが見つかりません".to_string()).error_response()
        }
        Err(err) => {
            error!("获取用户信息错误: {:?}", err);
            ApiError::InternalServerError.error_response()
        }
    }
}

/// 用户登出端点
/// 
/// 使当前用户的JWT令牌失效（可选：加入黑名单）
/// 
/// # 端点
/// `POST /api/auth/signout`
/// 
/// # 请求头
/// - Authorization: Bearer <jwt_token>
#[post("/signout")]
#[instrument(skip(service, claims))]
pub async fn signout(
    service: Data<AuthSigninService>,
    claims: UserIdentity,
) -> impl Responder {
    info!("收到用户登出请求: user_id={}", claims.user_id);
    
    debug!("开始处理用户登出");
    
    match service.signout(&claims.user_id).await {
        Ok(_) => {
            info!("用户登出成功: user_id={}", claims.user_id);
            ApiResponse::success(
                serde_json::json!({"message": "ログアウトしました"}),
                Some(200),
                Some("ログアウトしました"),
                None,
            )
        }
        Err(err) => {
            error!("用户登出处理错误: {:?}", err);
            ApiError::InternalServerError.error_response()
        }
    }
}

// ================================
// 令牌刷新端点
// ================================

/// JWT令牌刷新端点
/// 
/// 使用刷新令牌获取新的访问令牌
/// 
/// # 端点
/// `POST /api/auth/refresh`
/// 
/// # 请求体
/// ```json
/// {
///     "refresh_token": "refresh_token_here"
/// }
/// ```
#[post("/refresh")]
#[instrument(skip(service, request))]
pub async fn refresh_token(
    service: Data<AuthSigninService>,
    request: Json<RefreshTokenRequest>,
) -> impl Responder {
    info!("收到令牌刷新请求");
    
    debug!("开始处理令牌刷新");
    
    match service.refresh_token(&request).await {
        Ok(new_tokens) => {
            info!("令牌刷新成功");
            ApiResponse::success(
                new_tokens,
                Some(200),
                Some("トークンが更新されました"),
                None,
            )
        }
        Err(ApiError::AuthenticationError(msg)) => {
            warn!("令牌刷新失败: {}", msg);
            ApiError::AuthenticationError(msg).error_response()
        }
        Err(err) => {
            error!("令牌刷新处理错误: {:?}", err);
            ApiError::InternalServerError.error_response()
        }
    }
}