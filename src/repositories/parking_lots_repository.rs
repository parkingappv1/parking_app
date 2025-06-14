use crate::config::logging::{log_sql_error, log_sql_query, SqlParam};
use crate::config::postgresql_database::{DatabaseError, PostgresDatabase};
use crate::models::parking_lots_model::{
    ParkingImageRequest, ParkingLimitRequest, ParkingLotRequest, ParkingLotRow, ParkingVehicleTypeRequest
};
use chrono::{DateTime, Utc};
use sqlx::{Postgres, Transaction};
use tracing::{error, info};
use uuid::Uuid;

#[derive(Debug, Clone)]
pub struct ParkingLotsRepository {
    db: PostgresDatabase,
}

impl ParkingLotsRepository {
    pub fn new(db: PostgresDatabase) -> Self {
        Self { db }
    }

    pub async fn begin_transaction(&self) -> Result<Transaction<'static, Postgres>, DatabaseError> {
        self.db.pool().begin().await.map_err(|e| {
            error!("トランザクション開始に失敗: {}", e);
            DatabaseError::TransactionError(format!("トランザクション開始に失敗: {}", e))
        })
    }

    /// t_parking_lotsレコードの挿入
    pub async fn insert_parking_lot(
        &self,
        tx: &mut sqlx::Transaction<'static, sqlx::Postgres>,
        req: &ParkingLotRequest,
        now: chrono::DateTime<Utc>,
    ) -> Result<ParkingLotRow, DatabaseError> {
        let sql: &'static str = r#"
            INSERT INTO t_parking_lots ( 
                parking_lot_id,
                owner_id,
                parking_lot_name,
                postal_code,
                prefecture,
                city,
                address_detail,
                phone_number,
                capacity,
                available_capacity,
                rental_type,
                charge,
                features_tip,
                nearest_station,
                latitude,
                longitude,
                status,
                start_date,
                end_date,
                end_start_datetime,
                end_end_datetime,
                end_reason,
                end_reason_detail,
                notes,
                created_datetime,
                updated_datetime
            ) 
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26) 
            RETURNING parking_lot_id,parking_lot_name;
        "#;

        let parking_lot_id = Uuid::new_v4().to_string();

        let params = vec![
            SqlParam::String(parking_lot_id.clone()),
            SqlParam::String(req.owner_id.clone()),
            SqlParam::String(req.parking_lot_name.clone()),
            SqlParam::String(req.postal_code.clone()),
            SqlParam::String(req.prefecture.clone()),
            SqlParam::String(req.city.clone()),
            SqlParam::String(req.address_detail.clone()),
            SqlParam::String(req.phone_number.clone()),
            SqlParam::I32(req.capacity.clone()),
            SqlParam::OptionI32(req.available_capacity.clone()),
            SqlParam::String(req.rental_type.clone()),
            SqlParam::String(req.charge.clone()),
            SqlParam::OptionString(req.features_tip.clone()),
            SqlParam::OptionString(req.nearest_station.clone()),
            SqlParam::String(req.latitude.clone()),
            SqlParam::String(req.longitude.clone()),
            SqlParam::String(req.status.clone()),
            SqlParam::Date(req.start_date.clone()),
            SqlParam::OptionDate(req.end_date.clone()),
            SqlParam::OptionDateTime(req.end_start_datetime.clone()),
            SqlParam::OptionDateTime(req.end_end_datetime.clone()),
            SqlParam::OptionString(req.end_reason.clone()),
            SqlParam::OptionString(req.end_reason_detail.clone()),
            SqlParam::OptionString(req.notes.clone()),
            SqlParam::OptionDateTime(Some(now)),
            SqlParam::OptionDateTime(Some(now)),
        ];

        log_sql_query(sql, &params, None);

        match sqlx::query_as::<_, ParkingLotRow>(sql)
            .bind(&parking_lot_id)
            .bind(&req.owner_id)
            .bind(&req.parking_lot_name)
            .bind(&req.postal_code)
            .bind(&req.prefecture)
            .bind(&req.city)
            .bind(&req.address_detail)
            .bind(&req.phone_number)
            .bind(&req.capacity)
            .bind(&req.available_capacity)
            .bind(&req.rental_type)
            .bind(&req.charge)
            .bind(req.features_tip.as_deref())
            .bind(&req.nearest_station)
            .bind(&req.latitude)
            .bind(&req.longitude)
            .bind(&req.status)
            .bind(&req.start_date)
            .bind(&req.end_date)
            .bind(&req.end_start_datetime)
            .bind(&req.end_end_datetime)
            .bind(&req.end_reason)
            .bind(&req.end_reason_detail)
            .bind(&req.notes)
            .bind(&now)
            .bind(&now)
            .fetch_one(&mut **tx)
            .await
        {
            Ok(row) => {
                info!("t_parking_lotsレコード挿入成功");
                Ok(row)
            }
            Err(e) => {
                error!("t_parking_lotsレコード挿入に失敗: {}", e);
                log_sql_error(sql, &params, &e.to_string());
                Err(DatabaseError::QueryError(format!(
                    "t_parking_lotsレコード挿入に失敗: {}",
                    e
                )))
            }
        }
    }


    pub async fn insert_vehicle_limits(
        &self,
        tx: &mut Transaction<'_, Postgres>,
        parking_lot_id: String,
        limit: &ParkingLimitRequest,
        now: DateTime<Utc>,
    ) -> Result<(), DatabaseError> {
        let sql = r#"
            INSERT INTO t_parking_limits (
                parking_lot_id, length_limit, width_limit, height_limit, weight_limit, car_height_limit, tire_width_limit, car_bottom_limit, created_datetime, updated_datetime
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
        "#;

        let params = vec![
            SqlParam::String(parking_lot_id.to_string()),
            SqlParam::OptionI32(limit.length_limit.clone()),
            SqlParam::OptionI32(limit.width_limit.clone()),
            SqlParam::OptionI32(limit.height_limit.clone()),
            SqlParam::OptionI32(limit.weight_limit.clone()),
            SqlParam::OptionString(limit.car_height_limit.clone()),
            SqlParam::OptionString(limit.tire_width_limit.clone()),
            SqlParam::OptionString(limit.car_bottom_limit.clone()),
            SqlParam::OptionDateTime(Some(now)),
            SqlParam::OptionDateTime(Some(now)),
        ];

        log_sql_query(sql, &params, None);

        match sqlx::query(sql)
            .bind(parking_lot_id)
            .bind(&limit.length_limit)
            .bind(&limit.width_limit)
            .bind(&limit.height_limit)
            .bind(&limit.weight_limit)
            .bind(&limit.car_height_limit)
            .bind(&limit.tire_width_limit)
            .bind(&limit.car_bottom_limit)
            .bind(&now)
            .bind(&now)
            .execute(&mut **tx)
            .await
        {
            Ok(_) => {
                info!("t_parking_limits レコード挿入成功");
                Ok(())
            }
            Err(e) => {
                error!("t_parking_limits レコード挿入失敗: {}", e);
                log_sql_error(sql, &params, &e.to_string());
                Err(DatabaseError::QueryError(e.to_string()))
            }
        }
    }


    pub async fn insert_vehicle_types(
        &self,
        tx: &mut Transaction<'_, Postgres>,
        parking_lot_id: String,
        types: &[ParkingVehicleTypeRequest],
        now: DateTime<Utc>,
    ) -> Result<(), DatabaseError> {
        let parking_lot_id_ref = &parking_lot_id;
        
        for vt in types {
            let sql = r#"
                INSERT INTO t_parking_vehicle_types (
                    parking_lot_id, vehicle_type, capacity, created_datetime,updated_datetime
                )
                VALUES ($1, $2, $3, $4, $5)
            "#;

            let params = vec![
                SqlParam::String(parking_lot_id_ref.clone()),
                SqlParam::String(vt.vehicle_type.clone()),
                SqlParam::I32(vt.capacity.clone()),
                SqlParam::OptionDateTime(Some(now)),
                SqlParam::OptionDateTime(Some(now)),
            ];

            log_sql_query(sql, &params, None);

            if let Err(e) = sqlx::query(sql)
                .bind(&parking_lot_id_ref)
                .bind(&vt.vehicle_type)
                .bind(&vt.capacity)
                .bind(&now)
                .bind(&now)
                .execute(&mut **tx)
                .await
            {
                error!("t_parking_vehicle_types レコード挿入失敗: {}", e);
                log_sql_error(sql, &params, &e.to_string());
                return Err(DatabaseError::QueryError(e.to_string()));
            }
        }

        info!("t_parking_vehicle_types 全件挿入成功");
        Ok(())
    }


    pub async fn insert_parking_images(
        &self,
        tx: &mut Transaction<'_, Postgres>,
        images: &[ParkingImageRequest],
        now: DateTime<Utc>,
    ) -> Result<(), DatabaseError> {

        for image in images {
            let sql = r#"
                INSERT INTO t_parking_images (
                    parking_lot_id, image_url, created_datetime, updated_datetime
                )
                VALUES ($1, $2, $3, $4)
            "#;

            let params = vec![
                SqlParam::String(image.parking_lot_id.clone()),
                SqlParam::String(image.image_url.clone()),
                SqlParam::OptionDateTime(Some(now)),
                SqlParam::OptionDateTime(Some(now)),
            ];

            log_sql_query(sql, &params, None);

            if let Err(e) = sqlx::query(sql)
                .bind(&image.parking_lot_id)
                .bind(&image.image_url)
                .bind(now)
                .bind(now)
                .execute(&mut **tx)
                .await
            {
                error!("t_parking_images レコード挿入失敗: {}", e);
                log_sql_error(sql, &params, &e.to_string());
                return Err(DatabaseError::QueryError(e.to_string()));
            }
        }

        info!("t_parking_images 全件挿入成功");
        Ok(())
    }

}
