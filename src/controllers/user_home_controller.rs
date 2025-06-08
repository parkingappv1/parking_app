use tracing::{ error, info};
use crate::controllers::api_response::{success_response, error_response};
use crate::services::UserHomeService;
use actix_web::{post, web, Responder};
use crate::models::{
    parking_status_model::{ParkingStatusRequest, UpdateParkingStatusRequest},
    parking_search_history_model::{ParkingSearchHistoryRequest},
    favorites_model:: {FavoritesRequest}
};
use crate::config::postgresql_database::PostgresDatabase;

/// 入出庫状況の取得
#[post("/parking-status")]
pub async fn get_parking_status(
    db: web::Data<PostgresDatabase>,
    req: web::Json<ParkingStatusRequest>,
) -> impl Responder {
    info!("Processing get_parking_status request for user_id: {} status: {}", req.user_id, req.status);
    let user_home_service = UserHomeService::new(db.pool().clone());
    
    match user_home_service.get_parking_status(&req).await {
        Ok(res) => {
            info!("Processing get_parting_status successfully: user_id: {} status: {}", req.user_id, req.status);
            // データ付き成功レスポンス
            success_response(res, None, None, None)
        },
        Err(e) =>  {  
            error!("Processing get_parting_status failed for user_id: {} status: {} : {}", req.user_id, req.status, e);
            error_response(401, &e.to_string())              
        },           
    }
}

/// 入出庫状況の更新
#[post("/update-status")]
pub async fn update_parking_status(
    db: web::Data<PostgresDatabase>,
    req: web::Json<UpdateParkingStatusRequest>,
) -> impl Responder {
    info!("Processing update_parking_status for status_id: {} reservation_id: {} check_inout_kbn: {}", &req.status_id, &req.reservation_id, &req.check_inout_kbn);
    let user_home_service = UserHomeService::new(db.pool().clone());
    
    if req.check_inout_kbn == "1" {
            match user_home_service.update_parking_status_checkin(&req).await {
            Ok(_) => {
                // シンプルな成功レスポンス
                success_response(true, None, None, None)
            },
            Err(e) => {
                error!("Processing  update_parking_status failed status_id: {}  reservation_id: {} check_inout_kbn: {} {}", &req.status_id, &req.reservation_id,  &req.check_inout_kbn, e);
                error_response(400, &e.to_string())
            },
        } 
    } else {
          match user_home_service.update_parking_status_checkout(&req).await {
            Ok(_) => {
                // シンプルな成功レスポンス
                success_response(true, None, None, None)
            },
            Err(e) => {
                error!("Processing  update_parking_status failed status_id: {} reservation_id: {} check_inout_kbn: {} {}", &req.status_id, &req.reservation_id, &req.check_inout_kbn, e);
                error_response(400, &e.to_string())
            },
        } 
    }

}

/// 駐車場検索履歴の取得
#[post("/search-history")]
pub async fn get_parking_search_history(
    db: web::Data<PostgresDatabase>,
    req: web::Json<ParkingSearchHistoryRequest>,
) -> impl Responder {
    info!("Processing get_parking_search_history request for user_id: {}", req.user_id);
    let user_home_service = UserHomeService::new(db.pool().clone());
    
    match user_home_service.get_parking_search_history(&req).await {
        Ok(res) => {
            info!("Processing get_parking_search_history successfully: user_id: {}", req.user_id);
            // データ付き成功レスポンス
            success_response(res, None, None, None)
        },
        Err(e) => {
            error!("Processing get_parking_search_history failed for user_id: {} : {}", req.user_id, e);
            error_response(401, &e.to_string())
        },
    }
}

 /// お気に入りの取得
#[post("/favorites")]
pub async fn get_favorites(
    db: web::Data<PostgresDatabase>,
    req: web::Json<FavoritesRequest>,
) -> impl Responder {
    info!("Processing get_favorites request for user_id: {}", req.user_id);
    let user_home_service = UserHomeService::new(db.pool().clone());
    
    match user_home_service.get_favorites(&req).await {
        Ok(res) => {
            info!("Processing get_favorites successfully: user_id: {}", req.user_id);
            // データ付き成功レスポンス
            success_response(res, None, None, None)
        },
        Err(e) => {
            error!("Processing get_favorites failed for user_id: {} : {}", req.user_id, e);
            error_response(401, &e.to_string())
        },
    }
}