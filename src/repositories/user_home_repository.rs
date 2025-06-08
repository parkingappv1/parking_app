use crate::controllers::api_error::ApiError;
use crate::models::{
    parking_status_model::{ParkingStatusResponse, ParkingStatusRequest},
    parking_search_history_model::{ParkingSearchHistoryRequest, ParkingSearchHistoryResponse},
    favorites_model:: {FavoriteResponse, FavoritesRequest}
    
};
use sqlx::{postgres::PgPool};
use tracing::{debug, error};

pub struct UserHomeRepository {
    pool: PgPool,
}

impl UserHomeRepository {
    /// Create a new UserHomeRepository with the given database pool
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    /// 入出庫状況の取得
    pub async fn get_parking_status(&self, req: &ParkingStatusRequest) -> Result<ParkingStatusResponse, ApiError> {
        debug!("Fetching t_parking_status by user_id: {} status : {}", req.user_id, req.status);

        let sql = "
            select
                t_parking_status.status_id
                , t_parking_status.reservation_id
                , t_parking_status.parking_lot_id
                , t_parking_lots.parking_lot_name
                , t_parking_status.entry_status
                , t_parking_status.exit_status
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
                , t_parking_status.created_datetime
                , t_parking_status.updated_datetime 
            from
                t_reservations 
                inner join t_parking_lots 
                    on t_parking_lots.parking_lot_id = t_reservations.parking_lot_id 
                inner join t_parking_status 
                    on t_parking_status.reservation_id = t_reservations.reservation_id 
            where
                t_reservations.user_id = $1 
                and t_reservations.status = $2 
            order by
                t_reservations.start_datetime 
            limit
                1
        ";

        let res = sqlx::query_as::<_, ParkingStatusResponse>(sql)
            .bind(&req.user_id)
            .bind(&req.status)
            .fetch_one(&self.pool)
            .await
            .map_err(|e| match e {
                sqlx::Error::RowNotFound => {
                    ApiError::NotFoundError("入出庫状況が見つかりません".into())
                }
                _ => {
                    error!("Database error: {:?}", e);
                    ApiError::DatabaseError(format!("入出庫状況の取得に失敗しました: {}", e))
                }
            })?;

        Ok(res)
    }

    /// 駐車場検索履歴の取得
    pub async fn get_parking_search_history(&self, req: &ParkingSearchHistoryRequest) -> Result<Vec<ParkingSearchHistoryResponse>, ApiError> {
        debug!("Fetching t_parking_search_history by user_id: {} ", req.user_id);

        let sql = "
            select
                t_parking_search_history.search_id
                , t_parking_search_history.user_id
                , COALESCE(t_parking_search_history.parking_lot_id, '') as parking_lot_id
                , COALESCE(t_parking_lots.parking_lot_name, '') as parking_lot_name
                , COALESCE( 
                    t_parking_search_history.condition_keyword_free
                    , '-'
                ) as condition_keyword_free
                , COALESCE( 
                    t_parking_search_history.condition_use_date_start
                    , '-'
                ) as condition_use_date_start
                , COALESCE( 
                    t_parking_search_history.condition_use_date_end
                    , '-'
                ) as condition_use_date_end
                , COALESCE( 
                    t_parking_search_history.condition_vehicle_type_id
                    , '-'
                ) as condition_vehicle_type_id
                , COALESCE(m_parking_vehicle_types.vehicle_type, '-') as vehicle_type
                , COALESCE( 
                    t_parking_search_history.condition_rental_type_id
                    , ''
                ) as condition_rental_type_id
                , COALESCE(t_parking_rental_types.rental_type, '-') as rental_type
                , COALESCE( 
                    t_parking_rental_types.rental_value
                    , '-'
                ) as rental_value 
                , t_parking_search_history.created_datetime
                , t_parking_search_history.updated_datetime
            from
                t_parking_search_history 
                left join t_parking_lots 
                    on t_parking_lots.parking_lot_id = t_parking_search_history.parking_lot_id 
                left join m_parking_vehicle_types 
                    on m_parking_vehicle_types.vehicle_type_id = t_parking_search_history.condition_vehicle_type_id 
                left join t_parking_rental_types 
                    on t_parking_rental_types.rental_type_id = t_parking_search_history.condition_rental_type_id 
            where
                t_parking_search_history.user_id = $1 
            order by
                t_parking_search_history.created_datetime desc 
            limit
                5
        ";

        let res: Vec<ParkingSearchHistoryResponse> = sqlx::query_as::<_, ParkingSearchHistoryResponse>(sql)
            .bind(&req.user_id)
            .fetch_all(&self.pool)
            .await
            .map_err(|e| match e {
                sqlx::Error::RowNotFound => {
                    ApiError::NotFoundError("駐車場検索履歴が見つかりません".into())
                }
                _ => {
                    error!("Database error: {:?}", e);
                    ApiError::DatabaseError(format!("駐車場検索履歴の取得に失敗しました: {}", e))
                }
            })?;

        Ok(res)
    }

    /// お気に入りの取得
    pub async fn get_favorites(&self, req: &FavoritesRequest) -> Result<Vec<FavoriteResponse>, ApiError> {
        debug!("Fetching t_favorites by user_id: {} ", req.user_id);

        let sql = "
            select
                t_favorites.favorite_id
                , t_favorites.user_id
                , t_favorites.parking_lot_id
                , t_parking_lots.parking_lot_name
                , t_parking_lots.nearest_station
                , t_parking_lots.charge
                , t_favorites.created_datetime
                , t_favorites.updated_datetime
            from
                t_favorites 
                inner join t_parking_lots 
                    on t_parking_lots.parking_lot_id = t_favorites.parking_lot_id
            where
                t_favorites.user_id = $1 
            order by
                t_favorites.created_datetime desc 
            limit
                5
        ";

        let res: Vec<FavoriteResponse> = sqlx::query_as::<_, FavoriteResponse>(sql)
            .bind(&req.user_id)
            .fetch_all(&self.pool)
            .await
            .map_err(|e| match e {
                sqlx::Error::RowNotFound => {
                    ApiError::NotFoundError("お気に入りが見つかりません".into())
                }
                _ => {
                    error!("Database error: {:?}", e);
                    ApiError::DatabaseError(format!("お気に入りの取得に失敗しました: {}", e))
                }
            })?;

        Ok(res)
    }

    /// 入庫の更新
    pub async fn update_parking_status_checkin(
        &self,
        status_id: &String,
    ) -> Result<(), ApiError> {
        debug!("update_parking_status_checkin status_id: {}", status_id);

        let sql = "
            UPDATE t_parking_status 
            SET
                entry_datetime = now()
                , entry_status = '1'
                , updated_datetime = now() 
            WHERE
                status_id = $1
        ";

        sqlx::query(sql)
            .bind(status_id)
            .execute(&self.pool)
            .await
            .map_err(|e| {
                error!("Database error: {:?}", e);
                ApiError::DatabaseError(format!("入庫の更新に失敗しました: {}", e))
            })?;

        Ok(())
    }

     /// 出庫の更新
    pub async fn update_parking_status_checkout(
        &self,
        status_id: &String,
    ) -> Result<(), ApiError> {
        debug!("update_parking_status_checkout status_id: {}", status_id);

        let sql = "
            UPDATE t_parking_status 
            SET
                exit_datetime = now()
                , exit_status = '1'
                , updated_datetime = now() 
            WHERE
                status_id = $1
        ";

        sqlx::query(sql)
            .bind(status_id)
            .execute(&self.pool)
            .await
            .map_err(|e| {
                error!("Database error: {:?}", e);
                ApiError::DatabaseError(format!("出庫の更新に失敗しました: {}", e))
            })?;

        Ok(())
    }

     /// 予約ステータスの更新
    pub async fn update_reservation_status(
        &self,
        reservation_id: &String,
    ) -> Result<(), ApiError> {
        debug!("update_parking_status_checkout status_id: {}", reservation_id);

        let sql = "
            UPDATE t_reservations 
            SET
                status = '4'
                , updated_datetime = now() 
            WHERE
                reservation_id = $1
        ";

        sqlx::query(sql)
            .bind(reservation_id)
            .execute(&self.pool)
            .await
            .map_err(|e| {
                error!("Database error: {:?}", e);
                ApiError::DatabaseError(format!("予約ステータスの更新に失敗しました: {}", e))
            })?;

        Ok(())
    }


    
}
