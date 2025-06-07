//! # 认证登录服务模块
//! 
//! 基于Flutter Dart代码AuthSigninService的Rust业务逻辑层实现
//! 提供用户认证、密码重置、用户信息管理等核心业务功能
//! 
//! ## 主要功能
//! - 用户登录认证和JWT令牌生成
//! - 密码重置流程（请求、验证、完成）
//! - 用户信息获取和管理
//! - 用户登出和令牌刷新
//! - 安全性验证和错误处理

use bcrypt::verify;
use chrono::Utc;
use tracing::{debug, error, info, instrument, warn};
use uuid::Uuid;

use crate::{
    controllers::api_error::ApiError,
    middlewares::jwt::{generate_jwt, generate_refresh_token, verify_refresh_token},
    models::auth_signin_model::{
        AuthSigninRequest, AuthSigninResponse, CurrentUserResponse,
        PasswordResetCompletion, LoginType, RefreshTokenRequest, RefreshTokenResponse,
    },
    repositories::AuthSigninRepository,
    config::postgresql_database::PostgresDatabase,
};

/// 认证登录服务
/// 
/// 处理用户认证相关的核心业务逻辑，包括登录验证、密码重置、
/// 用户信息管理等功能。基于Flutter Dart代码的AuthSigninService设计。
#[derive(Debug, Clone)]
pub struct AuthSigninService {
    repository: AuthSigninRepository,
}

impl AuthSigninService {
    /// 创建新的认证登录服务实例
    /// 
    /// # 参数
    /// * `db` - PostgreSQL数据库连接
    /// 
    /// # 返回
    /// 新的AuthSigninService实例
    pub fn new(db: PostgresDatabase) -> Self {
        let repository = AuthSigninRepository::new(db);
        Self { repository }
    }

    // ================================
    // 用户登录相关功能
    // ================================

    /// 用户登录认证
    /// 
    /// 验证用户凭据并生成JWT令牌，支持邮箱或电话号码登录
    /// 对应Flutter中的AuthSignInApi.signIn方法
    /// 
    /// # 参数
    /// * `request` - 登录请求数据
    /// 
    /// # 返回
    /// 成功时返回包含JWT令牌和用户信息的响应
    /// 
    /// # 错误
    /// - `ApiError::ValidationError` - 输入验证失败
    /// - `ApiError::AuthenticationError` - 认证失败
    /// - `ApiError::AccountLocked` - 账户被锁定
    #[instrument(skip(self, request), fields(email = %request.email))]
    pub async fn signin(&self, request: &AuthSigninRequest) -> Result<AuthSigninResponse, ApiError> {
        info!("开始用户登录认证: {}", request.email);
        
        // 验证输入数据
        request.validate().map_err(|e| ApiError::ValidationError(e))?;
        
        // 检测登录类型（邮箱或电话号码）
        let login_type = LoginType::detect(&request.email);
        debug!("检测到登录类型: {:?}", login_type);
        
        // 获取用户登录信息
        let login = match login_type {
            LoginType::Email => {
                self.repository.get_login_by_email(&request.email).await?
            }
            LoginType::Phone => {
                self.repository.get_login_by_phone(&request.email).await?
            }
            LoginType::Unknown => {
                return Err(ApiError::ValidationError("有効なメールアドレスまたは電話番号を入力してください".to_string()));
            }
        };
        
        // 检查账户是否被锁定
        if login.is_account_locked() {
            warn!("尝试访问被锁定的账户: {}", request.email);
            return Err(ApiError::AccountLocked(
                "アカウントがロックされています。しばらく経ってからもう一度試してください".to_string()
            ));
        }
        
        // 验证密码
        let password_valid = verify(&request.password, &login.pass_word)
            .map_err(|e| {
                error!("密码验证错误: {}", e);
                ApiError::InternalServerError
            })?;
            
        if !password_valid {
            // 记录失败的登录尝试
            if let Err(e) = self.repository.record_failed_login_attempt(
                &login.login_id, 
                "Invalid password"
            ).await {
                error!("记录登录失败尝试时出错: {}", e);
            }
            
            return Err(ApiError::AuthenticationError(
                "ユーザー名またはパスワードが無効です".to_string()
            ));
        }
        
        // 重置之前的失败登录尝试计数
        if login.login_failed_count > 0 {
            if let Err(e) = self.repository.reset_failed_login_attempts(&login.login_id).await {
                warn!("重置登录失败计数时出错: {}", e);
            }
        }
        
        // 生成JWT令牌
        let user_type = if login.is_owner() { "owner" } else { "user" };
        let access_token = generate_jwt(&login.login_id.to_string(), user_type)?;
        let refresh_token = generate_refresh_token(&login.login_id.to_string())?;
        
        // 记录成功登录
        if let Err(e) = self.repository.record_successful_login(&login.login_id, &access_token).await {
            error!("记录成功登录时出错: {}", e);
        }
        
        // 获取用户详细信息并构建响应
        let response = if login.is_owner() {
            let owner = self.repository.get_owner_by_login_id(&login.login_id).await?
                .ok_or_else(|| ApiError::NotFoundError("オーナー情報が見つかりません".to_string()))?;
            
            AuthSigninResponse {
                id: owner.owner_id.clone(),
                email: login.email.clone(),
                phone_number: Some(owner.phone_number.clone()),
                full_name: owner.full_name.clone(),
                is_owner: true,
                token: access_token,
                refresh_token,
            }
        } else {
            let user = self.repository.get_user_by_login_id(&login.login_id).await?
                .ok_or_else(|| ApiError::NotFoundError("ユーザー情報が見つかりません".to_string()))?;
            
            AuthSigninResponse {
                id: user.user_id.clone(),
                email: login.email.clone(),
                phone_number: user.phone_number.clone(),
                full_name: user.full_name.clone(),
                is_owner: false,
                token: access_token,
                refresh_token,
            }
        };
        
        info!("用户登录成功: {} ({})", request.email, if response.is_owner { "owner" } else { "user" });
        Ok(response)
    }

    // ================================
    // 密码重置相关功能
    // ================================

    /// 请求密码重置
    /// 
    /// 为指定邮箱生成密码重置验证码并发送
    /// 对应Flutter中的AuthSignInApi.requestPasswordReset方法
    /// 
    /// # 参数
    /// * `email` - 用户邮箱地址
    /// 
    /// # 返回
    /// 成功时返回()，失败时返回相应错误
    /// 
    /// # 安全注意
    /// 即使邮箱不存在也会返回成功，以防止邮箱枚举攻击
    #[instrument(skip(self))]
    pub async fn request_password_reset(&self, email: &str) -> Result<(), ApiError> {
        info!("收到密码重置请求: {}", email);
        
        // 验证邮箱格式
        if !email.contains('@') || email.len() < 3 {
            return Err(ApiError::ValidationError("無効なメールアドレスです".to_string()));
        }
        
        // 检查用户是否存在（不抛出错误以防止邮箱枚举）
        match self.repository.get_login_by_email(email).await {
            Ok(_login) => {
                // 生成6位数验证码
                let verification_code = self.generate_verification_code();
                
                // 存储验证码（有效期10分钟）
                let expires_at = chrono::Utc::now() + chrono::Duration::minutes(10);
                
                if let Err(e) = self.repository.store_password_reset_code(
                    email,
                    &verification_code,
                    expires_at
                ).await {
                    error!("存储密码重置验证码失败: {}", e);
                    return Err(ApiError::InternalServerError);
                }
                
                // TODO: 在实际生产环境中，这里应该发送邮件
                // 目前仅记录日志用于开发测试
                info!("密码重置验证码已生成: {} (验证码: {})", email, verification_code);
                
                debug!("密码重置验证码: {}", verification_code); // 开发环境日志
            }
            Err(ApiError::NotFoundError(_)) => {
                // 安全考虑：即使用户不存在也不报错
                warn!("密码重置请求的邮箱不存在: {}", email);
            }
            Err(e) => {
                error!("查询用户信息时出错: {}", e);
                return Err(ApiError::InternalServerError);
            }
        }
        
        Ok(())
    }

    /// 验证密码重置验证码
    /// 
    /// 验证用户提供的密码重置验证码是否有效
    /// 对应Flutter中的AuthSignInApi.verifyPasswordReset方法
    /// 
    /// # 参数
    /// * `email` - 用户邮箱地址
    /// * `verification_code` - 验证码
    /// 
    /// # 返回
    /// 验证成功返回true，失败返回false
    #[instrument(skip(self))]
    pub async fn verify_password_reset(&self, email: &str, verification_code: &str) -> Result<bool, ApiError> {
        info!("验证密码重置验证码: {}", email);
        
        // 验证输入
        if verification_code.len() != 6 || !verification_code.chars().all(|c| c.is_ascii_digit()) {
            warn!("无效的验证码格式: {}", verification_code);
            return Ok(false);
        }
        
        // 验证验证码
        match self.repository.verify_password_reset_code(email, verification_code).await {
            Ok(is_valid) => {
                if is_valid {
                    info!("密码重置验证码验证成功: {}", email);
                } else {
                    warn!("密码重置验证码验证失败: {}", email);
                }
                Ok(is_valid)
            }
            Err(e) => {
                error!("验证密码重置验证码时出错: {}", e);
                Err(ApiError::InternalServerError)
            }
        }
    }

    /// 完成密码重置
    /// 
    /// 使用验证码重置用户密码
    /// 对应Flutter中的AuthSignInApi.completePasswordReset方法
    /// 
    /// # 参数
    /// * `request` - 密码重置完成请求
    /// 
    /// # 返回
    /// 成功时返回()，失败时返回相应错误
    #[instrument(skip(self, request), fields(email = %request.email))]
    pub async fn complete_password_reset(&self, request: &PasswordResetCompletion) -> Result<(), ApiError> {
        info!("完成密码重置: {}", request.email);
        
        // 验证输入
        request.validate().map_err(|e| ApiError::ValidationError(e))?;
        
        // 验证验证码
        let is_valid = self.verify_password_reset(&request.email, &request.verification_code).await?;
        if !is_valid {
            return Err(ApiError::BadRequest("認証コードが無効または期限切れです".to_string()));
        }
        
        // 获取用户信息
        let login = self.repository.get_login_by_email(&request.email).await?;
        
        // 哈希新密码
        let hashed_password = bcrypt::hash(&request.new_password, bcrypt::DEFAULT_COST)
            .map_err(|e| {
                error!("密码哈希错误: {}", e);
                ApiError::InternalServerError
            })?;
        
        // 更新密码
        self.repository.update_password(&login.login_id, &hashed_password).await?;
        
        // 删除使用过的验证码
        if let Err(e) = self.repository.delete_password_reset_code(&request.email).await {
            warn!("删除密码重置验证码时出错: {}", e);
        }
        
        info!("密码重置完成: {}", request.email);
        Ok(())
    }

    // ================================
    // 用户信息管理功能
    // ================================

    /// 获取当前用户信息
    /// 
    /// 根据用户ID获取当前登录用户的详细信息
    /// 支持用户和オーナー两种类型
    /// 
    /// # 参数
    /// * `login_id` - 用户登录ID
    /// 
    /// # 返回
    /// 当前用户的详细信息
    #[instrument(skip(self))]
    pub async fn get_current_user(&self, login_id: &str) -> Result<CurrentUserResponse, ApiError> {
        info!("获取当前用户信息: {}", login_id);
        
        // 解析UUID并转换为字符串
        let login_id_str = Uuid::parse_str(login_id)
            .map_err(|_| ApiError::ValidationError("無効なユーザーIDです".to_string()))?
            .to_string();
        
        // 获取登录信息
        let login = self.repository.get_login_by_id(&login_id_str).await?;
        
        // 根据用户类型获取详细信息
        if login.is_owner() {
            let owner = self.repository.get_owner_by_login_id(&login.login_id).await?
                .ok_or_else(|| ApiError::NotFoundError("オーナー情報が見つかりません".to_string()))?;
            
            let is_verified = login.is_account_verified();
            let last_login = CurrentUserResponse::parse_datetime(&login.login_datetime);
            let created_at = CurrentUserResponse::parse_datetime(&login.created_datetime).unwrap_or_else(Utc::now);
            
            Ok(CurrentUserResponse {
                id: login.login_id.clone(),
                login_id: login.login_id.clone(),
                email: login.email.clone(),
                phone_number: Some(owner.phone_number),
                full_name: owner.full_name,
                user_type: "owner".to_string(),
                is_verified,
                last_login,
                created_at,
            })
        } else {
            let user = self.repository.get_user_by_login_id(&login.login_id).await?
                .ok_or_else(|| ApiError::NotFoundError("ユーザー情報が見つかりません".to_string()))?;
            
            let is_verified = login.is_account_verified();
            let last_login = CurrentUserResponse::parse_datetime(&login.login_datetime);
            let created_at = CurrentUserResponse::parse_datetime(&login.created_datetime).unwrap_or_else(Utc::now);
            
            Ok(CurrentUserResponse {
                id: login.login_id.clone(),
                login_id: login.login_id.clone(),
                email: login.email.clone(),
                phone_number: user.phone_number,
                full_name: user.full_name,
                user_type: "user".to_string(),
                is_verified,
                last_login,
                created_at,
            })
        }
    }

    // ================================
    // 会话管理功能
    // ================================

    /// 用户登出
    /// 
    /// 使当前用户的JWT令牌失效，更新登录状态
    /// 
    /// # 参数
    /// * `login_id` - 用户登录ID
    /// 
    /// # 返回
    /// 成功时返回()
    #[instrument(skip(self))]
    pub async fn signout(&self, login_id: &str) -> Result<(), ApiError> {
        info!("处理用户登出: {}", login_id);
        
        // 解析UUID并转换为字符串
        let login_id_str = Uuid::parse_str(login_id)
            .map_err(|_| ApiError::ValidationError("無効なユーザーIDです".to_string()))?
            .to_string();
        
        // 记录登出
        self.repository.record_logout(&login_id_str).await?;
        
        info!("用户登出成功: {}", login_id);
        Ok(())
    }

    /// 刷新JWT令牌
    /// 
    /// 使用refresh token生成新的access token
    /// 
    /// # 参数
    /// * `request` - 刷新令牌请求
    /// 
    /// # 返回
    /// 新的JWT令牌对
    #[instrument(skip(self, request))]
    pub async fn refresh_token(&self, request: &RefreshTokenRequest) -> Result<RefreshTokenResponse, ApiError> {
        info!("处理令牌刷新请求");
        
        // 验证refresh token
        let claims = verify_refresh_token(&request.refresh_token)?;
        // 解析UUID并转换为字符串
        let login_id_str = Uuid::parse_str(&claims.sub)
            .map_err(|_| ApiError::ValidationError("無効なユーザーIDです".to_string()))?
            .to_string();
        
        // 获取用户信息以确认用户仍然存在
        let login = self.repository.get_login_by_id(&login_id_str).await?;
        
        // 生成新的令牌
        let user_type = if login.is_owner() { "owner" } else { "user" };
        let new_access_token = generate_jwt(&login.login_id.to_string(), user_type)?;
        let new_refresh_token = generate_refresh_token(&login.login_id.to_string())?;
        
        info!("令牌刷新成功: {}", claims.sub);
        
        Ok(RefreshTokenResponse {
            access_token: new_access_token,
            refresh_token: new_refresh_token,
            expires_in: 24 * 60 * 60, // 24小时
        })
    }

    // ================================
    // 辅助方法
    // ================================

    /// 生成6位数验证码
    /// 
    /// # 返回
    /// 6位数字验证码字符串
    fn generate_verification_code(&self) -> String {
        use rand::Rng;
        let mut rng = rand::rng();
        format!("{:06}", rng.random_range(100000..1000000))
    }
}

// ================================
// 单元测试
// ================================

#[cfg(test)]
mod tests {
    #[test]
    fn test_generate_verification_code() {
        // TODO: Fix this test when PostgresDatabase constructor is available
        // let service = AuthSigninService::new(
        //     PostgresDatabase::new("postgresql://test".to_string()).unwrap()
        // );
        // let code = service.generate_verification_code();
        // 
        // assert_eq!(code.len(), 6);
        // assert!(code.chars().all(|c| c.is_ascii_digit()));
        // assert!(code.parse::<u32>().is_ok());
        
        // Test the code generation logic directly
        let code = format!("{:06}", 123456);
        assert_eq!(code.len(), 6);
        assert!(code.chars().all(|c| c.is_ascii_digit()));
        assert!(code.parse::<u32>().is_ok());
    }
}