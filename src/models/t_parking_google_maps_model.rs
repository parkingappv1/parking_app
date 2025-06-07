// src/models/t_parking_google_maps_model.rs
//! Google Maps関連情報テーブル（t_parking_google_maps）のモデル
//! 
//! 駐車場のGoogle Maps関連情報（緯度・経度、Place ID、ズームレベル、
//! 地図タイプ、URL、埋め込みリンクなど）を管理するモデル

use serde::{Deserialize, Serialize};

/// Google Maps関連情報モデル（t_parking_google_mapsテーブル）
/// 
/// 駐車場のGoogle Maps関連情報を格納するモデル。
/// 1つの駐車場IDに対し複数のGoogle Maps情報を関連付け可能。
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct TParkingGoogleMapsModel {
    /// 論理名: Google Maps情報ID
    /// 物理名: google_maps_id（UUID v4）
    pub google_maps_id: String,
    
    /// 論理名: 駐車場ID
    /// 物理名: parking_lot_id（形式: P-XXXXXX）
    pub parking_lot_id: String,
    
    /// 論理名: 緯度
    /// 物理名: latitude（Google Maps用、可NULL）
    pub latitude: Option<f64>,
    
    /// 論理名: 経度
    /// 物理名: longitude（Google Maps用、可NULL）
    pub longitude: Option<f64>,
    
    /// 論理名: Google Place ID
    /// 物理名: place_id（場所特定用、可NULL）
    pub place_id: Option<String>,
    
    /// 論理名: ズームレベル
    /// 物理名: zoom_level（0～21、可NULL）
    pub zoom_level: Option<i32>,
    
    /// 論理名: 地図タイプ
    /// 物理名: map_type（roadmap, satellite, hybrid, terrain、可NULL）
    pub map_type: Option<String>,
    
    /// 論理名: Google Maps URL
    /// 物理名: google_maps_url（可NULL）
    pub google_maps_url: Option<String>,
    
    /// 論理名: Google Maps埋め込みリンク
    /// 物理名: google_maps_embed（可NULL）
    pub google_maps_embed: Option<String>,
    
    /// 論理名: 説明
    /// 物理名: description（可NULL）
    pub description: Option<String>,
    
    /// 論理名: 作成日時
    /// 物理名: created_datetime
    pub created_datetime: Option<String>,
    
    /// 論理名: 更新日時
    /// 物理名: updated_datetime
    pub updated_datetime: Option<String>,
}

impl TParkingGoogleMapsModel {
    /// 新しいGoogle Maps情報インスタンスを作成
    pub fn new(
        google_maps_id: Option<String>,
        parking_lot_id: Option<String>,
        latitude: Option<f64>,
        longitude: Option<f64>,
        place_id: Option<String>,
        zoom_level: Option<i32>,
        map_type: Option<String>,
        google_maps_url: Option<String>,
        google_maps_embed: Option<String>,
        description: Option<String>,
        created_datetime: Option<String>,
        updated_datetime: Option<String>,
    ) -> Self {
        Self {
            google_maps_id: google_maps_id.unwrap_or_default(),
            parking_lot_id: parking_lot_id.unwrap_or_default(),
            latitude,
            longitude,
            place_id,
            zoom_level,
            map_type,
            google_maps_url,
            google_maps_embed,
            description,
            created_datetime,
            updated_datetime,
        }
    }
    
    /// 位置情報（緯度・経度）が利用可能かどうかを判定
    pub fn has_location(&self) -> bool {
        self.latitude.is_some() && self.longitude.is_some()
    }
    
    /// ズームレベルが有効範囲内かどうかを判定
    pub fn is_valid_zoom_level(&self) -> bool {
        self.zoom_level.map_or(true, |zoom| zoom >= 0 && zoom <= 21)
    }
    
    /// 地図タイプが有効かどうかを判定
    pub fn is_valid_map_type(&self) -> bool {
        if let Some(ref map_type) = self.map_type {
            matches!(map_type.as_str(), "roadmap" | "satellite" | "hybrid" | "terrain")
        } else {
            true
        }
    }
    
    /// Google Maps URLを生成（緯度・経度が存在する場合）
    pub fn generate_google_maps_url(&self) -> Option<String> {
        if let (Some(lat), Some(lng)) = (self.latitude, self.longitude) {
            let zoom = self.zoom_level.unwrap_or(15);
            Some(format!(
                "https://www.google.com/maps?q={},{}&z={}",
                lat, lng, zoom
            ))
        } else {
            None
        }
    }
    
    /// Google Maps埋め込みURLを生成（緯度・経度が存在する場合）
    pub fn generate_embed_url(&self) -> Option<String> {
        if let (Some(lat), Some(lng)) = (self.latitude, self.longitude) {
            let zoom = self.zoom_level.unwrap_or(15);
            let map_type = self.map_type.as_deref().unwrap_or("roadmap");
            Some(format!(
                "https://www.google.com/maps/embed/v1/place?key={{API_KEY}}&q={},{}&zoom={}&maptype={}",
                lat, lng, zoom, map_type
            ))
        } else {
            None
        }
    }
    
    /// 2点間の距離を計算（km単位、Haversine公式）
    pub fn calculate_distance_to(&self, target_lat: f64, target_lng: f64) -> Option<f64> {
        if let (Some(lat), Some(lng)) = (self.latitude, self.longitude) {
            Some(Self::haversine_distance(lat, lng, target_lat, target_lng))
        } else {
            None
        }
    }
    
    /// Haversine公式による2点間距離計算（km単位）
    fn haversine_distance(lat1: f64, lng1: f64, lat2: f64, lng2: f64) -> f64 {
        const EARTH_RADIUS_KM: f64 = 6371.0;
        
        let lat1_rad = lat1.to_radians();
        let lat2_rad = lat2.to_radians();
        let delta_lat = (lat2 - lat1).to_radians();
        let delta_lng = (lng2 - lng1).to_radians();
        
        let a = (delta_lat / 2.0).sin().powi(2)
            + lat1_rad.cos() * lat2_rad.cos() * (delta_lng / 2.0).sin().powi(2);
        let c = 2.0 * a.sqrt().atan2((1.0 - a).sqrt());
        
        EARTH_RADIUS_KM * c
    }
    
    /// 検証メソッド
    pub fn validate(&self) -> Result<(), String> {
        // 緯度の範囲チェック
        if let Some(lat) = self.latitude {
            if lat < -90.0 || lat > 90.0 {
                return Err("緯度は-90から90の範囲内である必要があります".to_string());
            }
        }
        
        // 経度の範囲チェック
        if let Some(lng) = self.longitude {
            if lng < -180.0 || lng > 180.0 {
                return Err("経度は-180から180の範囲内である必要があります".to_string());
            }
        }
        
        // ズームレベルのチェック
        if !self.is_valid_zoom_level() {
            return Err("ズームレベルは0から21の範囲内である必要があります".to_string());
        }
        
        // 地図タイプのチェック
        if !self.is_valid_map_type() {
            return Err("地図タイプは roadmap, satellite, hybrid, terrain のいずれかである必要があります".to_string());
        }
        
        Ok(())
    }
}

/// Google Maps情報の作成・更新用リクエストモデル
#[derive(Debug, Deserialize)]
pub struct GoogleMapsRequest {
    pub parking_lot_id: String,
    pub latitude: Option<f64>,
    pub longitude: Option<f64>,
    pub place_id: Option<String>,
    pub zoom_level: Option<i32>,
    pub map_type: Option<String>,
    pub google_maps_url: Option<String>,
    pub google_maps_embed: Option<String>,
    pub description: Option<String>,
}

impl GoogleMapsRequest {
    /// リクエストデータの検証
    pub fn validate(&self) -> Result<(), String> {
        // 駐車場IDの検証
        if self.parking_lot_id.trim().is_empty() {
            return Err("駐車場IDは必須です".to_string());
        }
        
        // 緯度の範囲チェック
        if let Some(lat) = self.latitude {
            if lat < -90.0 || lat > 90.0 {
                return Err("緯度は-90から90の範囲内である必要があります".to_string());
            }
        }
        
        // 経度の範囲チェック
        if let Some(lng) = self.longitude {
            if lng < -180.0 || lng > 180.0 {
                return Err("経度は-180から180の範囲内である必要があります".to_string());
            }
        }
        
        // ズームレベルのチェック
        if let Some(zoom) = self.zoom_level {
            if zoom < 0 || zoom > 21 {
                return Err("ズームレベルは0から21の範囲内である必要があります".to_string());
            }
        }
        
        // 地図タイプのチェック
        if let Some(ref map_type) = self.map_type {
            if !matches!(map_type.as_str(), "roadmap" | "satellite" | "hybrid" | "terrain") {
                return Err("地図タイプは roadmap, satellite, hybrid, terrain のいずれかである必要があります".to_string());
            }
        }
        
        Ok(())
    }
}

/// Google Maps レスポンス用構造体
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct GoogleMapsResponse {
    pub google_maps_id: String,
    pub parking_lot_id: String,
    pub latitude: Option<f64>,
    pub longitude: Option<f64>,
    pub place_id: Option<String>,
    pub zoom_level: Option<i32>,
    pub map_type: Option<String>,
    pub google_maps_url: Option<String>,
    pub google_maps_embed: Option<String>,
    pub description: Option<String>,
    pub created_datetime: String,
    pub updated_datetime: String,
}

impl From<TParkingGoogleMapsModel> for GoogleMapsResponse {
    fn from(model: TParkingGoogleMapsModel) -> Self {
        Self {
            google_maps_id: model.google_maps_id,
            parking_lot_id: model.parking_lot_id,
            latitude: model.latitude,
            longitude: model.longitude,
            place_id: model.place_id,
            zoom_level: model.zoom_level,
            map_type: model.map_type,
            google_maps_url: model.google_maps_url,
            google_maps_embed: model.google_maps_embed,
            description: model.description,
            created_datetime: model.created_datetime.unwrap_or_default(),
            updated_datetime: model.updated_datetime.unwrap_or_default(),
        }
    }
}
