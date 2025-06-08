//! Repository layer for the parking application.
//!
//! This module contains all data access implementations that encapsulate
//! the storage and retrieval of data. Repositories are responsible for:
//! - Database interactions
//! - CRUD operations
//! - Query implementation
//! - Data transformation between database and domain models

// Import external types
use sqlx::PgPool;

// Additional repositories will be added here
// pub mod XXXX_repository;
// pub use XXXX_repository::ParkingRepository;

// Repository for authentication operations
pub mod auth_signin_repository;
pub use auth_signin_repository::AuthSigninRepository;

/// Repository for user signup operations
pub mod auth_signup_repository;
pub use auth_signup_repository::AuthSignupRepository;

/// Repository for parking search operations
pub mod parking_search_repository;
pub use parking_search_repository::ParkingSearchRepository;

pub mod user_home_repository;
pub use user_home_repository::UserHomeRepository;

pub mod use_history_repository;
pub use use_history_repository::UseHistoryRepository;

// Common repository utilities and interfaces
mod repository_utils {
    use sqlx::PgPool;
    use tracing::info;
    
    /// Check database connectivity
    pub async fn check_connectivity(pool: &PgPool) -> Result<(), sqlx::Error> {
        info!("Checking database connectivity");
        sqlx::query("SELECT 1").execute(pool).await?;
        info!("Database connection successful");
        Ok(())
    }
    
    /// Initialize repositories' common resources
    pub fn init_repositories() {
        info!("リポジトリ層を初期化しています！");
        // Perform any global repository initialization here
    }
}

/// Initialize the repository layer
pub fn init() {
    repository_utils::init_repositories();
}

/// Health check for repository connectivity
pub async fn health_check(pool: &PgPool) -> bool {
    repository_utils::check_connectivity(pool).await.is_ok()
}
