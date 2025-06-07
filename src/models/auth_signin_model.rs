//! # 认证登录模型模块
//! 
//! 基于Flutter Dart代码的SignIn API和数据库schema设计的Rust实现
//! 提供统一的登录请求、响应和相关数据模型
//! 
//! ## 功能特性
//! - 支持邮箱或电话号码登录
//! - 密码重置流程
//! - JWT令牌管理
//! - 与前端Flutter模型保持一致性

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use crate::models::{m_login_model::MLoginModel, m_users_model::MUsersModel, m_owners_model::MOwnersModel};

// ================================
// 登录请求/响应模型 - 对应Flutter AuthSigninModel
// ================================

/// 用户登录请求模型
/// 
/// 对应Flutter中的AuthSigninModel，支持邮箱或电话号码登录
/// 根据数据库schema m_login表设计
#[derive(Debug, Deserialize, Clone)]
pub struct AuthSigninRequest {
    /// 邮箱地址或电话号码 - 对应m_login.email或phone_number字段
    /// VARCHAR(255) NOT NULL
    pub email: String,
    
    /// 密码 - 对应m_login.pass_word字段（存储时为bcrypt哈希）
    /// TEXT NOT NULL
    pub password: String,
    
    /// 记住登录状态 - 影响令牌过期时间
    #[serde(default)]
    pub remember_me: bool,
}

/// 用户登录响应模型
/// 
/// 返回给Flutter客户端的登录成功响应，包含用户信息和认证令牌
/// 统一支持普通用户和停车场业主
#[derive(Debug, Serialize, Clone)]
pub struct AuthSigninResponse {
    /// 用户唯一标识 - m_users.user_id或m_owners.owner_id
    pub id: String,
    
    /// 邮箱地址 - m_login.email
    pub email: String,
    
    /// 电话号码 - m_login.phone_number
    #[serde(rename = "phone_number")]
    pub phone_number: Option<String>,
    
    /// 用户姓名 - m_users.full_name或m_owners.full_name
    #[serde(rename = "full_name")]
    pub full_name: String,
    
    /// 是否为停车场业主 - m_login.is_user_owner ("0"=用户, "1"=业主)
    #[serde(rename = "is_owner")]
    pub is_owner: bool,
    
    /// 访问令牌 - 短期令牌，用于API认证
    pub token: String,
    
    /// 刷新令牌 - 长期令牌，用于更新访问令牌
    #[serde(rename = "refresh_token")]
    pub refresh_token: String,
}

/// 当前用户信息响应模型
/// 
/// 用于获取当前登录用户的详细信息
#[derive(Debug, Serialize)]
pub struct CurrentUserResponse {
    /// 用户标识
    pub id: String,
    
    /// 登录ID
    pub login_id: String,
    
    /// 邮箱
    pub email: String,
    
    /// 电话号码
    pub phone_number: Option<String>,
    
    /// 姓名
    pub full_name: String,
    
    /// 用户类型
    pub user_type: String,
    
    /// 是否验证
    pub is_verified: bool,
    
    /// 最后登录时间
    pub last_login: Option<DateTime<Utc>>,
    
    /// 账户创建时间
    pub created_at: DateTime<Utc>,
}

// ================================
// 密码重置相关模型 - 对应Flutter密码重置功能
// ================================

/// 密码重置请求模型
/// 
/// 对应Flutter中的密码重置请求功能
#[derive(Debug, Deserialize)]
pub struct PasswordResetRequest {
    /// 邮箱地址 - 用于发送重置邮件
    pub email: String,
}

/// 密码重置验证模型
/// 
/// 验证重置码的有效性
#[derive(Debug, Deserialize)]
pub struct PasswordResetVerification {
    /// 邮箱地址
    pub email: String,
    
    /// 验证码 - 从邮件中获取
    pub verification_code: String,
}

/// 密码重置完成模型
/// 
/// 完成密码重置操作
#[derive(Debug, Deserialize)]
pub struct PasswordResetCompletion {
    /// 邮箱地址
    pub email: String,
    
    /// 验证码
    pub verification_code: String,
    
    /// 新密码
    pub new_password: String,
}

/// 令牌刷新完成响应模型
#[derive(Debug, Serialize)]
pub struct RefreshTokenCompletion {
    /// 成功消息
    pub message: String,
    
    /// 用户登录标识 - 用于后续操作
    pub login_id: String,
}

// ================================
// 令牌刷新模型
// ================================

/// 刷新令牌请求模型
/// 
/// 用于刷新访问令牌的请求
#[derive(Debug, Deserialize, Clone)]
pub struct RefreshTokenRequest {
    /// 刷新令牌
    pub refresh_token: String,
}

/// 刷新令牌响应模型
/// 
/// 返回新的访问令牌和刷新令牌
#[derive(Debug, Serialize, Clone)]
pub struct RefreshTokenResponse {
    /// 新的访问令牌
    pub access_token: String,
    
    /// 新的刷新令牌
    pub refresh_token: String,
    
    /// 令牌过期时间（秒）
    pub expires_in: i64,
}

// ================================
// 数据库记录转换实现
// ================================

impl AuthSigninResponse {
    /// 从用户数据库记录创建登录响应
    /// 
    /// # 参数
    /// * `login` - 登录信息记录 (m_login表)
    /// * `user` - 用户信息记录 (m_users表)
    /// * `access_token` - JWT访问令牌
    /// * `refresh_token` - JWT刷新令牌
    pub fn from_user_record(
        login: &MLoginModel,
        user: &MUsersModel,
        access_token: String,
        refresh_token: String,
    ) -> Self {
        Self {
            id: user.user_id.clone(),
            email: login.email.clone(),
            phone_number: user.phone_number.clone(),
            full_name: user.full_name.clone(),
            is_owner: false, // 普通用户
            token: access_token,
            refresh_token,
        }
    }
    
    /// 从业主数据库记录创建登录响应
    /// 
    /// # 参数
    /// * `login` - 登录信息记录 (m_login表)
    /// * `owner` - 业主信息记录 (m_owners表)
    /// * `access_token` - JWT访问令牌
    /// * `refresh_token` - JWT刷新令牌
    pub fn from_owner_record(
        login: &MLoginModel,
        owner: &MOwnersModel,
        access_token: String,
        refresh_token: String,
    ) -> Self {
        Self {
            id: owner.owner_id.clone(),
            email: login.email.clone(),
            phone_number: Some(owner.phone_number.clone()),
            full_name: owner.full_name.clone(),
            is_owner: true, // 停车场业主
            token: access_token,
            refresh_token,
        }
    }
}

impl CurrentUserResponse {
    /// 从用户记录创建当前用户响应
    pub fn from_user_record(login: &MLoginModel, user: &MUsersModel) -> Self {
        Self {
            id: user.user_id.clone(),
            login_id: login.login_id.clone(),
            email: login.email.clone(),
            phone_number: user.phone_number.clone(),
            full_name: user.full_name.clone(),
            user_type: "user".to_string(),
            is_verified: true,
            last_login: Self::parse_datetime(&login.login_datetime),
            created_at: Self::parse_datetime(&user.created_datetime).unwrap_or_else(Utc::now),
        }
    }
    
    /// 从业主记录创建当前用户响应
    pub fn from_owner_record(login: &MLoginModel, owner: &MOwnersModel) -> Self {
        Self {
            id: owner.owner_id.clone(),
            login_id: login.login_id.clone(),
            email: login.email.clone(),
            phone_number: Some(owner.phone_number.clone()),
            full_name: owner.full_name.clone(),
            user_type: "owner".to_string(),
            is_verified: true,
            last_login: Self::parse_datetime(&login.login_datetime),
            created_at: Self::parse_datetime(&owner.created_datetime).unwrap_or_else(Utc::now),
        }
    }
    
    /// 解析日期时间字符串
    pub fn parse_datetime(datetime_str: &Option<String>) -> Option<DateTime<Utc>> {
        datetime_str.as_ref().and_then(|s| {
            chrono::DateTime::parse_from_rfc3339(s)
                .map(|dt| dt.with_timezone(&Utc))
                .or_else(|_| {
                    // 尝试其他日期格式
                    chrono::NaiveDateTime::parse_from_str(s, "%Y-%m-%d %H:%M:%S")
                        .map(|ndt| DateTime::from_naive_utc_and_offset(ndt, Utc))
                })
                .ok()
        })
    }
}

// ================================
// 验证功能实现
// ================================

impl AuthSigninRequest {
    /// 验证登录请求数据
    /// 
    /// 根据数据库schema约束验证输入数据
    pub fn validate(&self) -> Result<(), String> {
        // 邮箱/电话号码验证 - VARCHAR(255) NOT NULL
        if self.email.trim().is_empty() {
            return Err("メールアドレスまたは電話番号は必須です".to_string());
        }
        
        if self.email.len() > 255 {
            return Err("メールアドレスは255文字以内で入力してください".to_string());
        }
        
        // 密码验证 - TEXT NOT NULL（前端应已验证强度）
        if self.password.is_empty() {
            return Err("パスワードは必須です".to_string());
        }
        
        if self.password.len() < 6 {
            return Err("パスワードは6文字以上である必要があります".to_string());
        }
        
        // 验证邮箱或电话号码格式
        if !self.is_valid_email() && !self.is_valid_phone() {
            return Err("有効なメールアドレスまたは電話番号を入力してください".to_string());
        }
        
        Ok(())
    }
    
    /// 检查是否为有效邮箱格式
    fn is_valid_email(&self) -> bool {
        use regex::Regex;
        let email_regex = Regex::new(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").unwrap();
        email_regex.is_match(&self.email)
    }
    
    /// 检查是否为有效电话号码格式（日本格式）
    fn is_valid_phone(&self) -> bool {
        use regex::Regex;
        let phone_regex = Regex::new(r"^(0[0-9]{1,4}-[0-9]{1,4}-[0-9]{4}|0[0-9]{9,10})$").unwrap();
        phone_regex.is_match(&self.email) // email字段可能包含电话号码
    }
    
    /// 确定登录方式（邮箱或电话号码）
    pub fn login_type(&self) -> LoginType {
        if self.is_valid_email() {
            LoginType::Email
        } else if self.is_valid_phone() {
            LoginType::Phone
        } else {
            LoginType::Unknown
        }
    }
}

/// 登录方式枚举
#[derive(Debug, Clone, PartialEq)]
pub enum LoginType {
    /// 邮箱登录
    Email,
    /// 电话号码登录
    Phone,
    /// 未知格式
    Unknown,
}

impl LoginType {
    /// 根据输入字符串检测登录方式
    pub fn detect(input: &str) -> Self {
        use regex::Regex;
        
        // 邮箱格式检查
        let email_regex = Regex::new(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").unwrap();
        if email_regex.is_match(input) {
            return LoginType::Email;
        }
        
        // 电话号码格式检查（日本格式）
        let phone_regex = Regex::new(r"^(0[0-9]{1,4}-[0-9]{1,4}-[0-9]{4}|0[0-9]{9,10})$").unwrap();
        if phone_regex.is_match(input) {
            return LoginType::Phone;
        }
        
        LoginType::Unknown
    }
}

impl PasswordResetRequest {
    /// 验证密码重置请求
    pub fn validate(&self) -> Result<(), String> {
        if self.email.trim().is_empty() {
            return Err("メールアドレスは必須です".to_string());
        }
        
        if self.email.len() > 255 {
            return Err("メールアドレスは255文字以内で入力してください".to_string());
        }
        
        if !self.is_valid_email() {
            return Err("有効なメールアドレス形式を入力してください".to_string());
        }
        
        Ok(())
    }
    
    fn is_valid_email(&self) -> bool {
        use regex::Regex;
        let email_regex = Regex::new(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").unwrap();
        email_regex.is_match(&self.email)
    }
}

impl PasswordResetCompletion {
    /// 验证密码重置完成请求
    pub fn validate(&self) -> Result<(), String> {
        if self.email.trim().is_empty() {
            return Err("メールアドレスは必須です".to_string());
        }
        
        if self.verification_code.trim().is_empty() {
            return Err("認証コードは必須です".to_string());
        }
        
        if self.new_password.len() < 6 {
            return Err("新しいパスワードは6文字以上である必要があります".to_string());
        }
        
        Ok(())
    }
}
