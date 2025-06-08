use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;

/// m_parking_featuresテーブルのモデル
#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
pub struct ParkingFeatureResponse {
    pub feature_id: String,
    pub feature_type: String,
    pub feature_value: String,
    pub created_datetime: DateTime<Utc>,
    pub updated_datetime: DateTime<Utc>,
}

/// m_parking_featuresテーブルのリクエスト
#[derive(Debug, Serialize, Deserialize)]
pub struct ParkingFeatureRequest {
    pub parking_lot_id: String,
}    
