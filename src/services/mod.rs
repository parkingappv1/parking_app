//！services/mod.rs - サービスモジュール
//! Service layer implementation for the parking application.
//!
//! This module contains all service implementations that encapsulate the business logic
//! of the application. Services are responsible for coordinating between repositories
//! and controllers, implementing validation rules, and applying business rules.

pub mod email_service;
pub mod sms_service;
pub mod token_service;

// 共通で使用するサービスの再エクスポート
pub use email_service::EmailService;
pub use sms_service::SmsService;
pub use token_service::TokenService;

/// 各サービスの実装をここに追加

/// Authentication service for user signup and signin.
pub mod auth_signin_service;
pub use auth_signin_service::AuthSigninService;

/// Authentication service for user signup and signin.
pub mod auth_signup_service;
pub use auth_signup_service::AuthSignupService;

/// Parking search service for parking lot search functionality.
pub mod parking_search_service;
pub use parking_search_service::ParkingSearchService;

/// サービス層の初期化関数
pub fn init() {
    use tracing::info;
    info!("サービス層を初期化しています！");
}
