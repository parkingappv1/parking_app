// src/models/t_parking_lots_model.rs
//! 駐車場基本情報テーブル（t_parking_lots）のモデル
//! 
//! 駐車場の名称、住所、電話番号、収容台数、料金、特徴概要、サイズ制限、車種、
//! 最寄り駅、利用状況などの基本情報を格納するモデル

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

/// 駐車場基本情報モデル（t_parking_lotsテーブル）
/// 
/// 駐車場の基本情報を格納する主要なモデル。
/// 関連する詳細情報は他のテーブル（Google Maps、特徴、車種など）で管理される。
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct TParkingLotsModel {
    /// 論理名: 駐車場ID
    /// 物理名: parking_lot_id（形式: P-XXXXXX）
    pub parking_lot_id: String,
    
    /// 論理名: オーナーID
    /// 物理名: owner_id（形式: owner_XXXXXX）
    pub owner_id: String,
    
    /// 論理名: 駐車場名
    /// 物理名: parking_lot_name
    pub parking_lot_name: String,
    
    /// 論理名: 郵便番号
    /// 物理名: postal_code（例: 123-4567）
    pub postal_code: String,
    
    /// 論理名: 都道府県
    /// 物理名: prefecture
    pub prefecture: String,
    
    /// 論理名: 市区町村
    /// 物理名: city
    pub city: String,
    
    /// 論理名: 番地・建物名
    /// 物理名: address_detail
    pub address_detail: String,
    
    /// 論理名: 電話番号
    /// 物理名: phone_number
    pub phone_number: String,
    
    /// 論理名: 収容台数
    /// 物理名: capacity
    pub capacity: i32,
    
    /// 論理名: 収容空き台数
    /// 物理名: available_capacity
    pub available_capacity: Option<i32>,
    
    /// 論理名: 貸出タイプ
    /// 物理名: rental_type（時間単位、日間単位）
    pub rental_type: Option<String>,
    
    /// 論理名: 料金
    /// 物理名: charge
    pub charge: String,
    
    /// 論理名: 特徴概要
    /// 物理名: features_tip
    pub features_tip: Option<String>,
    
    /// 論理名: 長さ制限
    /// 物理名: length_limit（cm単位）
    pub length_limit: Option<i32>,
    
    /// 論理名: 幅制限
    /// 物理名: width_limit（cm単位）
    pub width_limit: Option<i32>,
    
    /// 論理名: 高さ制限
    /// 物理名: height_limit（cm単位）
    pub height_limit: Option<i32>,
    
    /// 論理名: 重量制限
    /// 物理名: weight_limit（kg単位）
    pub weight_limit: Option<i32>,
    
    /// 論理名: 車高制限
    /// 物理名: car_height_limit
    pub car_height_limit: Option<String>,
    
    /// 論理名: タイヤ幅制限
    /// 物理名: tire_width_limit
    pub tire_width_limit: Option<String>,
    
    /// 論理名: 車種
    /// 物理名: vehicle_type
    pub vehicle_type: Option<String>,
    
    /// 論理名: 最寄り駅
    /// 物理名: nearest_station
    pub nearest_station: Option<String>,
    
    /// 論理名: 状態
    /// 物理名: status（アクティブ、停止中）
    pub status: String,
    
    /// 論理名: 利用開始日
    /// 物理名: start_date
    pub start_date: Option<String>,
    
    /// 論理名: 利用停止日
    /// 物理名: end_date
    pub end_date: Option<String>,
    
    /// 論理名: 利用停止開始日時
    /// 物理名: end_start_datetime
    pub end_start_datetime: Option<String>,
    
    /// 論理名: 利用停止終了日時
    /// 物理名: end_end_datetime
    pub end_end_datetime: Option<String>,
    
    /// 論理名: 停止理由
    /// 物理名: end_reason
    pub end_reason: Option<String>,
    
    /// 論理名: 停止理由詳細
    /// 物理名: end_reason_detail
    pub end_reason_detail: Option<String>,
    
    /// 論理名: 注意事項
    /// 物理名: notes
    pub notes: Option<String>,
    
    /// 論理名: 作成日時
    /// 物理名: created_datetime
    pub created_datetime: Option<String>,
    
    /// 論理名: 更新日時
    /// 物理名: updated_datetime
    pub updated_datetime: Option<String>,
}

impl TParkingLotsModel {
    /// 新しい駐車場基本情報インスタンスを作成
    pub fn new(
        parking_lot_id: Option<String>,
        owner_id: Option<String>,
        parking_lot_name: Option<String>,
        postal_code: Option<String>,
        prefecture: Option<String>,
        city: Option<String>,
        address_detail: Option<String>,
        phone_number: Option<String>,
        capacity: Option<i32>,
        available_capacity: Option<i32>,
        rental_type: Option<String>,
        charge: Option<String>,
        features_tip: Option<String>,
        length_limit: Option<i32>,
        width_limit: Option<i32>,
        height_limit: Option<i32>,
        weight_limit: Option<i32>,
        car_height_limit: Option<String>,
        tire_width_limit: Option<String>,
        vehicle_type: Option<String>,
        nearest_station: Option<String>,
        status: Option<String>,
        start_date: Option<String>,
        end_date: Option<String>,
        end_start_datetime: Option<String>,
        end_end_datetime: Option<String>,
        end_reason: Option<String>,
        end_reason_detail: Option<String>,
        notes: Option<String>,
        created_datetime: Option<String>,
        updated_datetime: Option<String>,
    ) -> Self {
        Self {
            parking_lot_id: parking_lot_id.unwrap_or_default(),
            owner_id: owner_id.unwrap_or_default(),
            parking_lot_name: parking_lot_name.unwrap_or_default(),
            postal_code: postal_code.unwrap_or_default(),
            prefecture: prefecture.unwrap_or_default(),
            city: city.unwrap_or_default(),
            address_detail: address_detail.unwrap_or_default(),
            phone_number: phone_number.unwrap_or_default(),
            capacity: capacity.unwrap_or(0),
            available_capacity,
            rental_type,
            charge: charge.unwrap_or_default(),
            features_tip,
            length_limit,
            width_limit,
            height_limit,
            weight_limit,
            car_height_limit,
            tire_width_limit,
            vehicle_type,
            nearest_station,
            status: status.unwrap_or_default(),
            start_date,
            end_date,
            end_start_datetime,
            end_end_datetime,
            end_reason,
            end_reason_detail,
            notes,
            created_datetime,
            updated_datetime,
        }
    }
    
    /// 完全な住所を取得
    pub fn get_full_address(&self) -> String {
        format!("{}{}{}", self.prefecture, self.city, self.address_detail)
    }
    
    /// 駐車場が利用可能かどうかを判定
    pub fn is_available(&self) -> bool {
        self.status == "アクティブ"
    }
    
    /// 空き台数が存在するかどうかを判定
    pub fn has_available_space(&self) -> bool {
        self.available_capacity.map_or(true, |capacity| capacity > 0)
    }
    
    /// 日付時刻文字列を安全に解析
    pub fn parse_datetime(datetime_str: &Option<String>) -> Option<DateTime<Utc>> {
        datetime_str
            .as_ref()
            .and_then(|dt| {
                DateTime::parse_from_rfc3339(dt)
                    .map(|dt| dt.with_timezone(&Utc))
                    .or_else(|_| {
                        chrono::NaiveDateTime::parse_from_str(dt, "%Y-%m-%d %H:%M:%S")
                            .map(|ndt| ndt.and_utc())
                    })
                    .ok()
            })
    }
    
    /// 利用停止期間中かどうかを判定
    pub fn is_in_suspension_period(&self) -> bool {
        let now = Utc::now();
        
        if let (Some(start_str), Some(end_str)) = (&self.end_start_datetime, &self.end_end_datetime) {
            if let (Some(start), Some(end)) = (
                Self::parse_datetime(&Some(start_str.clone())),
                Self::parse_datetime(&Some(end_str.clone()))
            ) {
                return now >= start && now <= end;
            }
        }
        
        false
    }
}

/// 駐車場検索用の拡張情報を含むモデル
/// 
/// 検索結果にUI表示用の計算値（距離、お気に入り状態、評価など）を含む
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ParkingLotSearchResult {
    /// 駐車場基本情報
    #[serde(flatten)]
    pub parking_lot: TParkingLotsModel,
    
    /// お気に入りフラグ（ユーザー固有）
    pub is_favorite: bool,
    
    /// 評価スコア（計算値）
    pub rating: Option<f64>,
    
    /// 現在地からの距離（km、計算値）
    pub distance: Option<f64>,
    
    /// 時間料金（円、UI表示用）
    pub hourly_rate: Option<i32>,
}

impl ParkingLotSearchResult {
    /// 駐車場基本情報から検索結果を作成
    pub fn from_parking_lot(
        parking_lot: TParkingLotsModel,
        is_favorite: bool,
        rating: Option<f64>,
        distance: Option<f64>,
        hourly_rate: Option<i32>,
    ) -> Self {
        Self {
            parking_lot,
            is_favorite,
            rating,
            distance,
            hourly_rate,
        }
    }
    
    /// 駐車場IDを取得
    pub fn parking_lot_id(&self) -> &str {
        &self.parking_lot.parking_lot_id
    }
    
    /// 駐車場名を取得
    pub fn parking_lot_name(&self) -> &str {
        &self.parking_lot.parking_lot_name
    }
    
    /// 完全な住所を取得
    pub fn full_address(&self) -> String {
        self.parking_lot.get_full_address()
    }
}

/// 駐車場レスポンス用構造体
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ParkingLotResponse {
    pub parking_lot_id: String,
    pub owner_id: String,
    pub parking_lot_name: String,
    pub postal_code: String,
    pub prefecture: String,
    pub city: String,
    pub address_detail: String,
    pub phone_number: String,
    pub capacity: i32,
    pub available_capacity: Option<i32>,
    pub rental_type: Option<String>,
    pub charge: String,
    pub features_tip: Option<String>,
    pub length_limit: Option<i32>,
    pub width_limit: Option<i32>,
    pub height_limit: Option<i32>,
    pub weight_limit: Option<i32>,
    pub car_height_limit: Option<String>,
    pub tire_width_limit: Option<String>,
    pub vehicle_type: Option<String>,
    pub nearest_station: Option<String>,
    pub status: String,
    pub start_date: String,
    pub end_date: Option<String>,
    pub end_start_datetime: Option<String>,
    pub end_end_datetime: Option<String>,
    pub end_reason: Option<String>,
    pub end_reason_detail: Option<String>,
    pub notes: Option<String>,
    pub created_datetime: String,
    pub updated_datetime: String,
}

impl From<TParkingLotsModel> for ParkingLotResponse {
    fn from(model: TParkingLotsModel) -> Self {
        Self {
            parking_lot_id: model.parking_lot_id,
            owner_id: model.owner_id,
            parking_lot_name: model.parking_lot_name,
            postal_code: model.postal_code,
            prefecture: model.prefecture,
            city: model.city,
            address_detail: model.address_detail,
            phone_number: model.phone_number,
            capacity: model.capacity,
            available_capacity: model.available_capacity,
            rental_type: model.rental_type,
            charge: model.charge,
            features_tip: model.features_tip,
            length_limit: model.length_limit,
            width_limit: model.width_limit,
            height_limit: model.height_limit,
            weight_limit: model.weight_limit,
            car_height_limit: model.car_height_limit,
            tire_width_limit: model.tire_width_limit,
            vehicle_type: model.vehicle_type,
            nearest_station: model.nearest_station,
            status: model.status,
            start_date: model.start_date.unwrap_or_default(),
            end_date: model.end_date,
            end_start_datetime: model.end_start_datetime,
            end_end_datetime: model.end_end_datetime,
            end_reason: model.end_reason,
            end_reason_detail: model.end_reason_detail,
            notes: model.notes,
            created_datetime: model.created_datetime.unwrap_or_default(),
            updated_datetime: model.updated_datetime.unwrap_or_default(),
        }
    }
}
