use serde::{Deserialize, Serialize};
use crate::utils::validation::validate_not_empty;

/// 駐車場検索モデル（Dartモデルと対応）
/// 駐車場検索機能のリクエスト・レスポンス・データ管理を行う
use crate::models::{
    t_parking_lots_model::ParkingLotResponse,
    t_parking_google_maps_model::GoogleMapsResponse,
    t_parking_rental_types_model::RentalTypeResponse,
    m_parking_vehicle_types_model::VehicleTypeResponse,
    m_parking_features_model::ParkingFeatureResponse,
};

/// 駐車場検索リクエストモデル
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ParkingSearchRequest {
    /// 検索地点の緯度
    pub latitude: Option<f64>,
    /// 検索地点の経度
    pub longitude: Option<f64>,
    /// 検索地点の住所
    pub address: Option<String>,
    /// 検索半径（km）
    pub radius_km: Option<f64>,
    /// 利用予定日時（開始）
    pub usage_start_datetime: Option<chrono::DateTime<chrono::Utc>>,
    /// 利用予定日時（終了）
    pub usage_end_datetime: Option<chrono::DateTime<chrono::Utc>>,
    /// 車両タイプID
    pub vehicle_type_id: Option<String>,
    /// 希望する設備・機能IDリスト
    pub feature_ids: Option<Vec<String>>,
    /// 最低評価値
    pub min_rating: Option<f64>,
    /// 最大料金（時間単位）
    pub max_hourly_rate: Option<i32>,
    /// 最大料金（日単位）
    pub max_daily_rate: Option<i32>,
    /// ソート方式（距離、料金、評価など）
    pub sort_by: Option<String>,
    /// ソート順序（asc, desc）
    pub sort_order: Option<String>,
    /// ページ番号（1から開始）
    pub page: Option<i32>,
    /// 1ページあたりの件数
    pub page_size: Option<i32>,
    /// お気に入りのみ表示するか
    pub favorites_only: Option<bool>,
    /// ユーザーID（お気に入り検索用）
    pub user_id: Option<String>,
}

/// 駐車場検索レスポンスモデル
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ParkingSearchResponse {
    /// 検索結果の駐車場リスト
    pub parking_lots: Vec<ParkingSearchResult>,
    /// ページネーション情報
    pub pagination: PaginationInfo,
    /// 検索条件情報
    pub search_info: SearchInfo,
    /// 検索統計情報
    pub search_stats: SearchStats,
}

/// 駐車場検索結果の個別アイテム
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ParkingSearchResult {
    /// 駐車場基本情報
    pub parking_lot: ParkingLotResponse,
    /// 位置情報・地図情報
    pub location_info: Option<GoogleMapsResponse>,
    /// 利用可能なレンタルタイプリスト
    pub rental_types: Vec<RentalTypeResponse>,
    /// 対応車両タイプリスト
    pub vehicle_types: Vec<VehicleTypeResponse>,
    /// 設備・機能リスト
    pub features: Vec<ParkingFeatureResponse>,
    /// 距離情報（検索地点からの距離）
    pub distance_info: Option<DistanceInfo>,
    /// 利用可能性情報
    pub availability_info: AvailabilityInfo,
    /// 料金情報
    pub pricing_info: PricingInfo,
    /// お気に入り情報
    pub favorite_info: Option<FavoriteInfo>,
    /// 評価情報
    pub rating_info: Option<RatingInfo>,
}

/// ページネーション情報
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PaginationInfo {
    /// 現在のページ番号
    pub current_page: i32,
    /// 1ページあたりの件数
    pub page_size: i32,
    /// 総件数
    pub total_count: i64,
    /// 総ページ数
    pub total_pages: i32,
    /// 前のページがあるか
    pub has_previous: bool,
    /// 次のページがあるか
    pub has_next: bool,
}

/// 検索条件情報
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SearchInfo {
    /// 検索地点情報
    pub search_location: Option<SearchLocation>,
    /// 検索半径
    pub search_radius_km: Option<f64>,
    /// 検索日時範囲
    pub search_period: Option<SearchPeriod>,
    /// 適用されたフィルター
    pub applied_filters: Vec<AppliedFilter>,
    /// ソート情報
    pub sort_info: SortInfo,
}

/// 検索地点情報
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SearchLocation {
    /// 緯度
    pub latitude: f64,
    /// 経度
    pub longitude: f64,
    /// 住所
    pub address: Option<String>,
    /// 地点名称
    pub location_name: Option<String>,
}

/// 検索期間情報
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SearchPeriod {
    /// 利用開始日時
    pub start_datetime: chrono::DateTime<chrono::Utc>,
    /// 利用終了日時
    pub end_datetime: chrono::DateTime<chrono::Utc>,
    /// 利用時間（分）
    pub duration_minutes: i32,
}

/// 適用されたフィルター情報
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AppliedFilter {
    /// フィルター名
    pub filter_name: String,
    /// フィルター値
    pub filter_value: String,
    /// フィルター表示名
    pub display_name: String,
}

/// ソート情報
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SortInfo {
    /// ソート項目
    pub sort_by: String,
    /// ソート順序
    pub sort_order: String,
    /// ソート項目表示名
    pub sort_display_name: String,
}

/// 検索統計情報
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SearchStats {
    /// 検索実行時間（ミリ秒）
    pub execution_time_ms: u64,
    /// 検索半径内の総駐車場数
    pub total_lots_in_radius: i64,
    /// フィルター適用後の駐車場数
    pub filtered_lots_count: i64,
    /// 利用可能な駐車場数
    pub available_lots_count: i64,
}

/// 距離情報
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DistanceInfo {
    /// 直線距離（km）
    pub straight_distance_km: f64,
    /// 直線距離（m）
    pub straight_distance_m: i32,
    /// 表示用距離文字列
    pub distance_display: String,
    /// 徒歩時間（分）推定
    pub walking_time_minutes: Option<i32>,
    /// 車での時間（分）推定
    pub driving_time_minutes: Option<i32>,
}

/// 利用可能性情報
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AvailabilityInfo {
    /// 指定期間中に利用可能か
    pub is_available: bool,
    /// 利用可能性の詳細理由
    pub availability_reason: String,
    /// 営業時間内かどうか
    pub is_within_operating_hours: bool,
    /// 予約の必要性
    pub requires_reservation: bool,
    /// 空き台数情報（リアルタイム取得可能な場合）
    pub available_spaces: Option<i32>,
    /// 総台数
    pub total_spaces: Option<i32>,
}

/// 料金情報
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PricingInfo {
    /// 指定期間の推定料金
    pub estimated_cost: Option<i32>,
    /// 最安値のレンタルタイプ
    pub cheapest_rental_type: Option<RentalTypeResponse>,
    /// 時間料金範囲
    pub hourly_rate_range: Option<PriceRange>,
    /// 日料金範囲
    pub daily_rate_range: Option<PriceRange>,
    /// 料金表示文字列
    pub pricing_display: String,
}

/// 料金範囲
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PriceRange {
    /// 最低料金
    pub min_price: i32,
    /// 最高料金
    pub max_price: i32,
    /// 通貨単位
    pub currency: String,
}

/// お気に入り情報
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FavoriteInfo {
    /// お気に入りに登録されているか
    pub is_favorite: bool,
    /// お気に入り登録日時
    pub favorite_added_at: Option<chrono::DateTime<chrono::Utc>>,
    /// お気に入りメモ
    pub favorite_memo: Option<String>,
}

/// 評価情報
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RatingInfo {
    /// 平均評価値
    pub average_rating: f64,
    /// 評価件数
    pub rating_count: i32,
    /// 評価分布
    pub rating_distribution: Option<Vec<RatingDistribution>>,
    /// 最新のレビュー
    pub latest_reviews: Option<Vec<ReviewSummary>>,
}

/// 評価分布
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RatingDistribution {
    /// 星の数（1-5）
    pub star_count: i32,
    /// その星数の件数
    pub count: i32,
    /// 全体に占める割合
    pub percentage: f64,
}

/// レビュー要約
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ReviewSummary {
    /// レビューID
    pub review_id: String,
    /// 評価値
    pub rating: i32,
    /// レビューコメント（抜粋）
    pub comment_excerpt: Option<String>,
    /// レビュー投稿日時
    pub review_date: chrono::DateTime<chrono::Utc>,
    /// レビュー投稿者名（匿名化）
    pub reviewer_name: Option<String>,
}

/// お気に入り操作リクエスト
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FavoriteOperationRequest {
    /// ユーザーID
    pub user_id: String,
    /// 駐車場ID
    pub parking_lot_id: String,
    /// 操作タイプ（add, remove）
    pub operation: String,
    /// お気に入りメモ（追加時のみ）
    pub memo: Option<String>,
}

/// お気に入り操作レスポンス
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FavoriteOperationResponse {
    /// 操作成功フラグ
    pub success: bool,
    /// 現在のお気に入り状態
    pub is_favorite: bool,
    /// メッセージ
    pub message: String,
    /// お気に入り総数
    pub total_favorites: i32,
}

impl ParkingSearchRequest {
    /// 検索リクエストのバリデーション
    pub fn validate(&self) -> Result<(), String> {
        // 位置情報または住所のいずれかは必須
        if self.latitude.is_none() && self.longitude.is_none() && self.address.is_none() {
            return Err("検索地点の指定が必要です（緯度経度または住所）".to_string());
        }

        // 緯度経度が指定されている場合の妥当性チェック
        if let (Some(lat), Some(lng)) = (self.latitude, self.longitude) {
            if lat < -90.0 || lat > 90.0 {
                return Err("緯度は-90.0から90.0の範囲で指定してください".to_string());
            }
            if lng < -180.0 || lng > 180.0 {
                return Err("経度は-180.0から180.0の範囲で指定してください".to_string());
            }
        }

        // 検索半径の妥当性チェック
        if let Some(radius) = self.radius_km {
            if radius <= 0.0 || radius > 100.0 {
                return Err("検索半径は0.1km以上100km以下で指定してください".to_string());
            }
        }

        // 利用日時の妥当性チェック
        if let (Some(start), Some(end)) = (self.usage_start_datetime, self.usage_end_datetime) {
            if start >= end {
                return Err("利用終了日時は開始日時より後にしてください".to_string());
            }
            
            let now = chrono::Utc::now();
            if start < now {
                return Err("利用開始日時は現在時刻より後にしてください".to_string());
            }
        }

        // 評価値の妥当性チェック
        if let Some(rating) = self.min_rating {
            if rating < 0.0 || rating > 5.0 {
                return Err("評価値は0.0から5.0の範囲で指定してください".to_string());
            }
        }

        // ページング情報の妥当性チェック
        if let Some(page) = self.page {
            if page < 1 {
                return Err("ページ番号は1以上で指定してください".to_string());
            }
        }

        if let Some(page_size) = self.page_size {
            if page_size < 1 || page_size > 100 {
                return Err("ページサイズは1以上100以下で指定してください".to_string());
            }
        }

        Ok(())
    }

    /// デフォルト値を設定
    pub fn set_defaults(&mut self) {
        if self.radius_km.is_none() {
            self.radius_km = Some(5.0); // デフォルト5km
        }
        if self.page.is_none() {
            self.page = Some(1);
        }
        if self.page_size.is_none() {
            self.page_size = Some(20);
        }
        if self.sort_by.is_none() {
            self.sort_by = Some("distance".to_string()); // デフォルトは距離順
        }
        if self.sort_order.is_none() {
            self.sort_order = Some("asc".to_string());
        }
    }

    /// 検索期間の長さを分単位で取得
    pub fn get_duration_minutes(&self) -> Option<i32> {
        if let (Some(start), Some(end)) = (self.usage_start_datetime, self.usage_end_datetime) {
            let duration = end.signed_duration_since(start);
            Some(duration.num_minutes() as i32)
        } else {
            None
        }
    }

    /// お気に入り検索かどうか
    pub fn is_favorites_search(&self) -> bool {
        self.favorites_only.unwrap_or(false) && self.user_id.is_some()
    }

    /// フィルターが適用されているかチェック
    pub fn has_filters(&self) -> bool {
        self.vehicle_type_id.is_some() ||
        (self.feature_ids.is_some() && !self.feature_ids.as_ref().unwrap().is_empty()) ||
        self.min_rating.is_some() ||
        self.max_hourly_rate.is_some() ||
        self.max_daily_rate.is_some()
    }
}

impl PaginationInfo {
    /// ページネーション情報を作成
    pub fn new(current_page: i32, page_size: i32, total_count: i64) -> Self {
        let total_pages = ((total_count as f64) / (page_size as f64)).ceil() as i32;
        let has_previous = current_page > 1;
        let has_next = current_page < total_pages;

        Self {
            current_page,
            page_size,
            total_count,
            total_pages,
            has_previous,
            has_next,
        }
    }
}

impl DistanceInfo {
    /// 距離情報を作成
    pub fn new(distance_km: f64) -> Self {
        let distance_m = (distance_km * 1000.0) as i32;
        let distance_display = if distance_km < 1.0 {
            format!("{}m", distance_m)
        } else {
            format!("{:.1}km", distance_km)
        };

        // 徒歩時間推定（時速4km）
        let walking_time_minutes = Some((distance_km / 4.0 * 60.0) as i32);
        // 車での時間推定（時速30km、市街地想定）
        let driving_time_minutes = Some((distance_km / 30.0 * 60.0) as i32);

        Self {
            straight_distance_km: distance_km,
            straight_distance_m: distance_m,
            distance_display,
            walking_time_minutes,
            driving_time_minutes,
        }
    }
}

impl FavoriteOperationRequest {
    /// お気に入り操作リクエストのバリデーション
    pub fn validate(&self) -> Result<(), String> {
        validate_not_empty(&self.user_id, "ユーザーID")
            .map_err(|e| e.to_string())?;
        validate_not_empty(&self.parking_lot_id, "駐車場ID")
            .map_err(|e| e.to_string())?;
        
        if self.operation != "add" && self.operation != "remove" {
            return Err("操作タイプはaddまたはremoveで指定してください".to_string());
        }

        Ok(())
    }
}
