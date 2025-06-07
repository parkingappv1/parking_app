use actix_web::http::StatusCode;
use actix_web::{
    HttpRequest, Responder, ResponseError, post, get,
    web::{Data, Json, Query, Path},
};
use tracing::{debug, error, instrument, warn, info};

use crate::controllers::api_error::ApiError;
use crate::controllers::api_response::ApiResponse;
use crate::models::parking_search_model::{
    ParkingSearchRequest, FavoriteOperationRequest,
};
use crate::services::{ParkingSearchService, parking_search_service::ParkingSearchFilters};

/// 駐車場検索エンドポイント
///
/// 位置情報、フィルター条件、ソート設定に基づいて駐車場を検索します。
/// 包括的な入力検証、構造化されたAPIレスポンス、詳細なログ記録を提供する
/// 駐車場検索処理を行います。
///
/// # エンドポイント
/// `POST /api/parking/search`
///
/// # 必要なヘッダー
/// - `Content-Type`: application/json
/// - `Authorization`: Bearer <jwt_token> (任意：お気に入り情報用)
///
/// # レスポンス
/// - `200 OK`: 検索成功、駐車場リストを返す
/// - `400 Bad Request`: 無効な検索条件
/// - `422 Unprocessable Entity`: 検証エラー
/// - `500 Internal Server Error`: サーバー処理エラー
#[post("/search")]
#[instrument(skip(service), fields(latitude = ?req.latitude, longitude = ?req.longitude))]
pub async fn search_parking_lots_controller(
    req: Json<ParkingSearchRequest>,
    service: Data<ParkingSearchService>,
    http_req: HttpRequest,
) -> impl Responder {
    let request_data = req.into_inner();
    let connection_info = http_req.connection_info();
    let client_ip = connection_info.realip_remote_addr().unwrap_or("不明");

    debug!(
        "駐車場検索リクエストを受信 - 緯度: {:?}, 経度: {:?}, IP: {}",
        request_data.latitude, request_data.longitude, client_ip
    );

    // モデルの検証メソッドを使用した入力データの検証
    if let Err(validation_error) = request_data.validate() {
        warn!("駐車場検索の入力検証に失敗: {}", validation_error);
        return ApiError::ValidationError(validation_error).error_response();
    }

    // 認証されたユーザーIDの取得（オプション）
    let user_id = extract_user_id_from_request(&http_req);

    // 駐車場検索処理の実行
    match service.search_parking_lots(request_data, user_id).await {
        Ok(search_response) => {
            info!(
                "駐車場検索が成功 - 結果数: {}, 総数: {}, IP: {}",
                search_response.parking_lots.len(), 
                search_response.pagination.total_count,
                client_ip
            );
            ApiResponse::success(
                search_response,
                Some(StatusCode::OK.as_u16()),
                Some("駐車場検索が正常に完了しました"),
                None,
            )
        }
        Err(api_err) => {
            error!("駐車場検索に失敗 - IP: {}: {}", client_ip, api_err);

            match &api_err {
                ApiError::ValidationError(_) => {
                    warn!("駐車場検索の検証エラー - IP: {}", client_ip);
                }
                ApiError::InternalServerError => {
                    error!("駐車場検索処理中の内部サーバーエラー - IP: {}", client_ip);
                }
                _ => {
                    error!("駐車場検索中の予期しないエラー - IP: {}: {:?}", client_ip, api_err);
                }
            }
            api_err.error_response()
        }
    }
}

/// お気に入り駐車場検索エンドポイント
///
/// 認証されたユーザーのお気に入り駐車場を検索します。
/// JWTトークンによる認証、包括的なアクセス制御を提供する
/// お気に入り検索処理を行います。
///
/// # エンドポイント
/// `GET /api/parking/favorites`
///
/// # 必要なヘッダー
/// - `Authorization`: Bearer <jwt_token>
///
/// # レスポンス
/// - `200 OK`: 検索成功、お気に入り駐車場リストを返す
/// - `401 Unauthorized`: 認証が必要
/// - `403 Forbidden`: アクセス権限なし
/// - `500 Internal Server Error`: サーバー処理エラー
#[get("/favorites")]
#[instrument(skip(service))]
pub async fn get_favorite_parking_lots_controller(
    service: Data<ParkingSearchService>,
    query: Query<ParkingSearchFilters>,
    http_req: HttpRequest,
) -> impl Responder {
    let filters = query.into_inner();
    let connection_info = http_req.connection_info();
    let client_ip = connection_info.realip_remote_addr().unwrap_or("不明");

    debug!("お気に入り駐車場検索リクエストを受信 - IP: {}", client_ip);

    // 認証されたユーザーIDの取得（必須）
    let user_id = match extract_user_id_from_request(&http_req) {
        Some(uid) => uid,
        None => {
            warn!("お気に入り検索で認証情報が不足 - IP: {}", client_ip);
            return ApiError::AuthenticationError(
                "お気に入り検索には認証が必要です".to_string()
            ).error_response();
        }
    };

    // お気に入り検索処理の実行
    match service.get_favorite_parking_lots(filters, user_id).await {
        Ok(search_response) => {
            info!(
                "お気に入り駐車場検索が成功 - 結果数: {}, IP: {}",
                search_response.parking_lots.len(), client_ip
            );
            ApiResponse::success(
                search_response,
                Some(StatusCode::OK.as_u16()),
                Some("お気に入り駐車場検索が正常に完了しました"),
                None,
            )
        }
        Err(api_err) => {
            error!("お気に入り駐車場検索に失敗 - IP: {}: {}", client_ip, api_err);

            match &api_err {
                ApiError::AuthenticationError(_) => {
                    warn!("お気に入り検索の認証エラー - IP: {}", client_ip);
                }
                ApiError::InternalServerError => {
                    error!("お気に入り検索処理中の内部サーバーエラー - IP: {}", client_ip);
                }
                _ => {
                    error!("お気に入り検索中の予期しないエラー - IP: {}: {:?}", client_ip, api_err);
                }
            }
            api_err.error_response()
        }
    }
}

/// お気に入り操作エンドポイント
///
/// 駐車場をお気に入りに追加・削除します。
/// 認証、認可、包括的な検証、トランザクション処理を提供する
/// お気に入り管理機能を行います。
///
/// # エンドポイント
/// `POST /api/parking/favorites`
///
/// # 必要なヘッダー
/// - `Content-Type`: application/json
/// - `Authorization`: Bearer <jwt_token>
///
/// # レスポンス
/// - `200 OK`: 操作成功
/// - `400 Bad Request`: 無効なリクエストデータ
/// - `401 Unauthorized`: 認証が必要
/// - `403 Forbidden`: アクセス権限なし
/// - `404 Not Found`: 指定された駐車場が見つからない
/// - `500 Internal Server Error`: サーバー処理エラー
#[post("/favorites")]
#[instrument(skip(service), fields(parking_lot_id = %req.parking_lot_id, operation = %req.operation))]
pub async fn manage_favorite_parking_lot_controller(
    service: Data<ParkingSearchService>,
    req: Json<FavoriteOperationRequest>,
    http_req: HttpRequest,
) -> impl Responder {
    let request_data = req.into_inner();
    let connection_info = http_req.connection_info();
    let client_ip = connection_info.realip_remote_addr().unwrap_or("不明");

    debug!(
        "お気に入り操作リクエストを受信 - 駐車場ID: {}, 操作: {}, IP: {}",
        request_data.parking_lot_id, request_data.operation, client_ip
    );

    // モデルの検証メソッドを使用した入力データの検証
    if let Err(validation_error) = request_data.validate() {
        warn!("お気に入り操作の入力検証に失敗 - IP: {}: {}", client_ip, validation_error);
        return ApiError::ValidationError(validation_error).error_response();
    }

    // 認証されたユーザーIDの取得（必須）
    let user_id = match extract_user_id_from_request(&http_req) {
        Some(uid) => uid,
        None => {
            warn!("お気に入り操作で認証情報が不足 - IP: {}", client_ip);
            return ApiError::AuthenticationError(
                "お気に入り操作には認証が必要です".to_string()
            ).error_response();
        }
    };

    // ユーザーIDをリクエストに追加
    let mut enriched_request = request_data;
    enriched_request.user_id = user_id;

    // お気に入り操作処理の実行
    match service.manage_favorite_operation(enriched_request.clone()).await {
        Ok(operation_response) => {
            info!(
                "お気に入り操作が成功 - 駐車場ID: {}, 操作: {}, IP: {}",
                enriched_request.parking_lot_id, enriched_request.operation, client_ip
            );
            ApiResponse::success(
                operation_response,
                Some(StatusCode::OK.as_u16()),
                Some("お気に入り操作が正常に完了しました"),
                None,
            )
        }
        Err(api_err) => {
            error!("お気に入り操作に失敗 - IP: {}: {}", client_ip, api_err);

            match &api_err {
                ApiError::ValidationError(_) => {
                    warn!("お気に入り操作の検証エラー - IP: {}", client_ip);
                }
                ApiError::AuthenticationError(_) => {
                    warn!("お気に入り操作の認証エラー - IP: {}", client_ip);
                }
                ApiError::NotFoundError(_) => {
                    warn!("指定された駐車場が見つかりません - IP: {}", client_ip);
                }
                ApiError::DuplicateError(_) => {
                    warn!("お気に入り操作の重複エラー - IP: {}", client_ip);
                }
                ApiError::InternalServerError => {
                    error!("お気に入り操作処理中の内部サーバーエラー - IP: {}", client_ip);
                }
                _ => {
                    error!("お気に入り操作中の予期しないエラー - IP: {}: {:?}", client_ip, api_err);
                }
            }
            api_err.error_response()
        }
    }
}

/// 駐車場詳細取得エンドポイント
///
/// 指定された駐車場の詳細情報を取得します。
/// 認証情報がある場合はお気に入り状態も含めて返します。
///
/// # エンドポイント
/// `GET /api/parking/details/{parking_lot_id}`
///
/// # 必要なヘッダー
/// - `Authorization`: Bearer <jwt_token> (任意)
///
/// # レスポンス
/// - `200 OK`: 取得成功、駐車場詳細を返す
/// - `404 Not Found`: 指定された駐車場が見つからない
/// - `500 Internal Server Error`: サーバー処理エラー
#[get("/details/{parking_lot_id}")]
#[instrument(skip(service), fields(parking_lot_id = %parking_lot_id))]
pub async fn get_parking_lot_detail_controller(
    service: Data<ParkingSearchService>,
    parking_lot_id: Path<String>,
    http_req: HttpRequest,
) -> impl Responder {
    let parking_lot_id = parking_lot_id.into_inner();
    let connection_info = http_req.connection_info();
    let client_ip = connection_info.realip_remote_addr().unwrap_or("不明");

    debug!("駐車場詳細取得リクエストを受信 - 駐車場ID: {}, IP: {}", parking_lot_id, client_ip);

    // 認証されたユーザーIDの取得（オプション）
    let user_id = extract_user_id_from_request(&http_req);

    // 駐車場詳細取得処理の実行
    match service.get_parking_lot_detail(&parking_lot_id, user_id).await {
        Ok(Some(detail_response)) => {
            info!(
                "駐車場詳細取得が成功 - 駐車場ID: {}, 駐車場名: {}, IP: {}",
                parking_lot_id, detail_response.parking_lot.parking_lot_name, client_ip
            );
            ApiResponse::success(
                detail_response,
                Some(StatusCode::OK.as_u16()),
                Some("駐車場詳細の取得が正常に完了しました"),
                None,
            )
        }
        Ok(None) => {
            warn!("指定された駐車場が見つかりません - 駐車場ID: {}, IP: {}", parking_lot_id, client_ip);
            ApiError::NotFoundError(
                format!("駐車場ID: {} の駐車場が見つかりません", parking_lot_id)
            ).error_response()
        }
        Err(api_err) => {
            error!("駐車場詳細取得に失敗 - 駐車場ID: {}, IP: {}: {}", parking_lot_id, client_ip, api_err);

            match &api_err {
                ApiError::NotFoundError(_) => {
                    warn!("駐車場詳細取得で対象が見つかりません - IP: {}", client_ip);
                }
                ApiError::InternalServerError => {
                    error!("駐車場詳細取得処理中の内部サーバーエラー - IP: {}", client_ip);
                }
                _ => {
                    error!("駐車場詳細取得中の予期しないエラー - IP: {}: {:?}", client_ip, api_err);
                }
            }
            api_err.error_response()
        }
    }
}

// プライベートヘルパーメソッド

/// HTTPリクエストからユーザーIDを抽出
/// 
/// JWTトークンから認証されたユーザーのIDを取得します。
/// 認証が失敗した場合やトークンが無効な場合はNoneを返します。
fn extract_user_id_from_request(req: &HttpRequest) -> Option<String> {
    // TODO: JWTミドルウェアと連携してユーザーIDを抽出する実装
    // 現在は仮の実装として、ヘッダーから直接取得する例を示す
    req.headers()
        .get("X-User-ID")
        .and_then(|header| header.to_str().ok())
        .map(|s| s.to_string())
}
