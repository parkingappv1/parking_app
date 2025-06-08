use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;

/// t_favoritesテーブルのモデル
#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
pub struct FavoriteResponse {
    pub favorite_id: String,
    pub user_id: String,
    pub parking_lot_id: String,
    pub parking_lot_name: String,
    pub nearest_station: String,
    pub charge: String,
    pub created_datetime: DateTime<Utc>,
    pub updated_datetime: DateTime<Utc>,
}

/// t_parking_statusテーブルのリクエスト
#[derive(Debug, Serialize, Deserialize)]
pub struct FavoritesRequest {
    pub user_id: String,
}    
