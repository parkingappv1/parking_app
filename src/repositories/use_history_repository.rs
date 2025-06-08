use crate::controllers::api_error::ApiError;
use crate::models::{
    parking_use_history_model::{ParkingUseHistoryRequest, ParkingUseHistoryDetailRequest, ParkingUseHistoryResponse, ParkingUseHistoryDetailResponse},
    parking_feature_model::{ParkingFeatureRequest, ParkingFeatureResponse},
};
use sqlx::{postgres::PgPool};
use tracing::{debug, error};

pub struct UseHistoryRepository {
    pool: PgPool,
}

impl UseHistoryRepository {
    /// Create a new UseHistoryRepository with the given database pool
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    /// 駐車場利用詳細の取得
    pub async fn get_parking_use_history_detail(&self, req: &ParkingUseHistoryDetailRequest) -> Result<ParkingUseHistoryDetailResponse, ApiError> {
        debug!("Fetching t_reservation_details by reservation_id: {}", req.reservation_id);

        let sql = "
            select
                t_reservation_details.detail_id
                , t_parking_lots.parking_lot_id
                , t_parking_lots.parking_lot_name
                , t_reservation_details.area
                , COALESCE( 
                    to_char( 
                        t_parking_status.entry_datetime AT TIME ZONE 'Asia/Tokyo'
                        , 'yyyy/MM/dd HH24:MI'
                    ) 
                    , '-'
                ) AS entry_datetime
                , COALESCE( 
                    to_char( 
                        t_parking_status.exit_datetime AT TIME ZONE 'Asia/Tokyo'
                        , 'yyyy/MM/dd HH24:MI'
                    ) 
                    , '-'
                ) AS exit_datetime
                , to_char( 
                    t_reservations.start_datetime AT TIME ZONE 'Asia/Tokyo'
                    , 'yyyy/MM/dd HH24:MI'
                ) as start_datetime
                , to_char( 
                    t_reservations.end_datetime AT TIME ZONE 'Asia/Tokyo'
                    , 'yyyy/MM/dd HH24:MI'
                ) as end_datetime
                , to_char(t_reservation_details.amount,  'FM99,999,999') as amount
                , t_reservation_details.created_datetime 
                , t_reservation_details.updated_datetime 
            from
                t_reservations 
                inner join t_parking_lots 
                    on t_parking_lots.parking_lot_id = t_reservations.parking_lot_id 
                inner join t_parking_status 
                    on t_parking_status.reservation_id = t_reservations.reservation_id 
                inner join t_reservation_details
                on t_reservation_details.reservation_id = t_reservations.reservation_id
            where
                t_reservations.reservation_id = $1 
        ";

        let res = sqlx::query_as::<_, ParkingUseHistoryDetailResponse>(sql)
            .bind(&req.reservation_id)
            .fetch_one(&self.pool)
            .await
            .map_err(|e| match e {
                sqlx::Error::RowNotFound => {
                    ApiError::NotFoundError("入駐車場利用履歴詳細が見つかりません".into())
                }
                _ => {
                    error!("Database error: {:?}", e);
                    ApiError::DatabaseError(format!("入駐車場利用履歴詳細の取得に失敗しました: {}", e))
                }
            })?;

        Ok(res)
    }

    /// 駐車場利用履歴の取得
    pub async fn get_parking_use_history(&self, req: &ParkingUseHistoryRequest) -> Result<Vec<ParkingUseHistoryResponse>, ApiError> {
        debug!("Fetching t_reservations by user_id: {} ", req.user_id);

        let sql = "
            select
                t_parking_status.reservation_id
                , t_parking_lots.parking_lot_name
                , t_reservation_details.area
                , COALESCE( 
                    to_char( 
                        t_parking_status.entry_datetime AT TIME ZONE 'Asia/Tokyo'
                        , 'yyyy/MM/dd HH24:MI'
                    ) 
                    , '-'
                ) AS entry_datetime
                , COALESCE( 
                    to_char( 
                        t_parking_status.exit_datetime AT TIME ZONE 'Asia/Tokyo'
                        , 'yyyy/MM/dd HH24:MI'
                    ) 
                    , '-'
                ) AS exit_datetime
                , to_char( 
                    t_reservations.start_datetime AT TIME ZONE 'Asia/Tokyo'
                    , 'yyyy/MM/dd HH24:MI'
                ) as start_datetime
                , to_char( 
                    t_reservations.end_datetime AT TIME ZONE 'Asia/Tokyo'
                    , 'yyyy/MM/dd HH24:MI'
                ) as end_datetime
                , to_char(t_reservation_details.amount,  'FM99,999,999') as amount
                , t_reservations.created_datetime 
                , t_reservations.updated_datetime 
            from
                t_reservations 
                inner join t_parking_lots 
                    on t_parking_lots.parking_lot_id = t_reservations.parking_lot_id 
                inner join t_parking_status 
                    on t_parking_status.reservation_id = t_reservations.reservation_id 
                inner join t_reservation_details
                on t_reservation_details.reservation_id = t_reservations.reservation_id
            where
                t_reservations.user_id = $1 
                and t_reservations.status = '4' 
            order by
                t_reservations.updated_datetime desc
        ";

        let res: Vec<ParkingUseHistoryResponse> = sqlx::query_as::<_, ParkingUseHistoryResponse>(sql)
            .bind(&req.user_id)
            .fetch_all(&self.pool)
            .await
            .map_err(|e| match e {
                sqlx::Error::RowNotFound => {
                    ApiError::NotFoundError("駐車場利用履歴が見つかりません".into())
                }
                _ => {
                    error!("Database error: {:?}", e);
                    ApiError::DatabaseError(format!("駐車場利用履歴の取得に失敗しました: {}", e))
                }
            })?;

        Ok(res)
    }

    /// 駐車場特徴の取得
    pub async fn get_parking_features(&self, req: &ParkingFeatureRequest) -> Result<Vec<ParkingFeatureResponse>, ApiError> {
        debug!("Fetching m_parking_features by parking_lot_id: {} ", req.parking_lot_id);

        let sql = "
            select
                m_parking_features.feature_id
                , m_parking_features.feature_type
                , m_parking_features.feature_value
                , m_parking_features.created_datetime
                , m_parking_features.updated_datetime 
            from
                m_parking_features 
            where
                m_parking_features.parking_lot_id = $1
            order by
                m_parking_features.updated_datetime desc
        ";

        let res: Vec<ParkingFeatureResponse> = sqlx::query_as::<_, ParkingFeatureResponse>(sql)
            .bind(&req.parking_lot_id)
            .fetch_all(&self.pool)
            .await
            .map_err(|e| match e {
                sqlx::Error::RowNotFound => {
                    ApiError::NotFoundError("駐車場特徴が見つかりません".into())
                }
                _ => {
                    error!("Database error: {:?}", e);
                    ApiError::DatabaseError(format!("駐車場特徴の取得に失敗しました: {}", e))
                }
            })?;

        Ok(res)
    }
    
}
