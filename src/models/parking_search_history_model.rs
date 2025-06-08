use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;

/// t_favoritesテーブルのモデル
#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
pub struct ParkingSearchHistoryResponse {
    pub search_id: String,
    pub user_id: String,
    pub parking_lot_id: String,
    pub parking_lot_name: String,
    pub condition_keyword_free: String,
    pub condition_use_date_start: String,
    pub condition_use_date_end: String,
    pub condition_vehicle_type_id: String,
    pub vehicle_type: String,
    pub condition_rental_type_id: String,
    pub rental_type: String,
    pub rental_value: String,
    pub created_datetime: DateTime<Utc>,
    pub updated_datetime: DateTime<Utc>,
}
/// t_parking_statusテーブルのリクエスト
#[derive(Debug, Serialize, Deserialize)]
pub struct ParkingSearchHistoryRequest {
    pub user_id: String,
}    
