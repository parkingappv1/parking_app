use crate::models::{
    favorites_model:: {FavoriteResponse, FavoritesRequest}, parking_status_model::{ParkingStatusRequest, ParkingStatusResponse, UpdateParkingStatusRequest}, ParkingSearchHistoryRequest, ParkingSearchHistoryResponse
};
use crate::repositories::UserHomeRepository;
use crate::controllers::api_error::ApiError;
use sqlx::PgPool;
use tracing::{debug, error, info};

/// ユーザホーム用サービス
pub struct UserHomeService {
    repo: UserHomeRepository,
}

impl UserHomeService {
    /// Create a new UserHomeService with the given database pool
    pub fn new(pool: PgPool) -> Self {
        Self { repo: UserHomeRepository::new(pool) }
    }

    /// 入出庫状況の取得
    pub async fn get_parking_status(&self, request: &ParkingStatusRequest) -> Result<ParkingStatusResponse, ApiError> {
        debug!("get_parking_status user_id: {} status: {}", request.user_id, request.status);

        let response = self.repo.get_parking_status(request).await
            .map_err(|e| {
                error!("Failed to get_parking_status information: {}", e);
                ApiError::InternalServerError
            })?;

        info!("get_parking_status successfully: user_id: {} status: {}", request.user_id, request.status);
        Ok(response)
    }

    /// 入庫状況の更新
    pub async fn update_parking_status_checkin(&self, request: &UpdateParkingStatusRequest) -> Result<(), ApiError> {
         debug!("update_parking_status_checkin status_id: {}", request.status_id);

        self.repo.update_parking_status_checkin(&request.status_id).await
            .map_err(|e| {
                error!("Failed to update_parking_status_checkin: {}", e);
                ApiError::InternalServerError
            })?;

           info!("update_parking_status_checkin successfully status_id: {}", request.status_id);
        Ok(())
    }

    /// 出庫状況の更新
    pub async fn update_parking_status_checkout(&self, request: &UpdateParkingStatusRequest) -> Result<(), ApiError> {
        debug!("update_parking_status_checkout status_id: {} reservation_id: {}", request.status_id, request.reservation_id);

        self.repo.update_parking_status_checkout(&request.status_id).await
            .map_err(|e| {
                error!("Failed to pdate_parking_status_checkout: {}", e);
                ApiError::InternalServerError
            })?;

        self.repo.update_reservation_status(&request.reservation_id).await
            .map_err(|e| {
                error!("Failed to update_reservation_status: {}", e);
                ApiError::InternalServerError
            })?;

        info!("update_parking_status_checkout successfully status_id: {} reservation_id: {}", request.status_id, request.reservation_id);

        Ok(())
    }

    /// 駐車場検索履歴の取得
    pub async fn get_parking_search_history(&self, request: &ParkingSearchHistoryRequest) -> Result<Vec<ParkingSearchHistoryResponse>, ApiError> {
        debug!("get_favorites user_id: {}", request.user_id);

        let response: Vec<ParkingSearchHistoryResponse> = self.repo.get_parking_search_history(request).await
            .map_err(|e| {
                error!("Failed to get_parking_search_history information: {}", e);
                ApiError::InternalServerError
            })?;

        info!("get_parking_search_history successfully: user_id: {}", request.user_id);
        Ok(response)
    }

    /// お気に入りの取得
    pub async fn get_favorites(&self, request: &FavoritesRequest) -> Result<Vec<FavoriteResponse>, ApiError> {
        debug!("get_favorites user_id: {}", request.user_id);

        let response = self.repo.get_favorites(request).await
            .map_err(|e| {
                error!("Failed to get_favorites information: {}", e);
                ApiError::InternalServerError
            })?;

        info!("get_favorites successfully: user_id: {}", request.user_id);
        Ok(response)
    }

    
}