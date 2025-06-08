use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;

/// 入出庫状況のモデル
#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
pub struct ParkingStatusResponse {
    pub status_id: String,
    pub reservation_id: String,
    pub parking_lot_id: String,
    pub parking_lot_name: String,
    pub entry_status: String,
    pub exit_status: String,
    pub entry_datetime: String,
    pub exit_datetime: String,
    pub start_datetime: String,
    pub end_datetime: String,
    pub created_datetime: DateTime<Utc>,
    pub updated_datetime: DateTime<Utc>,
}

/// 入出庫状況取得のリクエスト
#[derive(Debug, Serialize, Deserialize)]
pub struct ParkingStatusRequest {
    pub user_id: String,
    pub status: String,
}    

/// 入出庫状況更新のリクエスト
#[derive(Debug, Serialize, Deserialize)]
pub struct UpdateParkingStatusRequest {
    pub status_id: String,
    pub reservation_id: String,
    pub check_inout_kbn: String,
}  