// src/models/mod.rs
use sqlx::FromRow;
use uuid::Uuid;

pub mod auth_signup_model;
pub mod auth_signin_model;
pub mod m_login_model;
pub mod m_users_model;
pub mod m_owners_model;

// Parking-related models
pub mod t_parking_lots_model;
pub mod t_parking_google_maps_model;
pub mod t_parking_rental_types_model;
pub mod m_parking_vehicle_types_model;
pub mod m_parking_features_model;
pub mod parking_search_model;
pub mod parking_lots_model;

// UserHome-related models
pub mod parking_status_model;
pub mod favorites_model;
pub mod parking_search_history_model;
pub mod parking_use_history_model;
pub mod parking_feature_model;

pub use auth_signin_model::{
    AuthSigninRequest, AuthSigninResponse, CurrentUserResponse,
    PasswordResetRequest, PasswordResetVerification, PasswordResetCompletion
};

pub use parking_status_model::{ ParkingStatusRequest, ParkingStatusResponse, UpdateParkingStatusRequest};
pub use parking_search_history_model::{ParkingSearchHistoryRequest, ParkingSearchHistoryResponse};
pub use favorites_model::{FavoritesRequest, FavoriteResponse};
pub use parking_lots_model::{ParkingLotRequest, ParkingLotResponse,ParkingImageRequest};

pub use parking_use_history_model::{ParkingUseHistoryRequest, ParkingUseHistoryDetailRequest, ParkingUseHistoryResponse, ParkingUseHistoryDetailResponse};
pub use parking_feature_model::{ParkingFeatureRequest, ParkingFeatureResponse};


#[derive(Debug, FromRow)]
pub struct LoginIdRow {
    pub login_id: Uuid,
}

#[derive(Debug, FromRow)]
pub struct UserIdRow {
    pub user_id: String,
}

#[derive(Debug, FromRow)]
pub struct OwnerIdRow {
    pub owner_id: String,
}