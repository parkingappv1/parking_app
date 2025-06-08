use tracing::{ error, info};
use crate::controllers::api_response::{success_response, error_response};
use crate::services::UseHistoryService;
use actix_web::{post, web, Responder};
use crate::models::{
     parking_use_history_model::{ParkingUseHistoryRequest, ParkingUseHistoryDetailRequest},
    parking_feature_model::{ParkingFeatureRequest},
    };
use crate::config::postgresql_database::PostgresDatabase;

/// 駐車場検索履歴の取得
#[post("/use-history")]
pub async fn get_parking_use_history(
    db: web::Data<PostgresDatabase>,
    req: web::Json<ParkingUseHistoryRequest>,
) -> impl Responder {
    info!("Processing get_parking_use_history request for user_id: {}", req.user_id);
    let use_history_service = UseHistoryService::new(db.pool().clone());
    
    match use_history_service.get_parking_use_history(&req).await {
        Ok(res) => {
            info!("Processing get_parking_use_history successfully: user_id: {}", req.user_id);
            // データ付き成功レスポンス
            success_response(res, None, None, None)
        },
        Err(e) => {
            error!("Processing get_parking_use_history failed for user_id: {} : {}", req.user_id, e);
            error_response(401, &e.to_string())
        },
    }
}

/// 駐車場検索履歴詳細の取得
#[post("/use-history-detail")]
pub async fn get_parking_use_history_detail(
    db: web::Data<PostgresDatabase>,
    req: web::Json<ParkingUseHistoryDetailRequest>,
) -> impl Responder {
    info!("Processing get_parking_use_history_detail request for reservation_id: {}", req.reservation_id);
    let use_history_service = UseHistoryService::new(db.pool().clone());
    
    match use_history_service.get_parking_use_history_detail(&req).await {
        Ok(res) => {
            info!("Processing get_parking_use_history_detail successfully: reservation_id: {}", req.reservation_id);
            // データ付き成功レスポンス
            success_response(res, None, None, None)
        },
        Err(e) =>  {  
            error!("Processing get_parking_use_history_detail failed for reservation_id: {} : {}", req.reservation_id, e);
            error_response(401, &e.to_string())              
        },           
    }
}

/// 駐車場検索履歴の取得
#[post("/parking-features")]
pub async fn get_parking_features(
    db: web::Data<PostgresDatabase>,
    req: web::Json<ParkingFeatureRequest>,
) -> impl Responder {
    info!("Processing get_parking_features request for parking_lot_id: {}", req.parking_lot_id);
    let use_history_service = UseHistoryService::new(db.pool().clone());
    
    match use_history_service.get_parking_features(&req).await {
        Ok(res) => {
            info!("Processing get_parking_features successfully: parking_lot_id: {}", req.parking_lot_id);
            // データ付き成功レスポンス
            success_response(res, None, None, None)
        },
        Err(e) => {
            error!("Processing get_parking_features failed for parking_lot_id: {} : {}", req.parking_lot_id, e);
            error_response(401, &e.to_string())
        },
    }
}