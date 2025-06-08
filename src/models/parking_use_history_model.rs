use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;

/// t_reservationsテーブルのモデル
#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
pub struct ParkingUseHistoryResponse {
    pub reservation_id: String,
    pub parking_lot_name: String,
    pub area: String,
    pub entry_datetime: String,
    pub exit_datetime: String,
    pub start_datetime: String,
    pub end_datetime: String,
    pub amount: String,
    pub created_datetime: DateTime<Utc>,
    pub updated_datetime: DateTime<Utc>,
}

/// t_reservation_detailsテーブルのモデル
#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
pub struct ParkingUseHistoryDetailResponse {
    pub detail_id: String,
    pub parking_lot_id: String,
    pub parking_lot_name: String,
    pub area: String,
    pub entry_datetime: String,
    pub exit_datetime: String,
    pub start_datetime: String,
    pub end_datetime: String,
    pub amount: String,
    pub created_datetime: DateTime<Utc>,
    pub updated_datetime: DateTime<Utc>,
}

/// t_reservationsテーブルのリクエスト
#[derive(Debug, Serialize, Deserialize)]
pub struct ParkingUseHistoryRequest {
    pub user_id: String,
}    

/// t_reservation_detailsテーブルのリクエスト
#[derive(Debug, Serialize, Deserialize)]
pub struct ParkingUseHistoryDetailRequest {
    pub reservation_id: String,
}    

