use actix_web::{http::StatusCode, post, web::{self, Data}, Responder, ResponseError};
use tracing::{debug, error, instrument, warn};

use crate::{controllers::{ApiError, ApiResponse}, models::ParkingLotRequest, services::ParkingLotsService};

#[post("/add-parking-space")]
#[instrument(skip(service), fields(name = ?req))]
pub async fn add_parking_space_controller(
    req: web::Json<ParkingLotRequest>,
    // req: web::Json<Value>, // ここを serde_json::Value に変更
    service: Data<ParkingLotsService>,
) -> impl Responder {
    let request_data = req.into_inner();
    // let request_data: ParkingLotRequest = match parse_json_with_error_log(req.into_inner()) {
    //     Ok(data) => data,
    //     Err(resp) => return resp,  // 解析失败，直接返回 400 响应
    // };
    debug!(
        "駐車場登録リクエストを受信 - 駐車場名: {}, オーナーID: {}",
        request_data.parking_lot_name, request_data.owner_id
    );

    if let Err(validation_error) = request_data.validate() {
        warn!("駐車場登録の入力検証に失敗: {}", validation_error);
        return ApiError::ValidationError(validation_error).error_response();
    }

    match service.register_parking_lot(request_data).await {
        Ok(response) => {
            debug!(
                "駐車場登録成功 - 駐車場名: {}, ID: {}",
                response.parking_lot_name, response.parking_lot_id
            );
            ApiResponse::success(
                response,
                Some(StatusCode::CREATED.as_u16()),
                Some("駐車場登録が正常に完了しました。"),
                None,
            )
        }
        Err(api_err) => {
            // 打印简洁的错误信息（Display）
            error!("駐車場登録に失敗: {}", api_err);
            
            // 直接打印更详细的错误（Debug）
            error!("駐車場登録の詳細エラー: {:?}", api_err);
            
            match &api_err {
                ApiError::DuplicateError(_) => {
                    warn!("重複する駐車場登録の試行");
                }
                ApiError::InternalServerError => {
                    error!("駐車場登録処理中の内部サーバーエラー");
                }
                _ => {
                    // 这里其实已经打印过详细错误了，可以删掉，避免重复
                    // error!("駐車場登録中の予期しないエラー: {:?}", api_err);
                }
            }
            api_err.error_response()
        }

    }
}
