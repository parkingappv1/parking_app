
use chrono::Utc;
use crate::controllers::ApiError;
use crate::models::parking_lots_model::{ParkingImageRequest, ParkingLotRequest, ParkingLotRow};
use crate::config::postgresql_database::{DatabaseError, PostgresDatabase};
use crate::repositories::ParkingLotsRepository;
use tracing::error;

pub struct ParkingLotsService {
    repository: ParkingLotsRepository,
}

impl ParkingLotsService {
    /// 新しいサービスインスタンスを作成
    pub fn new(db: PostgresDatabase) -> Self {
        let repository = ParkingLotsRepository::new(db);
        Self { repository }
    }

    pub async fn register_parking_lot(&self, req: ParkingLotRequest) -> Result<ParkingLotRow, ApiError> {
        // 开启事务
        let mut tx = self.repository.begin_transaction().await?;

        let now = Utc::now();

        // 插入主表，拿回新插入的 parking_lot_id
        let parking_lot_row = self.repository.insert_parking_lot(&mut tx, &req, now).await?;

        // 插入关联的车辆限制
        if let Some(limit) = &req.limits {
            self.repository.insert_vehicle_limits(&mut tx, parking_lot_row.parking_lot_id.clone(), limit, now).await?;
        }

        // 插入车辆类型
        if let Some(types) = &req.vehicle_types {
            self.repository.insert_vehicle_types(&mut tx, parking_lot_row.parking_lot_id.clone(), types, now).await?;
        }

        // 提交事务
        tx.commit().await.map_err(|e| {
            error!("トランザクションコミットに失敗: {}", e);
            DatabaseError::TransactionError(format!("トランザクションコミットに失敗: {}", e))
        })?;

        Ok(parking_lot_row)
    }

    pub async fn upload_parking_lot_images(
        &self,
        req_list: &Vec<ParkingImageRequest>,
    ) -> Result<(), ApiError> {
        if req_list.is_empty() {
            return Err(ApiError::BadRequest("画像リストが空です".to_string()));
        }

        // 开启事务
        let mut tx = self.repository.begin_transaction().await?;

        let now = Utc::now();

        // 插入多张图片
        self.repository
            .insert_parking_images(&mut tx, &req_list, now)
            .await?;

        // 提交事务
        tx.commit().await.map_err(|e| {
            error!("トランザクションコミットに失敗: {}", e);
            DatabaseError::TransactionError(format!("トランザクションコミットに失敗: {}", e))
        })?;

        Ok(())
    }

}
