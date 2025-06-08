use crate::models::{
   parking_use_history_model::{ParkingUseHistoryRequest, ParkingUseHistoryDetailRequest, ParkingUseHistoryResponse, ParkingUseHistoryDetailResponse},
   parking_feature_model::{ParkingFeatureRequest, ParkingFeatureResponse},
};
use crate::repositories::UseHistoryRepository;
use crate::controllers::api_error::ApiError;
use sqlx::PgPool;
use tracing::{debug, error, info};

/// 駐車場利用履歴用サービス
pub struct UseHistoryService {
    repo: UseHistoryRepository,
}

impl UseHistoryService {
    /// Create a new UseHistoryService with the given database pool
    pub fn new(pool: PgPool) -> Self {
        Self { repo: UseHistoryRepository::new(pool) }
    }

    /// 駐車場利用履歴の取得
    pub async fn get_parking_use_history(&self, request: &ParkingUseHistoryRequest) -> Result<Vec<ParkingUseHistoryResponse>, ApiError> {
        debug!("get_parking_use_history use_rid: {}", request.user_id);

        let response: Vec<ParkingUseHistoryResponse> = self.repo.get_parking_use_history(request).await
            .map_err(|e| {
                error!("Failed to get_parking_use_history information: {}", e);
                ApiError::InternalServerError
            })?;

        info!("get_parking_use_history successfully: user_id: {}", request.user_id);
        Ok(response)
    }

    /// 駐車場利用履歴詳細の取得
    pub async fn get_parking_use_history_detail(&self, request: &ParkingUseHistoryDetailRequest) -> Result<ParkingUseHistoryDetailResponse, ApiError> {
        debug!("get_parking_use_history_detail reservation_id: {}", request.reservation_id);

        let response = self.repo.get_parking_use_history_detail(request).await
            .map_err(|e| {
                error!("Failed to get_parking_status information: {}", e);
                ApiError::InternalServerError
            })?;

        info!("get_parking_use_history_detail successfully: reservation_id: {}", request.reservation_id);
        Ok(response)
    }

     /// 駐車場特徴の取得
    pub async fn get_parking_features(&self, request: &ParkingFeatureRequest) -> Result<Vec<ParkingFeatureResponse>, ApiError> {
        debug!("get_parking_features parking_lot_id: {}", request.parking_lot_id);

        let response: Vec<ParkingFeatureResponse> = self.repo.get_parking_features(request).await
            .map_err(|e| {
                error!("Failed to get_parking_features information: {}", e);
                ApiError::InternalServerError
            })?;

        info!("get_parking_features successfully: parking_lot_id: {}", request.parking_lot_id);
        Ok(response)
    }

    
}