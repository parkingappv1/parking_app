use chrono::{DateTime, NaiveDate, Utc};
use regex::Regex;
use serde::{Deserialize, Serialize};
use sqlx::FromRow;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ParkingLotRequest {
    pub owner_id: String,
    pub parking_lot_name: String,
    pub postal_code: String,
    pub prefecture: String,
    pub city: String,
    pub address_detail: String,
    pub phone_number: String,
    pub capacity: i32,
    pub available_capacity: Option<i32>,
    pub rental_type: String,
    pub charge: String,
    pub features_tip: Option<String>,
    pub nearest_station: Option<String>,
    pub latitude: String,
    pub longitude: String,
    pub status: String,
    pub start_date: NaiveDate,
    pub end_date: Option<NaiveDate>,
    pub end_start_datetime: Option<DateTime<Utc>>,
    pub end_end_datetime: Option<DateTime<Utc>>,
    pub end_reason: Option<String>,
    pub end_reason_detail: Option<String>,
    pub notes: Option<String>,
    pub created_datetime: Option<DateTime<Utc>>,
    pub updated_datetime: Option<DateTime<Utc>>,

    pub limits: Option<ParkingLimitRequest>,
    pub vehicle_types: Option<Vec<ParkingVehicleTypeRequest>>,
    pub images: Option<Vec<ParkingImageRequest>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ParkingLimitRequest {
    pub length_limit: Option<i32>,
    pub width_limit: Option<i32>,
    pub height_limit: Option<i32>,
    pub weight_limit: Option<i32>,
    pub car_height_limit: Option<String>,
    pub tire_width_limit: Option<String>,
    pub car_bottom_limit: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ParkingVehicleTypeRequest {
    pub vehicle_type: String,
    pub capacity: i32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ParkingImageRequest {
    pub parking_lot_id: String,
    pub image_url: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
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
    pub rental_type: String,
    pub charge: String,
    pub features_tip: Option<String>,
    pub nearest_station: Option<String>,
    pub latitude: String,
    pub longitude: String,
    pub status: String,
    pub start_date: NaiveDate,
    pub end_date: Option<NaiveDate>,
    pub end_start_datetime: Option<DateTime<Utc>>,
    pub end_end_datetime: Option<DateTime<Utc>>,
    pub end_reason: Option<String>,
    pub end_reason_detail: Option<String>,
    pub notes: Option<String>,
    pub created_datetime: Option<DateTime<Utc>>,
    pub updated_datetime: Option<DateTime<Utc>>,

    pub limits: Option<ParkingLimitModel>,
    pub vehicle_types: Option<Vec<ParkingVehicleTypeModel>>,
    pub images: Option<Vec<ParkingImageModel>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ParkingLimitModel {
    pub parking_lot_id: String,
    pub length_limit: Option<i32>,
    pub width_limit: Option<i32>,
    pub height_limit: Option<i32>,
    pub weight_limit: Option<i32>,
    pub car_height_limit: Option<String>,
    pub tire_width_limit: Option<String>,
    pub car_bottom_limit: Option<String>,
    pub created_datetime: Option<DateTime<Utc>>,
    pub updated_datetime: Option<DateTime<Utc>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ParkingVehicleTypeModel {
    pub id: i32,
    pub parking_lot_id: String,
    pub vehicle_type: String,
    pub capacity: i32,
    pub created_datetime: Option<DateTime<Utc>>,
    pub updated_datetime: Option<DateTime<Utc>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ParkingImageModel {
    pub id: i32,
    pub parking_lot_id: String,
    pub image_url: String,
    pub created_datetime: Option<DateTime<Utc>>,
    pub updated_datetime: Option<DateTime<Utc>>,
}

#[derive(Debug, Clone, FromRow,Serialize)]
pub struct ParkingLotRow {
    pub parking_lot_id: String,
    pub parking_lot_name: String,
}


impl ParkingLotRequest {
    /// 駐車場登録リクエストの検証処理（バリデーション）
    pub fn validate(&self) -> Result<(), String> {
        // 駐車場名 - VARCHAR(100)
        if self.parking_lot_name.trim().is_empty() {
            return Err("駐車場名は必須です".to_string());
        }
        if self.parking_lot_name.len() > 100 {
            return Err("駐車場名は100文字以内で入力してください".to_string());
        }

        // 郵便番号 - VARCHAR(10)
        if self.postal_code.trim().is_empty() {
            return Err("郵便番号は必須です".to_string());
        }
        if self.postal_code.len() > 10 {
            return Err("郵便番号は10文字以内で入力してください".to_string());
        }
        if !self.is_valid_postal_code(&self.postal_code) {
            return Err("郵便番号は正しい形式（例: 123-4567）で入力してください".to_string());
        }

        // 都道府県 - VARCHAR(50)
        if self.prefecture.trim().is_empty() {
            return Err("都道府県は必須です".to_string());
        }
        if self.prefecture.len() > 50 {
            return Err("都道府県は50文字以内で入力してください".to_string());
        }

        // 市区町村 - VARCHAR(100)
        if self.city.trim().is_empty() {
            return Err("市区町村は必須です".to_string());
        }
        if self.city.len() > 100 {
            return Err("市区町村は100文字以内で入力してください".to_string());
        }

        // 住所詳細 - TEXT (1000 文字制限)
        if self.address_detail.trim().is_empty() {
            return Err("住所詳細は必須です".to_string());
        }
        if self.address_detail.len() > 1000 {
            return Err("住所詳細は1000文字以内で入力してください".to_string());
        }

        // 電話番号 - VARCHAR(50)
        if self.phone_number.trim().is_empty() {
            return Err("電話番号は必須です".to_string());
        }
        if self.phone_number.len() > 50 {
            return Err("電話番号は50文字以内で入力してください".to_string());
        }

        // 台数 - INTEGER
        if self.capacity <= 0 {
            return Err("駐車可能台数は1以上で指定してください".to_string());
        }

        // 金額（charge） - 半角数値、桁数制限等
        if self.charge.trim().is_empty() {
            return Err("料金は必須です".to_string());
        }
        if !self.is_valid_number(&self.charge) {
            return Err("料金は半角数字で入力してください".to_string());
        }

        // 駐車場の特徴（任意） - VARCHAR(500)
        if self.latitude.trim().is_empty() {
            return Err("駐車場の緯度を入力してください".to_string());
        }
        // 駐車場の特徴（任意） - VARCHAR(500)
        if self.longitude.trim().is_empty() {
            return Err("駐車場の経度を入力してください".to_string());
        }

        // その他必要に応じたフィールド追加バリデーション...

        Ok(())
    }

    /// 郵便番号形式（例：123-4567）かどうか判定
    fn is_valid_postal_code(&self, code: &str) -> bool {
        let regex = Regex::new(r"^\d{3}-\d{4}$").unwrap();
        regex.is_match(code)
    }

    /// 半角数字かどうかを検証（料金、制限系等）
    fn is_valid_number(&self, value: &str) -> bool {
        let regex = Regex::new(r"^\d+$").unwrap();
        regex.is_match(value)
    }
}
