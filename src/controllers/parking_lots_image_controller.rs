use actix_web::{http::StatusCode, post, web::{ Data}, Responder, ResponseError};
use actix_multipart::Multipart;
use futures_util::TryStreamExt;
use std::{fs, io::Write};
use uuid::Uuid;
use tracing::{debug, error, instrument, warn};

use crate::{
    controllers::{ApiError, ApiResponse},
    models::ParkingImageRequest,
    services::ParkingLotsService,
};

#[post("/parking-lot-images/upload")]
#[instrument(skip(service, payload))]
pub async fn upload_parking_lot_images_controller(
    service: Data<ParkingLotsService>,
    mut payload: Multipart,
) -> impl Responder {
    debug!("（parking_lots_image_controller.rs）画像アップロードリクエストを受信");

    let mut parking_lot_id: Option<String> = None;
    let mut image_records: Vec<ParkingImageRequest> = vec![];

    // 1. 解析 multipart 字段
    while let Some(mut field) = match payload.try_next().await {
        Ok(Some(f)) => Some(f),
        Ok(None) => None,
        Err(e) => {
            error!("（parking_lots_image_controller.rs）Multipartの読み取りに失敗: {}", e);
            return ApiError::BadRequest("リクエスト形式が正しくありません".to_string()).error_response();
        }
    } {
        let content_disposition = field.content_disposition();
        let field_name = match content_disposition.and_then(|cd| cd.get_name()) {
            Some(name) => name,
            None => {
                warn!("（parking_lots_image_controller.rs）フィールド名なしのMultipartフィールドをスキップ");
                continue;
            }
        };
        debug!("parking_lots_image_controller.rs）multipart field name: {}", field_name);

        if field_name == "parking_lot_id" {
            // 读取 parking_lot_id
            let mut id_bytes = Vec::new();
            while let Some(chunk) = field.try_next().await.unwrap_or(None) {
                id_bytes.extend_from_slice(&chunk);
            }
            parking_lot_id = Some(String::from_utf8(id_bytes).unwrap_or_default());

        } else if field_name == "images" {
            // 2. 先确保有 parking_lot_id
            let lot_id = match &parking_lot_id {
                Some(id) => id,
                None => {
                    warn!("parking_lots_image_controller.rs）parking_lot_id が存在しません");
                    return ApiError::BadRequest("parking_lot_id が必要です".to_string()).error_response();
                }
            };

            let base_dir = format!("./uploadfolder/parking_lot_images/{}", lot_id);
            if let Err(e) = fs::create_dir_all(&base_dir) {
                error!("parking_lots_image_controller.rs）ディレクトリ作成失敗: {}", e);
                return ApiError::InternalServerError.error_response();
            }

            let filename = content_disposition
                .and_then(|cd| cd.get_filename())
                .map(sanitize_filename::sanitize)
                .unwrap_or_else(|| format!("upload_{}.jpg", Uuid::new_v4()));

            let filepath = format!("{}/{}", base_dir, filename);

            // 3. 文件写入
            match fs::File::create(&filepath) {
                Ok(mut file) => {
                    while let Some(chunk) = field.try_next().await.unwrap_or(None) {
                        if let Err(e) = file.write_all(&chunk) {
                            error!("parking_lots_image_controller.rs）画像の書き込みに失敗: {}", e);
                            return ApiError::InternalServerError.error_response();
                        }
                    }
                }
                Err(e) => {
                    error!("parking_lots_image_controller.rs）画像ファイルの作成に失敗: {}", e);
                    return ApiError::InternalServerError.error_response();
                }
            }

            image_records.push(ParkingImageRequest {
                parking_lot_id: lot_id.clone(),
                image_url: format!("uploadfolder/parking_lot_images/{}/{}", lot_id, filename),
            });
        }
    }

    if parking_lot_id.is_none() {
        return ApiError::BadRequest("parking_lot_id が指定されていません".to_string()).error_response();
    }

    if image_records.is_empty() {
        return ApiError::BadRequest("画像ファイルがありません".to_string()).error_response();
    }

    // 4. 调用 service 保存记录
    match service.upload_parking_lot_images(&image_records).await {
        Ok(_) => {
            debug!("parking_lots_image_controller.rs）画像アップロード完了 - 枚数: {}", image_records.len());
            ApiResponse::success(
                serde_json::json!({
                    "uploaded": image_records.len(),
                    "images": image_records.iter().map(|i| i.image_url.clone()).collect::<Vec<_>>(),
                }),
                Some(StatusCode::OK.as_u16()),
                Some("画像アップロードに成功しました"),
                None,
            )
        }
        Err(e) => {
            error!("parking_lots_image_controller.rs）DBへの保存に失敗: {}", e);
            ApiError::InternalServerError.error_response()
        }
    }
}
