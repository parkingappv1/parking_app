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


pub use auth_signin_model::{
    AuthSigninRequest, AuthSigninResponse, CurrentUserResponse,
    PasswordResetRequest, PasswordResetVerification, PasswordResetCompletion
};


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