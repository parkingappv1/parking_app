// controllers/mod.rs - コントローラーモジュール
// このモジュールはHTTPリクエストを処理し、適切なサービスを呼び出すコントローラーを提供します。
// 各コントローラーはリクエストの解析、入力検証、レスポンスのフォーマットを担当します。


pub mod api_error;
pub mod api_response;
pub mod constants;
pub use api_error::ApiError;
pub use api_response::{ApiResponse, error_response, success_response};

// バリデーション機能をコントローラーモジュール内に移動
pub mod validation; 
pub use validation::Validator;

// Note: 新しいコントローラーを追加する場合はここに追加してください
// 例: pub mod parking_controller;

// 追加: healthコントローラー
pub mod health_controller;
// 追加: CSRFトークン用コントローラー
pub mod api_base;
// 追加: サインイン用コントローラー
pub mod auth_signin_controller;
pub use auth_signin_controller::*;
// 追加: サインアップ用コントローラー
pub mod auth_signup_controller;

// 追加: 駐車場検索用コントローラー
pub mod parking_search_controller;

pub mod user_home_controller;
pub mod use_history_controller;

/// Initialize controllers if needed
pub fn init() {
    tracing::info!("コントローラーを初期化しています！");
    // Controller-specific initialization could go here
}
