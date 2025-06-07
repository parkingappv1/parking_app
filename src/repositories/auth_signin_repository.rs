//! # 认证登录仓库模块
//! 
//! 基于Flutter Dart代码的数据访问层实现
//! 提供用户认证、登录信息管理的数据库操作
//! 
//! ## 主要功能
//! - 用户登录信息的CRUD操作
//! - 密码重置验证码管理
//! - 登录尝试记录和账户锁定管理
//! - 基于实际数据库架构的SQL实现

use chrono::{DateTime, Utc};
use sqlx::{PgPool, Row};
use tracing::{info, instrument, error};
use uuid::Uuid;

use crate::{
    controllers::api_error::ApiError,
    config::postgresql_database::PostgresDatabase,
    models::{
        m_login_model::MLoginModel,
        m_users_model::MUsersModel,
        m_owners_model::MOwnersModel,
    },
};

/// 认证登录数据仓库
/// 
/// 负责处理与用户认证和登录相关的数据库操作
/// 基于实际PostgreSQL数据库架构实现
#[derive(Debug, Clone)]
pub struct AuthSigninRepository {
    db: PostgresDatabase,
}

impl AuthSigninRepository {
    /// 创建新的认证登录仓库实例
    /// 
    /// # 参数
    /// * `db` - PostgreSQL数据库连接
    pub fn new(db: PostgresDatabase) -> Self {
        Self { db }
    }

    /// 获取数据库连接池
    fn get_pool(&self) -> &PgPool {
        self.db.pool()
    }

    /// 记录SQL查询日志
    /// 
    /// # 参数
    /// * `query` - SQL查询语句
    /// * `params` - 查询参数（可选）
    fn log_sql_query(&self, query: &str, params: Option<&str>) {
        if let Some(p) = params {
            info!("执行SQL查询 - Query: {} | Parameters: {}", query.trim(), p);
        } else {
            info!("执行SQL查询 - Query: {}", query.trim());
        }
    }

    // ================================
    // 登录信息查询
    // ================================

    /// 根据邮箱获取登录信息
    /// 
    /// # 参数
    /// * `email` - 邮箱地址
    /// 
    /// # 返回
    /// 登录信息记录
    #[instrument(skip(self))]
    pub async fn get_login_by_email(&self, email: &str) -> Result<MLoginModel, ApiError> {
        info!("查询邮箱登录信息: {}", email);
        
        let query = r#"
            SELECT 
                login_id::text,
                email,
                phone_number,
                pass_word,
                is_user_owner,
                login_token,
                login_token_expiration::text,
                login_token_issued_datetime::text,
                login_token_issued_count,
                login_token_issued_flag,
                is_login,
                login_datetime::text,
                logout_datetime::text,
                login_failed_count,
                login_failed_datetime::text,
                login_failed_flag,
                login_failed_reason,
                login_failed_reason_detail,
                login_failed_reset_datetime::text,
                created_datetime::text,
                updated_datetime::text
            FROM m_login 
            WHERE email = $1
        "#;
        
        self.log_sql_query(query, Some(email));
        
        match sqlx::query(query)
            .bind(email)
            .fetch_one(self.get_pool())
            .await
        {
            Ok(row) => {
                let login = MLoginModel::new(
                    Some(row.get("login_id")),
                    Some(row.get("email")),
                    Some(row.get("phone_number")),
                    Some(row.get("pass_word")),
                    Some(row.get("is_user_owner")),
                    row.get("login_token"),
                    row.get("login_token_expiration"),
                    row.get("login_token_issued_datetime"),
                    Some(row.get("login_token_issued_count")),
                    Some(row.get("login_token_issued_flag")),
                    Some(row.get("is_login")),
                    row.get("login_datetime"),
                    row.get("logout_datetime"),
                    Some(row.get("login_failed_count")),
                    row.get("login_failed_datetime"),
                    Some(row.get("login_failed_flag")),
                    row.get("login_failed_reason"),
                    row.get("login_failed_reason_detail"),
                    row.get("login_failed_reset_datetime"),
                    row.get("created_datetime"),
                    row.get("updated_datetime"),
                );
                Ok(login)
            }
            Err(sqlx::Error::RowNotFound) => {
                Err(ApiError::NotFoundError("用户未找到".to_string()))
            }
            Err(e) => {
                error!("数据库查询错误: {}", e);
                Err(ApiError::InternalServerError)
            }
        }
    }

    /// 根据电话号码获取登录信息
    /// 
    /// # 参数
    /// * `phone` - 电话号码
    /// 
    /// # 返回
    /// 登录信息记录
    #[instrument(skip(self))]
    pub async fn get_login_by_phone(&self, phone: &str) -> Result<MLoginModel, ApiError> {
        info!("查询电话登录信息: {}", phone);
        
        let query = r#"
            SELECT 
                login_id::text,
                email,
                phone_number,
                pass_word,
                is_user_owner,
                login_token,
                login_token_expiration::text,
                login_token_issued_datetime::text,
                login_token_issued_count,
                login_token_issued_flag,
                is_login,
                login_datetime::text,
                logout_datetime::text,
                login_failed_count,
                login_failed_datetime::text,
                login_failed_flag,
                login_failed_reason,
                login_failed_reason_detail,
                login_failed_reset_datetime::text,
                created_datetime::text,
                updated_datetime::text
            FROM m_login 
            WHERE phone_number = $1
        "#;
        
        self.log_sql_query(query, Some(phone));
        
        match sqlx::query(query)
            .bind(phone)
            .fetch_one(self.get_pool())
            .await
        {
            Ok(row) => {
                let login = MLoginModel::new(
                    Some(row.get("login_id")),
                    Some(row.get("email")),
                    Some(row.get("phone_number")),
                    Some(row.get("pass_word")),
                    Some(row.get("is_user_owner")),
                    row.get("login_token"),
                    row.get("login_token_expiration"),
                    row.get("login_token_issued_datetime"),
                    Some(row.get("login_token_issued_count")),
                    Some(row.get("login_token_issued_flag")),
                    Some(row.get("is_login")),
                    row.get("login_datetime"),
                    row.get("logout_datetime"),
                    Some(row.get("login_failed_count")),
                    row.get("login_failed_datetime"),
                    Some(row.get("login_failed_flag")),
                    row.get("login_failed_reason"),
                    row.get("login_failed_reason_detail"),
                    row.get("login_failed_reset_datetime"),
                    row.get("created_datetime"),
                    row.get("updated_datetime"),
                );
                Ok(login)
            }
            Err(sqlx::Error::RowNotFound) => {
                Err(ApiError::NotFoundError("用户未找到".to_string()))
            }
            Err(e) => {
                error!("数据库查询错误: {}", e);
                Err(ApiError::InternalServerError)
            }
        }
    }

    /// 根据登录ID获取登录信息
    /// 
    /// # 参数
    /// * `login_id` - 登录ID (String format)
    /// 
    /// # 返回
    /// 登录信息记录
    #[instrument(skip(self))]
    pub async fn get_login_by_id(&self, login_id: &str) -> Result<MLoginModel, ApiError> {
        info!("查询登录信息: {}", login_id);
        
        // 解析UUID
        let login_uuid = Uuid::parse_str(login_id)
            .map_err(|_| ApiError::ValidationError("无效的登录ID格式".to_string()))?;
        
        let query = r#"
            SELECT 
                login_id::text,
                email,
                phone_number,
                pass_word,
                is_user_owner,
                login_token,
                login_token_expiration::text,
                login_token_issued_datetime::text,
                login_token_issued_count,
                login_token_issued_flag,
                is_login,
                login_datetime::text,
                logout_datetime::text,
                login_failed_count,
                login_failed_datetime::text,
                login_failed_flag,
                login_failed_reason,
                login_failed_reason_detail,
                login_failed_reset_datetime::text,
                created_datetime::text,
                updated_datetime::text
            FROM m_login 
            WHERE login_id = $1
        "#;
        
        self.log_sql_query(query, Some(login_id));
        
        match sqlx::query(query)
            .bind(login_uuid)
            .fetch_one(self.get_pool())
            .await
        {
            Ok(row) => {
                let login = MLoginModel::new(
                    Some(row.get("login_id")),
                    Some(row.get("email")),
                    Some(row.get("phone_number")),
                    Some(row.get("pass_word")),
                    Some(row.get("is_user_owner")),
                    row.get("login_token"),
                    row.get("login_token_expiration"),
                    row.get("login_token_issued_datetime"),
                    Some(row.get("login_token_issued_count")),
                    Some(row.get("login_token_issued_flag")),
                    Some(row.get("is_login")),
                    row.get("login_datetime"),
                    row.get("logout_datetime"),
                    Some(row.get("login_failed_count")),
                    row.get("login_failed_datetime"),
                    Some(row.get("login_failed_flag")),
                    row.get("login_failed_reason"),
                    row.get("login_failed_reason_detail"),
                    row.get("login_failed_reset_datetime"),
                    row.get("created_datetime"),
                    row.get("updated_datetime"),
                );
                Ok(login)
            }
            Err(sqlx::Error::RowNotFound) => {
                Err(ApiError::NotFoundError("登录信息未找到".to_string()))
            }
            Err(e) => {
                error!("数据库查询错误: {}", e);
                Err(ApiError::InternalServerError)
            }
        }
    }

    // ================================
    // 用户信息查询
    // ================================

    /// 根据登录ID获取用户信息
    /// 
    /// # 参数
    /// * `login_id` - 登录ID (String format)
    /// 
    /// # 返回
    /// 用户信息记录（可能为空）
    #[instrument(skip(self))]
    pub async fn get_user_by_login_id(&self, login_id: &str) -> Result<Option<MUsersModel>, ApiError> {
        info!("查询用户信息: {}", login_id);
        
        // 解析UUID
        let login_uuid = Uuid::parse_str(login_id)
            .map_err(|_| ApiError::ValidationError("无效的登录ID格式".to_string()))?;
        
        let query = r#"
            SELECT 
                user_id,
                login_id::text,
                full_name,
                phone_number,
                address,
                promotional_email_opt,
                service_email_opt,
                created_datetime::text,
                updated_datetime::text
            FROM m_users 
            WHERE login_id = $1
        "#;
        
        match sqlx::query(query)
            .bind(login_uuid)
            .fetch_optional(self.get_pool())
            .await
        {
            Ok(Some(row)) => {
                let user = MUsersModel::new(
                    Some(row.get("user_id")),
                    Some(row.get("login_id")),
                    Some(row.get("full_name")),
                    row.get("phone_number"),
                    Some(row.get("address")),
                    Some(row.get("promotional_email_opt")),
                    Some(row.get("service_email_opt")),
                    row.get("created_datetime"),
                    row.get("updated_datetime"),
                );
                Ok(Some(user))
            }
            Ok(None) => Ok(None),
            Err(e) => {
                error!("数据库查询错误: {}", e);
                Err(ApiError::InternalServerError)
            }
        }
    }

    /// 根据登录ID获取业主信息
    /// 
    /// # 参数
    /// * `login_id` - 登录ID (String format)
    /// 
    /// # 返回
    /// 业主信息记录（可能为空）
    #[instrument(skip(self))]
    pub async fn get_owner_by_login_id(&self, login_id: &str) -> Result<Option<MOwnersModel>, ApiError> {
        info!("查询业主信息: {}", login_id);
        
        // 解析UUID
        let login_uuid = Uuid::parse_str(login_id)
            .map_err(|_| ApiError::ValidationError("无效的登录ID格式".to_string()))?;
        
        let query = r#"
            SELECT 
                owner_id,
                login_id::text,
                registrant_type,
                full_name,
                full_name_kana,
                postal_code,
                address,
                phone_number,
                remarks,
                created_datetime::text,
                updated_datetime::text
            FROM m_owners 
            WHERE login_id = $1
        "#;
        
        match sqlx::query(query)
            .bind(login_uuid)
            .fetch_optional(self.get_pool())
            .await
        {
            Ok(Some(row)) => {
                let owner = MOwnersModel::new(
                    Some(row.get("owner_id")),
                    Some(row.get("login_id")),
                    Some(row.get("registrant_type")),
                    Some(row.get("full_name")),
                    row.get("full_name_kana"),
                    Some(row.get("postal_code")),
                    Some(row.get("address")),
                    Some(row.get("phone_number")),
                    row.get("remarks"),
                    row.get("created_datetime"),
                    row.get("updated_datetime"),
                );
                Ok(Some(owner))
            }
            Ok(None) => Ok(None),
            Err(e) => {
                error!("数据库查询错误: {}", e);
                Err(ApiError::InternalServerError)
            }
        }
    }

    // ================================
    // 登录尝试管理
    // ================================

    /// 记录失败的登录尝试
    /// 
    /// # 参数
    /// * `login_id` - 登录ID (String format)
    /// * `reason` - 失败原因
    #[instrument(skip(self))]
    pub async fn record_failed_login_attempt(&self, login_id: &str, reason: &str) -> Result<(), ApiError> {
        info!("记录登录失败: {} - {}", login_id, reason);
        
        // 解析UUID
        let login_uuid = Uuid::parse_str(login_id)
            .map_err(|_| ApiError::ValidationError("无效的登录ID格式".to_string()))?;
        
        let query = r#"
            UPDATE m_login 
            SET 
                login_failed_count = login_failed_count + 1,
                login_failed_datetime = CURRENT_TIMESTAMP,
                login_failed_flag = '1',
                login_failed_reason = $2,
                updated_datetime = CURRENT_TIMESTAMP
            WHERE login_id = $1
        "#;
        
        match sqlx::query(query)
            .bind(login_uuid)
            .bind(reason)
            .execute(self.get_pool())
            .await
        {
            Ok(_) => Ok(()),
            Err(e) => {
                error!("记录登录失败错误: {}", e);
                Err(ApiError::InternalServerError)
            }
        }
    }

    /// 重置失败的登录尝试计数
    /// 
    /// # 参数
    /// * `login_id` - 登录ID (String format)
    #[instrument(skip(self))]
    pub async fn reset_failed_login_attempts(&self, login_id: &str) -> Result<(), ApiError> {
        info!("重置登录失败计数: {}", login_id);
        
        // 解析UUID
        let login_uuid = Uuid::parse_str(login_id)
            .map_err(|_| ApiError::ValidationError("无效的登录ID格式".to_string()))?;
        
        let query = r#"
            UPDATE m_login 
            SET 
                login_failed_count = 0,
                login_failed_flag = '0',
                login_failed_reason = NULL,
                login_failed_reason_detail = NULL,
                login_failed_reset_datetime = CURRENT_TIMESTAMP,
                updated_datetime = CURRENT_TIMESTAMP
            WHERE login_id = $1
        "#;
        
        match sqlx::query(query)
            .bind(login_uuid)
            .execute(self.get_pool())
            .await
        {
            Ok(_) => Ok(()),
            Err(e) => {
                error!("重置登录失败计数错误: {}", e);
                Err(ApiError::InternalServerError)
            }
        }
    }

    /// 记录成功登录
    /// 
    /// # 参数
    /// * `login_id` - 登录ID (String format)
    /// * `access_token` - 访问令牌
    #[instrument(skip(self))]
    pub async fn record_successful_login(&self, login_id: &str, access_token: &str) -> Result<(), ApiError> {
        info!("记录成功登录: {}", login_id);
        
        // 解析UUID
        let login_uuid = Uuid::parse_str(login_id)
            .map_err(|_| ApiError::ValidationError("无效的登录ID格式".to_string()))?;
        
        let query = r#"
            UPDATE m_login 
            SET 
                login_failed_count = 0,
                login_failed_flag = '0',
                login_failed_reason = NULL,
                login_datetime = CURRENT_TIMESTAMP,
                is_login = '1',
                login_token = $2,
                login_token_issued_datetime = CURRENT_TIMESTAMP,
                login_token_issued_count = login_token_issued_count + 1,
                login_token_issued_flag = '1',
                updated_datetime = CURRENT_TIMESTAMP
            WHERE login_id = $1
        "#;
        
        match sqlx::query(query)
            .bind(login_uuid)
            .bind(access_token)
            .execute(self.get_pool())
            .await
        {
            Ok(_) => Ok(()),
            Err(e) => {
                error!("记录成功登录错误: {}", e);
                Err(ApiError::InternalServerError)
            }
        }
    }

    // ================================
    // 密码重置管理
    // ================================

    /// 存储密码重置验证码
    /// 
    /// # 参数
    /// * `email` - 邮箱地址
    /// * `verification_code` - 验证码
    /// * `expires_at` - 过期时间
    #[instrument(skip(self))]
    pub async fn store_password_reset_code(
        &self,
        email: &str,
        verification_code: &str,
        expires_at: DateTime<Utc>,
    ) -> Result<(), ApiError> {
        info!("存储密码重置验证码: {}", email);
        
        // 首先删除该邮箱的旧验证码
        let delete_query = r#"
            DELETE FROM password_reset_codes 
            WHERE email = $1
        "#;
        
        match sqlx::query(delete_query)
            .bind(email)
            .execute(self.get_pool())
            .await
        {
            Ok(_) => {},
            Err(e) => {
                error!("删除旧验证码失败: {}", e);
                return Err(ApiError::InternalServerError);
            }
        }
        
        // 插入新的验证码
        let insert_query = r#"
            INSERT INTO password_reset_codes (email, reset_code, expires_at, created_datetime)
            VALUES ($1, $2, $3, CURRENT_TIMESTAMP)
        "#;
        
        match sqlx::query(insert_query)
            .bind(email)
            .bind(verification_code)
            .bind(expires_at)
            .execute(self.get_pool())
            .await
        {
            Ok(_) => {
                info!("密码重置验证码存储成功: {}", email);
                Ok(())
            }
            Err(e) => {
                error!("存储密码重置验证码失败: {}", e);
                Err(ApiError::InternalServerError)
            }
        }
    }

    /// 验证密码重置验证码
    /// 
    /// # 参数
    /// * `email` - 邮箱地址
    /// * `verification_code` - 验证码
    /// 
    /// # 返回
    /// 验证是否成功
    #[instrument(skip(self))]
    pub async fn verify_password_reset_code(&self, email: &str, verification_code: &str) -> Result<bool, ApiError> {
        info!("验证密码重置验证码: {}", email);
        
        let query = r#"
            SELECT reset_code_id 
            FROM password_reset_codes
            WHERE email = $1 
                AND reset_code = $2 
                AND expires_at > CURRENT_TIMESTAMP
                AND is_used = '0'
        "#;
        
        match sqlx::query(query)
            .bind(email)
            .bind(verification_code)
            .fetch_optional(self.get_pool())
            .await
        {
            Ok(Some(_)) => {
                info!("密码重置验证码验证成功: {}", email);
                Ok(true)
            }
            Ok(None) => {
                info!("密码重置验证码验证失败: {} - 无效或已过期", email);
                Ok(false)
            }
            Err(e) => {
                error!("验证密码重置验证码错误: {}", e);
                Err(ApiError::InternalServerError)
            }
        }
    }

    /// 更新用户密码
    /// 
    /// # 参数
    /// * `login_id` - 登录ID (String format)
    /// * `hashed_password` - 哈希后的新密码
    #[instrument(skip(self))]
    pub async fn update_password(&self, login_id: &str, hashed_password: &str) -> Result<(), ApiError> {
        info!("更新用户密码: {}", login_id);
        
        // 解析UUID
        let login_uuid = Uuid::parse_str(login_id)
            .map_err(|_| ApiError::ValidationError("无效的登录ID格式".to_string()))?;
        
        let query = r#"
            UPDATE m_login 
            SET 
                pass_word = $2,
                updated_datetime = CURRENT_TIMESTAMP
            WHERE login_id = $1
        "#;
        
        match sqlx::query(query)
            .bind(login_uuid)
            .bind(hashed_password)
            .execute(self.get_pool())
            .await
        {
            Ok(result) => {
                if result.rows_affected() > 0 {
                    info!("用户密码更新成功: {}", login_id);
                    Ok(())
                } else {
                    error!("用户密码更新失败: 未找到用户 {}", login_id);
                    Err(ApiError::NotFoundError("用户不存在".to_string()))
                }
            }
            Err(e) => {
                error!("更新用户密码错误: {}", e);
                Err(ApiError::InternalServerError)
            }
        }
    }

    /// 删除已使用的密码重置验证码
    /// 
    /// # 参数
    /// * `email` - 邮箱地址
    #[instrument(skip(self))]
    pub async fn delete_password_reset_code(&self, email: &str) -> Result<(), ApiError> {
        info!("删除密码重置验证码: {}", email);
        
        // 标记验证码为已使用，而不是直接删除
        let query = r#"
            UPDATE password_reset_codes 
            SET 
                is_used = '1',
                used_datetime = CURRENT_TIMESTAMP
            WHERE email = $1 AND is_used = '0'
        "#;
        
        match sqlx::query(query)
            .bind(email)
            .execute(self.get_pool())
            .await
        {
            Ok(result) => {
                if result.rows_affected() > 0 {
                    info!("密码重置验证码标记为已使用: {}", email);
                } else {
                    info!("未找到待标记的密码重置验证码: {}", email);
                }
                Ok(())
            }
            Err(e) => {
                error!("标记密码重置验证码为已使用失败: {}", e);
                Err(ApiError::InternalServerError)
            }
        }
    }

    // ================================
    // 令牌管理
    // ================================

    /// 使访问令牌失效
    /// 
    /// # 参数
    /// * `login_id` - 登录ID (String format)
    #[instrument(skip(self))]
    pub async fn invalidate_access_token(&self, login_id: &str) -> Result<(), ApiError> {
        info!("使访问令牌失效: {}", login_id);
        
        // 解析UUID
        let login_uuid = Uuid::parse_str(login_id)
            .map_err(|_| ApiError::ValidationError("无效的登录ID格式".to_string()))?;
        
        let query = r#"
            UPDATE m_login 
            SET 
                login_token = NULL,
                login_token_issued_flag = '0',
                is_login = '0',
                updated_datetime = CURRENT_TIMESTAMP
            WHERE login_id = $1
        "#;
        
        match sqlx::query(query)
            .bind(login_uuid)
            .execute(self.get_pool())
            .await
        {
            Ok(result) => {
                if result.rows_affected() > 0 {
                    info!("访问令牌失效成功: {}", login_id);
                } else {
                    info!("未找到要失效的访问令牌: {}", login_id);
                }
                Ok(())
            }
            Err(e) => {
                error!("使访问令牌失效错误: {}", e);
                Err(ApiError::InternalServerError)
            }
        }
    }

    /// 记录用户登出
    /// 
    /// # 参数
    /// * `login_id` - 登录ID (String format)
    #[instrument(skip(self))]
    pub async fn record_logout(&self, login_id: &str) -> Result<(), ApiError> {
        info!("记录用户登出: {}", login_id);
        
        // 解析UUID
        let login_uuid = Uuid::parse_str(login_id)
            .map_err(|_| ApiError::ValidationError("无效的登录ID格式".to_string()))?;
        
        let query = r#"
            UPDATE m_login 
            SET 
                login_token = NULL,
                login_token_issued_flag = '0',
                is_login = '0',
                logout_datetime = CURRENT_TIMESTAMP,
                updated_datetime = CURRENT_TIMESTAMP
            WHERE login_id = $1
        "#;
        
        match sqlx::query(query)
            .bind(login_uuid)
            .execute(self.get_pool())
            .await
        {
            Ok(result) => {
                if result.rows_affected() > 0 {
                    info!("用户登出记录成功: {}", login_id);
                } else {
                    info!("未找到要登出的用户: {}", login_id);
                }
                Ok(())
            }
            Err(e) => {
                error!("记录用户登出错误: {}", e);
                Err(ApiError::InternalServerError)
            }
        }
    }
}