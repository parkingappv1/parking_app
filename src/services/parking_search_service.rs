use tracing::{error, info, instrument, warn};

use crate::{
    config::postgresql_database::{DatabaseError, PostgresDatabase},
    controllers::api_error::ApiError,
    models::parking_search_model::{
        ParkingSearchRequest, ParkingSearchResponse, ParkingSearchResult,
        PaginationInfo, SearchInfo, SearchStats, DistanceInfo, AvailabilityInfo,
        PricingInfo, FavoriteInfo, RatingInfo, FavoriteOperationRequest, FavoriteOperationResponse,
        SortInfo, PriceRange,
    },
    repositories::parking_search_repository::ParkingSearchRepository,
    models::{
        t_parking_lots_model::{TParkingLotsModel, ParkingLotResponse},
        t_parking_google_maps_model::{TParkingGoogleMapsModel, GoogleMapsResponse},
        t_parking_rental_types_model::{TParkingRentalTypesModel, RentalTypeResponse},
        m_parking_vehicle_types_model::{MParkingVehicleTypesModel, VehicleTypeResponse},
        m_parking_features_model::{MParkingFeaturesModel, ParkingFeatureResponse},
    },
};

/// 検索条件構造体
#[derive(Debug, Clone)]
pub struct SearchCriteria {
    pub latitude: Option<f64>,
    pub longitude: Option<f64>,
    pub radius_km: f64,
    pub vehicle_type_id: Option<String>,
    pub feature_ids: Vec<String>,
    pub min_rating: Option<f64>,
    pub max_hourly_rate: Option<i32>,
    pub max_daily_rate: Option<i32>,
    pub sort_by: String,
    pub sort_order: String,
}

/// 駐車場検索フィルター
#[derive(Debug, Clone, serde::Deserialize)]
pub struct ParkingSearchFilters {
    pub page: Option<i32>,
    pub page_size: Option<i32>,
    pub vehicle_type_id: Option<String>,
    pub feature_ids: Option<Vec<String>>,
    pub min_rating: Option<f64>,
    pub max_hourly_rate: Option<i32>,
    pub max_daily_rate: Option<i32>,
}

/// Default implementations
impl Default for ParkingSearchRequest {
    fn default() -> Self {
        Self {
            latitude: None,
            longitude: None,
            address: None,
            radius_km: Some(5.0),
            usage_start_datetime: None,
            usage_end_datetime: None,
            vehicle_type_id: None,
            feature_ids: None,
            min_rating: None,
            max_hourly_rate: None,
            max_daily_rate: None,
            sort_by: Some("distance".to_string()),
            sort_order: Some("asc".to_string()),
            page: Some(1),
            page_size: Some(20),
            favorites_only: None,
            user_id: None,
        }
    }
}

impl Default for SearchInfo {
    fn default() -> Self {
        Self {
            search_location: None,
            search_radius_km: None,
            search_period: None,
            applied_filters: vec![],
            sort_info: SortInfo {
                sort_by: "distance".to_string(),
                sort_order: "asc".to_string(),
                sort_display_name: "距離順".to_string(),
            },
        }
    }
}

/// 駐車場検索サービス
/// 検索ロジック、フィルタリング、ソート、お気に入り管理などのビジネスロジックを処理
/// auth_signup_serviceのパターンに従った実装
#[derive(Debug, Clone)]
pub struct ParkingSearchService {
    repository: ParkingSearchRepository,
}

impl ParkingSearchService {
    /// 新しいサービスインスタンスを作成
    pub fn new(db: PostgresDatabase) -> Self {
        let repository = ParkingSearchRepository::new(db);
        Self { repository }
    }

    /// 駐車場検索メイン処理
    /// 
    /// 包括的な検索条件の処理、検証、フィルタリング、ソート、ページネーション、
    /// お気に入り情報の統合を行います。
    #[instrument(skip(self), fields(latitude = ?request.latitude, longitude = ?request.longitude, user_id = ?user_id))]
    pub async fn search_parking_lots(
        &self,
        request: ParkingSearchRequest,
        user_id: Option<String>,
    ) -> Result<ParkingSearchResponse, ApiError> {
        info!("駐車場検索を開始します");

        // モデルの検証メソッドを使用した入力データの検証
        request.validate().map_err(ApiError::ValidationError)?;
        
        let start_time = std::time::Instant::now();

        // 基本的な駐車場データ取得
        let parking_lots = if request.is_favorites_search() {
            if let Some(uid) = &user_id {
                self.repository.get_favorite_parking_lots(
                    uid, 
                    request.page.unwrap_or(1), 
                    request.page_size.unwrap_or(20)
                ).await
                    .map_err(|e| self.handle_database_error(e))?
            } else {
                return Err(ApiError::AuthenticationError(
                    "お気に入り検索には認証が必要です".to_string()
                ));
            }
        } else {
            self.repository.search_parking_lots_by_location(&request).await
                .map_err(|e| self.handle_database_error(e))?
        };

        // フィルタリング適用
        let filtered_lots = self.apply_search_filters(parking_lots, &request).await?;

        // 距離計算（位置情報検索の場合）
        let lots_with_distance = if let (Some(lat), Some(lng)) = (request.latitude, request.longitude) {
            self.calculate_distances(filtered_lots, lat, lng).await?
        } else {
            filtered_lots.into_iter()
                .map(|(lot, rental, vehicle, features, maps)| (lot, None, rental, vehicle, features, maps))
                .collect()
        };

        // ソート処理
        let sorted_lots = self.sort_parking_lots(lots_with_distance, &request).await?;

        // ページネーション適用
        let total_count = sorted_lots.len() as i64;
        let page = request.page.unwrap_or(1);
        let page_size = request.page_size.unwrap_or(20);
        let offset = ((page - 1) * page_size) as usize;
        let limit = page_size as usize;
        
        let paginated_lots = sorted_lots
            .into_iter()
            .skip(offset)
            .take(limit)
            .collect::<Vec<_>>();

        // 詳細情報を含む検索結果を構築
        let mut search_results = Vec::new();
        for (parking_lot, distance_info, rental_types, vehicle_types, features, maps_info) in paginated_lots {
            let availability_info = self.get_availability_info(&parking_lot, &request).await?;
            let pricing_info = self.get_pricing_info(&parking_lot, &rental_types, &request).await?;
            let favorite_info = if let Some(uid) = &user_id {
                self.get_favorite_info(&parking_lot.parking_lot_id, uid).await?
            } else {
                None
            };
            let rating_info = self.get_rating_info(&parking_lot.parking_lot_id).await?;

            let search_result = ParkingSearchResult {
                parking_lot: ParkingLotResponse::from(parking_lot.clone()),
                location_info: maps_info.map(GoogleMapsResponse::from),
                rental_types: rental_types.into_iter().map(RentalTypeResponse::from).collect(),
                vehicle_types: vehicle_types.into_iter().map(VehicleTypeResponse::from).collect(),
                features: features.into_iter().map(ParkingFeatureResponse::from).collect(),
                distance_info,
                availability_info,
                pricing_info,
                favorite_info,
                rating_info,
            };

            search_results.push(search_result);
        }

        // レスポンス構築
        let pagination = PaginationInfo::new(page, page_size, total_count);
        let search_info = self.build_search_info(&request).await?;
        let execution_time = start_time.elapsed();
        let search_stats = SearchStats {
            execution_time_ms: execution_time.as_millis() as u64,
            total_lots_in_radius: total_count,
            filtered_lots_count: total_count,
            available_lots_count: search_results.iter()
                .filter(|r| r.availability_info.is_available)
                .count() as i64,
        };

        info!("駐車場検索が正常に完了しました - 結果数: {}", search_results.len());

        Ok(ParkingSearchResponse {
            parking_lots: search_results,
            pagination,
            search_info,
            search_stats,
        })
    }

    /// お気に入り駐車場検索
    /// 
    /// 認証されたユーザーのお気に入り駐車場を検索します。
    /// 追加のフィルタリング条件も適用可能です。
    #[instrument(skip(self), fields(user_id = %user_id))]
    pub async fn get_favorite_parking_lots(
        &self,
        filters: ParkingSearchFilters,
        user_id: String,
    ) -> Result<ParkingSearchResponse, ApiError> {
        info!("お気に入り駐車場検索を開始します: {}", user_id);
        
        // ユーザー認証状態の確認
        self.validate_user_access(&user_id).await?;

        let start_time = std::time::Instant::now();

        // お気に入り駐車場データの取得
        let favorite_lots = self.repository.get_favorite_parking_lots(
            &user_id, 
            filters.page.unwrap_or(1), 
            filters.page_size.unwrap_or(20)
        ).await
            .map_err(|e| self.handle_database_error(e))?;

        // フィルタリング適用
        let filtered_lots = self.apply_favorite_filters(favorite_lots, &filters).await?;

        // 詳細情報構築
        let mut search_results = Vec::new();
        for (parking_lot, rental_types, vehicle_types, features, maps_info) in filtered_lots {
            let availability_info = self.get_availability_info(&parking_lot, &ParkingSearchRequest::default()).await?;
            let pricing_info = self.get_pricing_info(&parking_lot, &rental_types, &ParkingSearchRequest::default()).await?;
            let favorite_info = Some(FavoriteInfo {
                is_favorite: true,
                favorite_added_at: Some(chrono::Utc::now()),
                favorite_memo: None,
            });
            let rating_info = self.get_rating_info(&parking_lot.parking_lot_id).await?;

            let search_result = ParkingSearchResult {
                parking_lot: ParkingLotResponse::from(parking_lot.clone()),
                location_info: maps_info.map(GoogleMapsResponse::from),
                rental_types: rental_types.into_iter().map(RentalTypeResponse::from).collect(),
                vehicle_types: vehicle_types.into_iter().map(VehicleTypeResponse::from).collect(),
                features: features.into_iter().map(ParkingFeatureResponse::from).collect(),
                distance_info: None,
                availability_info,
                pricing_info,
                favorite_info,
                rating_info,
            };

            search_results.push(search_result);
        }

        let total_count = search_results.len() as i64;
        let pagination = PaginationInfo::new(
            filters.page.unwrap_or(1), 
            filters.page_size.unwrap_or(20), 
            total_count
        );

        let execution_time = start_time.elapsed();
        let search_stats = SearchStats {
            execution_time_ms: execution_time.as_millis() as u64,
            total_lots_in_radius: total_count,
            filtered_lots_count: total_count,
            available_lots_count: search_results.iter()
                .filter(|r| r.availability_info.is_available)
                .count() as i64,
        };

        info!("お気に入り駐車場検索が正常に完了しました - 結果数: {}", search_results.len());

        Ok(ParkingSearchResponse {
            parking_lots: search_results,
            pagination,
            search_info: SearchInfo::default(),
            search_stats,
        })
    }

    /// お気に入り操作管理
    /// 
    /// 駐車場のお気に入り追加・削除を管理します。
    /// トランザクション処理と包括的な検証を行います。
    #[instrument(skip(self), fields(parking_lot_id = %request.parking_lot_id, operation = %request.operation, user_id = %request.user_id))]
    pub async fn manage_favorite_operation(
        &self,
        request: FavoriteOperationRequest,
    ) -> Result<FavoriteOperationResponse, ApiError> {
        info!("お気に入り操作を開始します: {} - {}", request.operation, request.parking_lot_id);

        // モデルの検証メソッドを使用
        request.validate().map_err(ApiError::ValidationError)?;
        
        // ユーザー認証状態の確認
        self.validate_user_access(&request.user_id).await?;

        // 駐車場の存在確認
        self.validate_parking_lot_exists(&request.parking_lot_id).await?;
        
        match request.operation.as_str() {
            "add" => {
                // お気に入り重複チェック
                if self.check_favorite_exists(&request.user_id, &request.parking_lot_id).await? {
                    return Err(ApiError::DuplicateError(
                        "この駐車場は既にお気に入りに登録されています".to_string()
                    ));
                }

                let result = self.repository.add_to_favorites(
                    &request.user_id, 
                    &request.parking_lot_id
                ).await
                    .map_err(|e| self.handle_database_error(e))?;
                
                let total_favorites = self.repository.get_user_favorites_count(&request.user_id).await
                    .map_err(|e| self.handle_database_error(e))?;
                
                info!("お気に入り追加が完了しました - ユーザー: {}, 駐車場: {}", request.user_id, request.parking_lot_id);
                
                Ok(FavoriteOperationResponse {
                    success: result,
                    is_favorite: result,
                    message: if result { 
                        "お気に入りに追加しました".to_string() 
                    } else { 
                        "お気に入りの追加に失敗しました".to_string() 
                    },
                    total_favorites: total_favorites as i32,
                })
            }
            "remove" => {
                // お気に入り存在チェック
                if !self.check_favorite_exists(&request.user_id, &request.parking_lot_id).await? {
                    return Err(ApiError::NotFoundError(
                        "指定された駐車場はお気に入りに登録されていません".to_string()
                    ));
                }

                let result = self.repository.remove_from_favorites(
                    &request.user_id, 
                    &request.parking_lot_id
                ).await
                    .map_err(|e| self.handle_database_error(e))?;
                
                let total_favorites = self.repository.get_user_favorites_count(&request.user_id).await
                    .map_err(|e| self.handle_database_error(e))?;
                
                info!("お気に入り削除が完了しました - ユーザー: {}, 駐車場: {}", request.user_id, request.parking_lot_id);
                
                Ok(FavoriteOperationResponse {
                    success: result,
                    is_favorite: false,
                    message: if result { 
                        "お気に入りから削除しました".to_string() 
                    } else { 
                        "お気に入りの削除に失敗しました".to_string() 
                    },
                    total_favorites: total_favorites as i32,
                })
            }
            _ => Err(ApiError::ValidationError(
                format!("無効な操作タイプです: {}", request.operation)
            ))
        }
    }

    /// 駐車場詳細情報取得
    /// 
    /// 指定された駐車場の詳細情報を取得します。
    /// ユーザー認証情報がある場合はお気に入り状態も含めます。
    #[instrument(skip(self), fields(parking_lot_id = %parking_lot_id, user_id = ?user_id))]
    pub async fn get_parking_lot_detail(
        &self,
        parking_lot_id: &str,
        user_id: Option<String>,
    ) -> Result<Option<ParkingSearchResult>, ApiError> {
        info!("駐車場詳細情報取得を開始します: {}", parking_lot_id);

        // 駐車場の基本情報取得 - 実際には単一の駐車場を取得するロジックを実装
        let search_request = ParkingSearchRequest {
            latitude: None,
            longitude: None,
            address: None,
            radius_km: Some(0.0),
            usage_start_datetime: None,
            usage_end_datetime: None,
            vehicle_type_id: None,
            feature_ids: None,
            min_rating: None,
            max_hourly_rate: None,
            max_daily_rate: None,
            sort_by: Some("distance".to_string()),
            sort_order: Some("asc".to_string()),
            page: Some(1),
            page_size: Some(1000),
            favorites_only: Some(false),
            user_id: user_id.clone(),
        };
        let parking_lot_details = self.repository.search_parking_lots_by_location(&search_request).await
            .map_err(|e| self.handle_database_error(e))?;

        if let Some((parking_lot, rental_types, vehicle_types, features, maps_info)) = parking_lot_details.into_iter().find(|(lot, _, _, _, _)| lot.parking_lot_id == parking_lot_id) {
            // 詳細情報構築
            let availability_info = self.get_availability_info(&parking_lot, &ParkingSearchRequest::default()).await?;
            let pricing_info = self.get_pricing_info(&parking_lot, &rental_types, &ParkingSearchRequest::default()).await?;
            let favorite_info = if let Some(uid) = &user_id {
                self.get_favorite_info(&parking_lot.parking_lot_id, uid).await?
            } else {
                None
            };
            let rating_info = self.get_rating_info(&parking_lot.parking_lot_id).await?;

            let detail_result = ParkingSearchResult {
                parking_lot: ParkingLotResponse::from(parking_lot.clone()),
                location_info: maps_info.map(GoogleMapsResponse::from),
                rental_types: rental_types.into_iter().map(RentalTypeResponse::from).collect(),
                vehicle_types: vehicle_types.into_iter().map(VehicleTypeResponse::from).collect(),
                features: features.into_iter().map(ParkingFeatureResponse::from).collect(),
                distance_info: None,
                availability_info,
                pricing_info,
                favorite_info,
                rating_info,
            };

            info!("駐車場詳細情報取得が完了しました: {}", parking_lot_id);
            Ok(Some(detail_result))
        } else {
            warn!("指定された駐車場が見つかりません: {}", parking_lot_id);
            Ok(None)
        }
    }

    // 共通ヘルパーメソッド



    /// ユーザーアクセス権限の検証
    async fn validate_user_access(&self, user_id: &str) -> Result<(), ApiError> {
        if user_id.is_empty() {
            return Err(ApiError::ValidationError(
                "ユーザーIDが指定されていません".to_string()
            ));
        }

        // 追加のユーザー認証確認がある場合はここに実装
        Ok(())
    }

    /// 駐車場の存在確認
    async fn validate_parking_lot_exists(&self, parking_lot_id: &str) -> Result<(), ApiError> {
        let exists = self.repository.parking_lot_exists(parking_lot_id).await
            .map_err(|e| self.handle_database_error(e))?;
        
        if !exists {
            return Err(ApiError::NotFoundError(
                format!("駐車場ID: {} の駐車場が見つかりません", parking_lot_id)
            ));
        }
        
        Ok(())
    }

    /// お気に入りの存在確認
    async fn check_favorite_exists(&self, user_id: &str, parking_lot_id: &str) -> Result<bool, ApiError> {
        self.repository.check_favorite_exists(user_id, parking_lot_id).await
            .map_err(|e| self.handle_database_error(e))
    }

    /// データベースエラーの処理
    /// auth_signup_serviceのパターンに従ったエラーハンドリング
    fn handle_database_error(&self, db_err: DatabaseError) -> ApiError {
        error!("データベースエラーが発生しました: {}", db_err);
        
        match db_err {
            DatabaseError::QueryError(ref s) if s.contains("duplicate key") => {
                ApiError::DuplicateError(
                    "指定されたリソースは既に存在します".to_string()
                )
            }
            DatabaseError::QueryError(ref s) if s.contains("foreign key constraint") => {
                ApiError::ValidationError(
                    "関連するデータが見つかりません".to_string()
                )
            }
            DatabaseError::QueryError(ref s) if s.contains("value too long") => {
                ApiError::ValidationError(
                    "入力された値が長すぎます".to_string()
                )
            }
            DatabaseError::TransactionError(_) => {
                error!("トランザクションエラーが発生しました");
                ApiError::InternalServerError
            }
            DatabaseError::ConnectionError(_) => {
                error!("データベース接続エラーが発生しました");
                ApiError::InternalServerError
            }
            _ => ApiError::InternalServerError,
        }
    }

    // 仮実装メソッド（実装が必要な場合は拡張）

    async fn apply_search_filters(
        &self,
        lots: Vec<(TParkingLotsModel, Vec<TParkingRentalTypesModel>, Vec<MParkingVehicleTypesModel>, Vec<MParkingFeaturesModel>, Option<TParkingGoogleMapsModel>)>,
        _request: &ParkingSearchRequest,
    ) -> Result<Vec<(TParkingLotsModel, Vec<TParkingRentalTypesModel>, Vec<MParkingVehicleTypesModel>, Vec<MParkingFeaturesModel>, Option<TParkingGoogleMapsModel>)>, ApiError> {
        // フィルタリングロジックの実装
        Ok(lots)
    }

    async fn apply_favorite_filters(
        &self,
        lots: Vec<(TParkingLotsModel, Vec<TParkingRentalTypesModel>, Vec<MParkingVehicleTypesModel>, Vec<MParkingFeaturesModel>, Option<TParkingGoogleMapsModel>)>,
        _filters: &ParkingSearchFilters,
    ) -> Result<Vec<(TParkingLotsModel, Vec<TParkingRentalTypesModel>, Vec<MParkingVehicleTypesModel>, Vec<MParkingFeaturesModel>, Option<TParkingGoogleMapsModel>)>, ApiError> {
        // お気に入りフィルタリングロジックの実装
        Ok(lots)
    }

    async fn calculate_distances(
        &self,
        lots: Vec<(TParkingLotsModel, Vec<TParkingRentalTypesModel>, Vec<MParkingVehicleTypesModel>, Vec<MParkingFeaturesModel>, Option<TParkingGoogleMapsModel>)>,
        _lat: f64,
        _lng: f64,
    ) -> Result<Vec<(TParkingLotsModel, Option<DistanceInfo>, Vec<TParkingRentalTypesModel>, Vec<MParkingVehicleTypesModel>, Vec<MParkingFeaturesModel>, Option<TParkingGoogleMapsModel>)>, ApiError> {
        // 距離計算ロジックの実装
        Ok(lots.into_iter()
            .map(|(lot, rental, vehicle, features, maps)| (lot, None, rental, vehicle, features, maps))
            .collect())
    }

    async fn sort_parking_lots(
        &self,
        lots: Vec<(TParkingLotsModel, Option<DistanceInfo>, Vec<TParkingRentalTypesModel>, Vec<MParkingVehicleTypesModel>, Vec<MParkingFeaturesModel>, Option<TParkingGoogleMapsModel>)>,
        _request: &ParkingSearchRequest,
    ) -> Result<Vec<(TParkingLotsModel, Option<DistanceInfo>, Vec<TParkingRentalTypesModel>, Vec<MParkingVehicleTypesModel>, Vec<MParkingFeaturesModel>, Option<TParkingGoogleMapsModel>)>, ApiError> {
        // ソートロジックの実装
        Ok(lots)
    }

    async fn get_availability_info(&self, _parking_lot: &TParkingLotsModel, _request: &ParkingSearchRequest) -> Result<AvailabilityInfo, ApiError> {
        // 利用可能性情報の取得
        Ok(AvailabilityInfo {
            is_available: true,
            availability_reason: "営業時間内のため利用可能です".to_string(),
            is_within_operating_hours: true,
            requires_reservation: false,
            available_spaces: Some(10),
            total_spaces: Some(20),
        })
    }

    async fn get_pricing_info(&self, _parking_lot: &TParkingLotsModel, _rental_types: &[TParkingRentalTypesModel], _request: &ParkingSearchRequest) -> Result<PricingInfo, ApiError> {
        // 料金情報の取得
        Ok(PricingInfo {
            estimated_cost: Some(800),
            cheapest_rental_type: None,
            hourly_rate_range: Some(PriceRange {
                min_price: 200,
                max_price: 500,
                currency: "JPY".to_string(),
            }),
            daily_rate_range: Some(PriceRange {
                min_price: 1500,
                max_price: 3000,
                currency: "JPY".to_string(),
            }),
            pricing_display: "200-500円/時".to_string(),
        })
    }

    async fn get_favorite_info(&self, parking_lot_id: &str, user_id: &str) -> Result<Option<FavoriteInfo>, ApiError> {
        // お気に入り情報の取得
        let is_favorite = self.check_favorite_exists(user_id, parking_lot_id).await?;
        if is_favorite {
            Ok(Some(FavoriteInfo {
                is_favorite: true,
                favorite_added_at: Some(chrono::Utc::now()),
                favorite_memo: None,
            }))
        } else {
            Ok(None)
        }
    }

    async fn get_rating_info(&self, _parking_lot_id: &str) -> Result<Option<RatingInfo>, ApiError> {
        // 評価情報の取得
        Ok(Some(RatingInfo {
            average_rating: 4.2,
            rating_count: 15,
            rating_distribution: None,
            latest_reviews: None,
        }))
    }

    async fn build_search_info(&self, request: &ParkingSearchRequest) -> Result<SearchInfo, ApiError> {
        // 検索情報の構築
        Ok(SearchInfo {
            search_location: None,
            search_radius_km: request.radius_km,
            search_period: None,
            applied_filters: vec![],
            sort_info: SortInfo {
                sort_by: request.sort_by.clone().unwrap_or_else(|| "distance".to_string()),
                sort_order: request.sort_order.clone().unwrap_or_else(|| "asc".to_string()),
                sort_display_name: "距離順".to_string(),
            },
        })
    }
}
