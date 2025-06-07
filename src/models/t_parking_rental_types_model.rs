// src/models/t_parking_rental_types_model.rs
//! 駐車場貸出タイプテーブル（t_parking_rental_types）のモデル
//! 
//! 駐車場の貸出タイプ（時間単位または日間単位）とその値（例: 15分、1日）を
//! 管理するモデル。同一駐車場IDに対し貸出タイプは一意。

use serde::{Deserialize, Serialize};

/// 駐車場貸出タイプモデル（t_parking_rental_typesテーブル）
/// 
/// 駐車場の貸出タイプとその具体的な値を格納するモデル。
/// 例：時間単位 - 15分、30分、1時間 / 日間単位 - 1日、2日、1週間、1ヶ月
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct TParkingRentalTypesModel {
    /// 論理名: 貸出タイプID
    /// 物理名: rental_type_id（UUID v4）
    pub rental_type_id: String,
    
    /// 論理名: 駐車場ID
    /// 物理名: parking_lot_id（形式: P-XXXXXX）
    pub parking_lot_id: String,
    
    /// 論理名: 貸出タイプ
    /// 物理名: rental_type（時間単位または日間単位）
    pub rental_type: String,
    
    /// 論理名: 貸出値
    /// 物理名: rental_value（例: 15分、1日）
    pub rental_value: String,
    
    /// 論理名: 作成日時
    /// 物理名: created_datetime
    pub created_datetime: Option<String>,
    
    /// 論理名: 更新日時
    /// 物理名: updated_datetime
    pub updated_datetime: Option<String>,
}

impl TParkingRentalTypesModel {
    /// 新しい貸出タイプインスタンスを作成
    pub fn new(
        rental_type_id: Option<String>,
        parking_lot_id: Option<String>,
        rental_type: Option<String>,
        rental_value: Option<String>,
        created_datetime: Option<String>,
        updated_datetime: Option<String>,
    ) -> Self {
        Self {
            rental_type_id: rental_type_id.unwrap_or_default(),
            parking_lot_id: parking_lot_id.unwrap_or_default(),
            rental_type: rental_type.unwrap_or_default(),
            rental_value: rental_value.unwrap_or_default(),
            created_datetime,
            updated_datetime,
        }
    }
    
    /// 時間単位の貸出タイプかどうかを判定
    pub fn is_hourly_rental(&self) -> bool {
        self.rental_type == "時間単位"
    }
    
    /// 日間単位の貸出タイプかどうかを判定
    pub fn is_daily_rental(&self) -> bool {
        self.rental_type == "日間単位"
    }
    
    /// 貸出値から分単位の時間を計算（時間単位の場合のみ）
    pub fn get_minutes(&self) -> Option<i32> {
        if !self.is_hourly_rental() {
            return None;
        }
        
        match self.rental_value.as_str() {
            "15分" => Some(15),
            "30分" => Some(30),
            "1時間" => Some(60),
            _ => None,
        }
    }
    
    /// 貸出値から日数を計算（日間単位の場合のみ）
    pub fn get_days(&self) -> Option<i32> {
        if !self.is_daily_rental() {
            return None;
        }
        
        match self.rental_value.as_str() {
            "1日" => Some(1),
            "2日" => Some(2),
            "1週間" => Some(7),
            "1ヶ月" => Some(30), // 概算
            _ => None,
        }
    }
    
    /// 貸出タイプと値の組み合わせが有効かどうかを判定
    pub fn is_valid_combination(&self) -> bool {
        match self.rental_type.as_str() {
            "時間単位" => matches!(
                self.rental_value.as_str(),
                "15分" | "30分" | "1時間"
            ),
            "日間単位" => matches!(
                self.rental_value.as_str(),
                "1日" | "2日" | "1週間" | "1ヶ月"
            ),
            _ => false,
        }
    }
    
    /// 検証メソッド
    pub fn validate(&self) -> Result<(), String> {
        // 駐車場IDの検証
        if self.parking_lot_id.trim().is_empty() {
            return Err("駐車場IDは必須です".to_string());
        }
        
        // 貸出タイプの検証
        if self.rental_type.trim().is_empty() {
            return Err("貸出タイプは必須です".to_string());
        }
        
        if !matches!(self.rental_type.as_str(), "時間単位" | "日間単位") {
            return Err("貸出タイプは「時間単位」または「日間単位」である必要があります".to_string());
        }
        
        // 貸出値の検証
        if self.rental_value.trim().is_empty() {
            return Err("貸出値は必須です".to_string());
        }
        
        // 貸出タイプと値の組み合わせ検証
        if !self.is_valid_combination() {
            return Err(format!(
                "貸出タイプ「{}」に対して貸出値「{}」は無効です",
                self.rental_type, self.rental_value
            ));
        }
        
        Ok(())
    }
}

/// 貸出タイプの作成・更新用リクエストモデル
#[derive(Debug, Deserialize)]
pub struct RentalTypeRequest {
    pub parking_lot_id: String,
    pub rental_type: String,
    pub rental_value: String,
}

impl RentalTypeRequest {
    /// リクエストデータの検証
    pub fn validate(&self) -> Result<(), String> {
        // 駐車場IDの検証
        if self.parking_lot_id.trim().is_empty() {
            return Err("駐車場IDは必須です".to_string());
        }
        
        // 貸出タイプの検証
        if self.rental_type.trim().is_empty() {
            return Err("貸出タイプは必須です".to_string());
        }
        
        if !matches!(self.rental_type.as_str(), "時間単位" | "日間単位") {
            return Err("貸出タイプは「時間単位」または「日間単位」である必要があります".to_string());
        }
        
        // 貸出値の検証
        if self.rental_value.trim().is_empty() {
            return Err("貸出値は必須です".to_string());
        }
        
        // 貸出タイプと値の組み合わせ検証
        let is_valid = match self.rental_type.as_str() {
            "時間単位" => matches!(
                self.rental_value.as_str(),
                "15分" | "30分" | "1時間"
            ),
            "日間単位" => matches!(
                self.rental_value.as_str(),
                "1日" | "2日" | "1週間" | "1ヶ月"
            ),
            _ => false,
        };
        
        if !is_valid {
            return Err(format!(
                "貸出タイプ「{}」に対して貸出値「{}」は無効です",
                self.rental_type, self.rental_value
            ));
        }
        
        Ok(())
    }
}

/// 貸出タイプレスポンス用構造体
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct RentalTypeResponse {
    pub rental_type_id: String,
    pub parking_lot_id: String,
    pub rental_type: String,
    pub rental_value: String,
    pub created_datetime: String,
    pub updated_datetime: String,
}

impl From<TParkingRentalTypesModel> for RentalTypeResponse {
    fn from(model: TParkingRentalTypesModel) -> Self {
        Self {
            rental_type_id: model.rental_type_id,
            parking_lot_id: model.parking_lot_id,
            rental_type: model.rental_type,
            rental_value: model.rental_value,
            created_datetime: model.created_datetime.unwrap_or_default(),
            updated_datetime: model.updated_datetime.unwrap_or_default(),
        }
    }
}

/// 貸出タイプの定数定義
pub struct RentalTypes;

impl RentalTypes {
    pub const HOURLY: &'static str = "時間単位";
    pub const DAILY: &'static str = "日間単位";
}

/// 時間単位の貸出値の定数定義
pub struct HourlyValues;

impl HourlyValues {
    pub const FIFTEEN_MINUTES: &'static str = "15分";
    pub const THIRTY_MINUTES: &'static str = "30分";
    pub const ONE_HOUR: &'static str = "1時間";
    
    /// 全ての有効な時間単位値を取得
    pub fn all_values() -> Vec<&'static str> {
        vec![
            Self::FIFTEEN_MINUTES,
            Self::THIRTY_MINUTES,
            Self::ONE_HOUR,
        ]
    }
}

/// 日間単位の貸出値の定数定義
pub struct DailyValues;

impl DailyValues {
    pub const ONE_DAY: &'static str = "1日";
    pub const TWO_DAYS: &'static str = "2日";
    pub const ONE_WEEK: &'static str = "1週間";
    pub const ONE_MONTH: &'static str = "1ヶ月";
    
    /// 全ての有効な日間単位値を取得
    pub fn all_values() -> Vec<&'static str> {
        vec![
            Self::ONE_DAY,
            Self::TWO_DAYS,
            Self::ONE_WEEK,
            Self::ONE_MONTH,
        ]
    }
}
