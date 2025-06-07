use chrono::Utc;
use tracing::{error, info, instrument, warn};
use uuid::Uuid;

use crate::{
    config::logging::{log_sql_error, log_sql_query, SqlParam},
    config::postgresql_database::{DatabaseError, PostgresDatabase},
    models::{
        parking_search_model::ParkingSearchRequest,
        t_parking_lots_model::TParkingLotsModel,
        t_parking_google_maps_model::TParkingGoogleMapsModel,
        t_parking_rental_types_model::TParkingRentalTypesModel,
        m_parking_vehicle_types_model::MParkingVehicleTypesModel,
        m_parking_features_model::MParkingFeaturesModel,
    },
};

/// 駐車場検索用の結果行構造体
#[derive(Debug, sqlx::FromRow)]
pub struct ParkingLotRow {
    pub parking_lot_id: String,
    pub owner_id: String,
    pub parking_lot_name: String,
    pub postal_code: String,
    pub prefecture: String,
    pub city: String,
    pub address_detail: String,
    pub phone_number: String,
    pub capacity: i32,
    pub available_capacity: Option<i32>,
    pub rental_type: Option<String>,
    pub charge: String,
    pub features_tip: Option<String>,
    pub nearest_station: Option<String>,
    pub status: String,
    pub start_date: chrono::DateTime<Utc>,
    pub end_date: Option<chrono::DateTime<Utc>>,
    pub created_datetime: chrono::DateTime<Utc>,
    pub updated_datetime: chrono::DateTime<Utc>,
}

#[derive(Debug, sqlx::FromRow)]
pub struct GoogleMapsRow {
    pub google_maps_id: String,
    pub parking_lot_id: String,
    pub latitude: Option<f64>,
    pub longitude: Option<f64>,
    pub place_id: Option<String>,
    pub zoom_level: Option<i32>,
    pub map_type: Option<String>,
    pub google_maps_url: Option<String>,
    pub google_maps_embed: Option<String>,
    pub description: Option<String>,
}

#[derive(Debug, sqlx::FromRow)]
pub struct ParkingFeatureRow {
    pub feature_id: String,
    pub parking_lot_id: String,
    pub feature_type: String,
    pub feature_value: String,
}

#[derive(Debug, sqlx::FromRow)]
pub struct VehicleTypeRow {
    pub vehicle_type_id: String,
    pub parking_lot_id: String,
    pub vehicle_type: String,
}

#[derive(Debug, sqlx::FromRow)]
pub struct RentalTypeRow {
    pub rental_type_id: String,
    pub parking_lot_id: String,
    pub rental_type: String,
    pub rental_value: String,
}

#[derive(Debug, sqlx::FromRow)]
pub struct FavoriteRow {
    pub favorite_id: String,
    pub user_id: String,
    pub parking_lot_id: String,
    pub created_datetime: chrono::DateTime<Utc>,
}

#[derive(Debug, sqlx::FromRow)]
pub struct FavoriteCountRow {
    pub count: i64,
}

#[derive(Debug, sqlx::FromRow)]
pub struct SearchCountRow {
    pub total_count: i64,
}

#[derive(Debug, sqlx::FromRow)]
pub struct ExistsRow {
    pub exists: bool,
}

#[derive(Debug, sqlx::FromRow)]
pub struct ParkingLotDetailRow {
    pub parking_lot_id: String,
    pub owner_id: String,
    pub parking_lot_name: String,
    pub postal_code: String,
    pub prefecture: String,
    pub city: String,
    pub address_detail: String,
    pub phone_number: String,
    pub capacity: i32,
    pub available_capacity: Option<i32>,
    pub rental_type: Option<String>,
    pub charge: String,
    pub features_tip: Option<String>,
    pub nearest_station: Option<String>,
    pub status: String,
    pub start_date: chrono::DateTime<Utc>,
    pub end_date: Option<chrono::DateTime<Utc>>,
    pub created_datetime: chrono::DateTime<Utc>,
    pub updated_datetime: chrono::DateTime<Utc>,
}

/// 駐車場検索リポジトリ（最適化版）
/// 
/// auth_signup_repositoryのパターンに従って最適化された実装:
/// - トランザクションベースの操作
/// - 包括的なログ記録とSQLクエリ追跡
/// - 構造化されたエラーハンドリングと詳細なエラーマッピング
/// - 一貫したメソッドパターンとインストルメンテーション
/// - 入力検証とリソース存在確認
#[derive(Debug, Clone)]
pub struct ParkingSearchRepository {
    db: PostgresDatabase,
}

impl ParkingSearchRepository {
    /// 新しいリポジトリインスタンスを作成
    pub fn new(db: PostgresDatabase) -> Self {
        Self { db }
    }

    // =============================================================================
    // 駐車場検索メソッド
    // =============================================================================

    /// 位置情報と条件による駐車場検索
    #[instrument(skip(self))]
    pub async fn search_parking_lots_by_location(
        &self,
        criteria: &ParkingSearchRequest,
    ) -> Result<Vec<(TParkingLotsModel, Vec<TParkingRentalTypesModel>, Vec<MParkingVehicleTypesModel>, Vec<MParkingFeaturesModel>, Option<TParkingGoogleMapsModel>)>, DatabaseError> {
        info!("位置情報による駐車場検索を開始 - ユーザーID: {:?}", criteria.user_id);

        let query = r#"
            SELECT 
                pl.parking_lot_id,
                pl.owner_id,
                pl.parking_lot_name,
                pl.postal_code,
                pl.prefecture,
                pl.city,
                pl.address_detail,
                pl.phone_number,
                pl.capacity,
                pl.available_capacity,
                pl.rental_type,
                pl.charge,
                pl.features_tip,
                pl.nearest_station,
                pl.status,
                pl.start_date,
                pl.end_date,
                pl.created_datetime,
                pl.updated_datetime
            FROM t_parking_lots pl
            WHERE pl.status = $1
            ORDER BY pl.created_datetime DESC
            LIMIT $2
        "#;

        let params = vec![
            SqlParam::String("アクティブ".to_string()),
            SqlParam::Integer(100),
        ];
        
        log_sql_query(query, &params, None);

        match sqlx::query_as::<_, ParkingLotRow>(query)
            .bind("アクティブ")
            .bind(100_i64)
            .fetch_all(self.db.pool())
            .await
        {
            Ok(rows) => {
                info!("駐車場検索完了 - 結果数: {}", rows.len());
                
                let mut results = Vec::new();
                for row in rows {
                    let parking_lot = self.row_to_parking_lot(row)?;
                    
                    // 関連データを並行して取得
                    let (rental_types, vehicle_types, features, google_maps) = tokio::try_join!(
                        self.get_rental_types_by_parking_lot_id(&parking_lot.parking_lot_id),
                        self.get_vehicle_types_by_parking_lot_id(&parking_lot.parking_lot_id),
                        self.get_features_by_parking_lot_id(&parking_lot.parking_lot_id),
                        self.get_google_maps_by_parking_lot_id(&parking_lot.parking_lot_id)
                    )?;
                    
                    results.push((parking_lot, rental_types, vehicle_types, features, google_maps));
                }

                info!("駐車場検索処理完了 - 最終結果数: {}", results.len());
                Ok(results)
            }
            Err(e) => {
                error!("駐車場検索に失敗: {}", e);
                log_sql_error(query, &params, &e.to_string());
                Err(DatabaseError::QueryError(format!(
                    "駐車場検索に失敗: {}",
                    e
                )))
            }
        }
    }

    /// 駐車場詳細取得
    #[instrument(skip(self))]
    pub async fn get_parking_lot_detail(
        &self,
        parking_lot_id: &str,
    ) -> Result<Option<(TParkingLotsModel, Vec<TParkingRentalTypesModel>, Vec<MParkingVehicleTypesModel>, Vec<MParkingFeaturesModel>, Option<TParkingGoogleMapsModel>)>, DatabaseError> {
        info!("駐車場詳細取得を開始 - ID: {}", parking_lot_id);

        // 入力検証
        if parking_lot_id.trim().is_empty() {
            warn!("無効な駐車場ID: 空文字列");
            return Err(DatabaseError::QueryError("駐車場IDが空です".to_string()));
        }

        let query = r#"
            SELECT 
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
                status,
                start_date,
                end_date,
                created_datetime,
                updated_datetime
            FROM t_parking_lots 
            WHERE parking_lot_id = $1 AND status = $2
        "#;

        let params = vec![
            SqlParam::String(parking_lot_id.to_string()),
            SqlParam::String("アクティブ".to_string()),
        ];

        log_sql_query(query, &params, None);

        match sqlx::query_as::<_, ParkingLotDetailRow>(query)
            .bind(parking_lot_id)
            .bind("アクティブ")
            .fetch_optional(self.db.pool())
            .await
        {
            Ok(Some(row)) => {
                info!("駐車場詳細取得成功 - 名前: {}", row.parking_lot_name);
                
                let parking_lot = self.detail_row_to_parking_lot(row)?;
                
                // 関連データを並行して取得
                let (rental_types, vehicle_types, features, google_maps) = tokio::try_join!(
                    self.get_rental_types_by_parking_lot_id(&parking_lot.parking_lot_id),
                    self.get_vehicle_types_by_parking_lot_id(&parking_lot.parking_lot_id),
                    self.get_features_by_parking_lot_id(&parking_lot.parking_lot_id),
                    self.get_google_maps_by_parking_lot_id(&parking_lot.parking_lot_id)
                )?;
                
                Ok(Some((parking_lot, rental_types, vehicle_types, features, google_maps)))
            }
            Ok(None) => {
                warn!("駐車場が見つかりません - ID: {}", parking_lot_id);
                Ok(None)
            }
            Err(e) => {
                error!("駐車場詳細取得に失敗: {}", e);
                log_sql_error(query, &params, &e.to_string());
                Err(DatabaseError::QueryError(format!(
                    "駐車場詳細取得に失敗: {}",
                    e
                )))
            }
        }
    }

    // =============================================================================
    // お気に入り操作メソッド（トランザクションベース）
    // =============================================================================

    /// お気に入り追加
    #[instrument(skip(self))]
    pub async fn add_to_favorites(
        &self,
        user_id: &str,
        parking_lot_id: &str,
    ) -> Result<bool, DatabaseError> {
        info!("お気に入り追加を開始 - ユーザーID: {}, 駐車場ID: {}", user_id, parking_lot_id);

        // 入力検証
        self.validate_favorite_inputs(user_id, parking_lot_id).await?;

        // 重複チェック
        if self.check_favorite_exists(user_id, parking_lot_id).await? {
            warn!("お気に入りは既に存在します - ユーザーID: {}, 駐車場ID: {}", user_id, parking_lot_id);
            return Err(DatabaseError::QueryError(
                "この駐車場は既にお気に入りに登録されています".to_string()
            ));
        }

        let mut tx = self.begin_transaction().await?;

        let favorite_id = Uuid::new_v4().to_string();
        let now = Utc::now();

        let query = r#"
            INSERT INTO t_favorites 
            (favorite_id, user_id, parking_lot_id, created_datetime, updated_datetime)
            VALUES ($1, $2, $3, $4, $5)
        "#;

        let params = vec![
            SqlParam::String(favorite_id.clone()),
            SqlParam::String(user_id.to_string()),
            SqlParam::String(parking_lot_id.to_string()),
            SqlParam::String(now.to_rfc3339()),
            SqlParam::String(now.to_rfc3339()),
        ];

        log_sql_query(query, &params, None);

        match sqlx::query(query)
            .bind(&favorite_id)
            .bind(user_id)
            .bind(parking_lot_id)
            .bind(now)
            .bind(now)
            .execute(&mut *tx)
            .await
        {
            Ok(result) => {
                if result.rows_affected() > 0 {
                    self.commit_transaction(tx).await?;
                    info!("お気に入り追加成功 - ID: {}", favorite_id);
                    Ok(true)
                } else {
                    let _ = tx.rollback().await;
                    error!("お気に入り追加失敗 - 行が影響を受けませんでした");
                    Err(DatabaseError::QueryError(
                        "お気に入り追加に失敗しました".to_string()
                    ))
                }
            }
            Err(e) => {
                let _ = tx.rollback().await;
                error!("お気に入り追加クエリ実行に失敗: {}", e);
                log_sql_error(query, &params, &e.to_string());
                Err(DatabaseError::QueryError(format!(
                    "お気に入り追加に失敗: {}",
                    e
                )))
            }
        }
    }

    /// お気に入り削除
    #[instrument(skip(self))]
    pub async fn remove_from_favorites(
        &self,
        user_id: &str,
        parking_lot_id: &str,
    ) -> Result<bool, DatabaseError> {
        info!("お気に入り削除を開始 - ユーザーID: {}, 駐車場ID: {}", user_id, parking_lot_id);

        // 入力検証
        self.validate_favorite_inputs(user_id, parking_lot_id).await?;

        // 存在チェック
        if !self.check_favorite_exists(user_id, parking_lot_id).await? {
            warn!("削除対象のお気に入りが存在しません - ユーザーID: {}, 駐車場ID: {}", user_id, parking_lot_id);
            return Ok(false);
        }

        let mut tx = self.begin_transaction().await?;

        let query = r#"
            DELETE FROM t_favorites 
            WHERE user_id = $1 AND parking_lot_id = $2
        "#;

        let params = vec![
            SqlParam::String(user_id.to_string()),
            SqlParam::String(parking_lot_id.to_string()),
        ];

        log_sql_query(query, &params, None);

        match sqlx::query(query)
            .bind(user_id)
            .bind(parking_lot_id)
            .execute(&mut *tx)
            .await
        {
            Ok(result) => {
                let affected = result.rows_affected();
                if affected > 0 {
                    self.commit_transaction(tx).await?;
                    info!("お気に入り削除成功 - 削除件数: {}", affected);
                    Ok(true)
                } else {
                    let _ = tx.rollback().await;
                    warn!("お気に入り削除失敗 - 対象が見つかりませんでした");
                    Ok(false)
                }
            }
            Err(e) => {
                let _ = tx.rollback().await;
                error!("お気に入り削除クエリ実行に失敗: {}", e);
                log_sql_error(query, &params, &e.to_string());
                Err(DatabaseError::QueryError(format!(
                    "お気に入り削除に失敗: {}",
                    e
                )))
            }
        }
    }

    /// お気に入り存在確認
    #[instrument(skip(self))]
    pub async fn check_favorite_exists(
        &self,
        user_id: &str,
        parking_lot_id: &str,
    ) -> Result<bool, DatabaseError> {
        let query = "SELECT EXISTS(SELECT 1 FROM t_favorites WHERE user_id = $1 AND parking_lot_id = $2)";
        let params = vec![
            SqlParam::String(user_id.to_string()),
            SqlParam::String(parking_lot_id.to_string()),
        ];

        log_sql_query(query, &params, None);

        match sqlx::query_as::<_, ExistsRow>(query)
            .bind(user_id)
            .bind(parking_lot_id)
            .fetch_one(self.db.pool())
            .await
        {
            Ok(row) => {
                let exists = row.exists;
                info!("お気に入り存在確認完了 - 存在: {}", exists);
                Ok(exists)
            }
            Err(e) => {
                error!("お気に入り存在確認に失敗: {}", e);
                log_sql_error(query, &params, &e.to_string());
                Err(DatabaseError::QueryError(format!(
                    "お気に入り存在確認に失敗: {}",
                    e
                )))
            }
        }
    }

    /// ユーザーのお気に入り駐車場IDリストを取得
    #[instrument(skip(self))]
    pub async fn get_user_favorites(
        &self,
        user_id: &str,
    ) -> Result<Vec<String>, DatabaseError> {
        info!("ユーザーお気に入り一覧取得を開始 - ユーザーID: {}", user_id);

        // 入力検証
        if user_id.trim().is_empty() {
            warn!("無効なユーザーID: 空文字列");
            return Err(DatabaseError::QueryError("ユーザーIDが空です".to_string()));
        }

        let query = r#"
            SELECT parking_lot_id 
            FROM t_favorites 
            WHERE user_id = $1 
            ORDER BY created_datetime DESC
        "#;
        
        let params = vec![SqlParam::String(user_id.to_string())];

        log_sql_query(query, &params, None);

        match sqlx::query_as::<_, FavoriteRow>(query)
            .bind(user_id)
            .fetch_all(self.db.pool())
            .await
        {
            Ok(rows) => {
                let favorite_ids: Vec<String> = rows.into_iter().map(|row| row.parking_lot_id).collect();
                info!("ユーザーお気に入り取得完了 - 件数: {}", favorite_ids.len());
                Ok(favorite_ids)
            }
            Err(e) => {
                error!("ユーザーお気に入り取得に失敗: {}", e);
                log_sql_error(query, &params, &e.to_string());
                Err(DatabaseError::QueryError(format!(
                    "ユーザーお気に入り取得に失敗: {}",
                    e
                )))
            }
        }
    }

    /// ユーザーのお気に入り件数を取得
    #[instrument(skip(self))]
    pub async fn get_user_favorites_count(
        &self,
        user_id: &str,
    ) -> Result<i64, DatabaseError> {
        info!("ユーザーお気に入り件数取得を開始 - ユーザーID: {}", user_id);

        // 入力検証
        if user_id.trim().is_empty() {
            warn!("無効なユーザーID: 空文字列");
            return Err(DatabaseError::QueryError("ユーザーIDが空です".to_string()));
        }

        let query = "SELECT COUNT(*) as count FROM t_favorites WHERE user_id = $1";
        let params = vec![SqlParam::String(user_id.to_string())];

        log_sql_query(query, &params, None);

        match sqlx::query_as::<_, FavoriteCountRow>(query)
            .bind(user_id)
            .fetch_one(self.db.pool())
            .await
        {
            Ok(row) => {
                info!("ユーザーお気に入り件数取得完了 - 件数: {}", row.count);
                Ok(row.count)
            }
            Err(e) => {
                error!("ユーザーお気に入り件数取得に失敗: {}", e);
                log_sql_error(query, &params, &e.to_string());
                Err(DatabaseError::QueryError(format!(
                    "ユーザーお気に入り件数取得に失敗: {}",
                    e
                )))
            }
        }
    }

    /// お気に入り駐車場取得（ページネーション対応）
    #[instrument(skip(self))]
    pub async fn get_favorite_parking_lots(
        &self,
        user_id: &str,
        page: i32,
        page_size: i32,
    ) -> Result<Vec<(TParkingLotsModel, Vec<TParkingRentalTypesModel>, Vec<MParkingVehicleTypesModel>, Vec<MParkingFeaturesModel>, Option<TParkingGoogleMapsModel>)>, DatabaseError> {
        info!("お気に入り駐車場取得を開始 - ユーザーID: {}, ページ: {}, サイズ: {}", user_id, page, page_size);

        // 入力検証
        if user_id.trim().is_empty() {
            warn!("無効なユーザーID: 空文字列");
            return Err(DatabaseError::QueryError("ユーザーIDが空です".to_string()));
        }

        if page < 1 {
            warn!("無効なページ番号: {}", page);
            return Err(DatabaseError::QueryError("ページ番号は1以上である必要があります".to_string()));
        }

        if page_size < 1 || page_size > 100 {
            warn!("無効なページサイズ: {}", page_size);
            return Err(DatabaseError::QueryError("ページサイズは1-100の範囲で指定してください".to_string()));
        }

        let offset = (page - 1) * page_size;
        
        let query = r#"
            SELECT 
                pl.parking_lot_id,
                pl.owner_id,
                pl.parking_lot_name,
                pl.postal_code,
                pl.prefecture,
                pl.city,
                pl.address_detail,
                pl.phone_number,
                pl.capacity,
                pl.available_capacity,
                pl.rental_type,
                pl.charge,
                pl.features_tip,
                pl.nearest_station,
                pl.status,
                pl.start_date,
                pl.end_date,
                pl.created_datetime,
                pl.updated_datetime
            FROM t_parking_lots pl
            INNER JOIN t_favorites fav ON pl.parking_lot_id = fav.parking_lot_id
            WHERE fav.user_id = $1 AND pl.status = $2
            ORDER BY fav.created_datetime DESC
            LIMIT $3 OFFSET $4
        "#;

        let params = vec![
            SqlParam::String(user_id.to_string()),
            SqlParam::String("アクティブ".to_string()),
            SqlParam::Integer(page_size as i64),
            SqlParam::Integer(offset as i64),
        ];

        log_sql_query(query, &params, None);

        match sqlx::query_as::<_, ParkingLotRow>(query)
            .bind(user_id)
            .bind("アクティブ")
            .bind(page_size as i64)
            .bind(offset as i64)
            .fetch_all(self.db.pool())
            .await
        {
            Ok(rows) => {
                info!("お気に入り駐車場取得完了 - 結果数: {}", rows.len());
                
                let mut results = Vec::new();
                for row in rows {
                    let parking_lot = self.row_to_parking_lot(row)?;
                    
                    // 関連データを並行して取得
                    let (rental_types, vehicle_types, features, google_maps) = tokio::try_join!(
                        self.get_rental_types_by_parking_lot_id(&parking_lot.parking_lot_id),
                        self.get_vehicle_types_by_parking_lot_id(&parking_lot.parking_lot_id),
                        self.get_features_by_parking_lot_id(&parking_lot.parking_lot_id),
                        self.get_google_maps_by_parking_lot_id(&parking_lot.parking_lot_id)
                    )?;
                    
                    results.push((parking_lot, rental_types, vehicle_types, features, google_maps));
                }

                info!("お気に入り駐車場処理完了 - 最終結果数: {}", results.len());
                Ok(results)
            }
            Err(e) => {
                error!("お気に入り駐車場取得に失敗: {}", e);
                log_sql_error(query, &params, &e.to_string());
                Err(DatabaseError::QueryError(format!(
                    "お気に入り駐車場取得に失敗: {}",
                    e
                )))
            }
        }
    }

    // =============================================================================
    // 関連データ取得メソッド
    // =============================================================================

    /// 駐車場IDによる貸出タイプ取得
    #[instrument(skip(self))]
    pub async fn get_rental_types_by_parking_lot_id(
        &self,
        parking_lot_id: &str,
    ) -> Result<Vec<TParkingRentalTypesModel>, DatabaseError> {
        let query = "SELECT * FROM t_parking_rental_types WHERE parking_lot_id = $1";
        let params = vec![SqlParam::String(parking_lot_id.to_string())];

        log_sql_query(query, &params, None);

        match sqlx::query_as::<_, RentalTypeRow>(query)
            .bind(parking_lot_id)
            .fetch_all(self.db.pool())
            .await
        {
            Ok(rows) => {
                let rental_types = rows.into_iter().map(|row| self.row_to_rental_type(row)).collect();
                Ok(rental_types)
            }
            Err(e) => {
                error!("貸出タイプ取得に失敗: {}", e);
                log_sql_error(query, &params, &e.to_string());
                Err(DatabaseError::QueryError(format!(
                    "貸出タイプ取得に失敗: {}",
                    e
                )))
            }
        }
    }

    /// 駐車場IDによる対応車種取得
    #[instrument(skip(self))]
    pub async fn get_vehicle_types_by_parking_lot_id(
        &self,
        parking_lot_id: &str,
    ) -> Result<Vec<MParkingVehicleTypesModel>, DatabaseError> {
        let query = "SELECT * FROM m_parking_vehicle_types WHERE parking_lot_id = $1";
        let params = vec![SqlParam::String(parking_lot_id.to_string())];

        log_sql_query(query, &params, None);

        match sqlx::query_as::<_, VehicleTypeRow>(query)
            .bind(parking_lot_id)
            .fetch_all(self.db.pool())
            .await
        {
            Ok(rows) => {
                let vehicle_types = rows.into_iter().map(|row| self.row_to_vehicle_type(row)).collect();
                Ok(vehicle_types)
            }
            Err(e) => {
                error!("対応車種取得に失敗: {}", e);
                log_sql_error(query, &params, &e.to_string());
                Err(DatabaseError::QueryError(format!(
                    "対応車種取得に失敗: {}",
                    e
                )))
            }
        }
    }

    /// 駐車場IDによる特徴取得
    #[instrument(skip(self))]
    pub async fn get_features_by_parking_lot_id(
        &self,
        parking_lot_id: &str,
    ) -> Result<Vec<MParkingFeaturesModel>, DatabaseError> {
        let query = "SELECT * FROM m_parking_features WHERE parking_lot_id = $1";
        let params = vec![SqlParam::String(parking_lot_id.to_string())];

        log_sql_query(query, &params, None);

        match sqlx::query_as::<_, ParkingFeatureRow>(query)
            .bind(parking_lot_id)
            .fetch_all(self.db.pool())
            .await
        {
            Ok(rows) => {
                let features = rows.into_iter().map(|row| self.row_to_feature(row)).collect();
                Ok(features)
            }
            Err(e) => {
                error!("駐車場特徴取得に失敗: {}", e);
                log_sql_error(query, &params, &e.to_string());
                Err(DatabaseError::QueryError(format!(
                    "駐車場特徴取得に失敗: {}",
                    e
                )))
            }
        }
    }

    /// 駐車場IDによるGoogle Maps情報取得
    #[instrument(skip(self))]
    pub async fn get_google_maps_by_parking_lot_id(
        &self,
        parking_lot_id: &str,
    ) -> Result<Option<TParkingGoogleMapsModel>, DatabaseError> {
        let query = "SELECT * FROM t_parking_google_maps WHERE parking_lot_id = $1";
        let params = vec![SqlParam::String(parking_lot_id.to_string())];

        log_sql_query(query, &params, None);

        match sqlx::query_as::<_, GoogleMapsRow>(query)
            .bind(parking_lot_id)
            .fetch_optional(self.db.pool())
            .await
        {
            Ok(Some(row)) => Ok(Some(self.row_to_google_maps(row))),
            Ok(None) => Ok(None),
            Err(e) => {
                error!("Google Maps情報取得に失敗: {}", e);
                log_sql_error(query, &params, &e.to_string());
                Err(DatabaseError::QueryError(format!(
                    "Google Maps情報取得に失敗: {}",
                    e
                )))
            }
        }
    }

    // =============================================================================
    // 駐車場存在確認メソッド
    // =============================================================================

    /// 駐車場存在確認
    #[instrument(skip(self))]
    pub async fn parking_lot_exists(&self, parking_lot_id: &str) -> Result<bool, DatabaseError> {
        let query = "SELECT EXISTS(SELECT 1 FROM t_parking_lots WHERE parking_lot_id = $1 AND status = $2)";
        let params = vec![
            SqlParam::String(parking_lot_id.to_string()),
            SqlParam::String("アクティブ".to_string()),
        ];

        log_sql_query(query, &params, None);

        match sqlx::query_as::<_, ExistsRow>(query)
            .bind(parking_lot_id)
            .bind("アクティブ")
            .fetch_one(self.db.pool())
            .await
        {
            Ok(row) => {
                let exists = row.exists;
                info!("駐車場存在確認完了 - ID: {}, 存在: {}", parking_lot_id, exists);
                Ok(exists)
            }
            Err(e) => {
                error!("駐車場存在確認に失敗: {}", e);
                log_sql_error(query, &params, &e.to_string());
                Err(DatabaseError::QueryError(format!(
                    "駐車場存在確認に失敗: {}",
                    e
                )))
            }
        }
    }

    // =============================================================================
    // プライベートヘルパーメソッド
    // =============================================================================

    /// トランザクションの開始
    async fn begin_transaction(&self) -> Result<sqlx::Transaction<'static, sqlx::Postgres>, DatabaseError> {
        self.db.pool().begin().await.map_err(|e| {
            error!("トランザクション開始に失敗: {}", e);
            DatabaseError::TransactionError(format!("トランザクション開始に失敗: {}", e))
        })
    }

    /// トランザクションのコミット
    async fn commit_transaction(&self, tx: sqlx::Transaction<'static, sqlx::Postgres>) -> Result<(), DatabaseError> {
        tx.commit().await.map_err(|e| {
            error!("トランザクションコミットに失敗: {}", e);
            DatabaseError::TransactionError(format!("トランザクションコミットに失敗: {}", e))
        })
    }

    /// お気に入り操作の入力検証
    async fn validate_favorite_inputs(&self, user_id: &str, parking_lot_id: &str) -> Result<(), DatabaseError> {
        // ユーザーID検証
        if user_id.trim().is_empty() {
            warn!("無効なユーザーID: 空文字列");
            return Err(DatabaseError::QueryError("ユーザーIDが空です".to_string()));
        }

        // 駐車場ID検証
        if parking_lot_id.trim().is_empty() {
            warn!("無効な駐車場ID: 空文字列");
            return Err(DatabaseError::QueryError("駐車場IDが空です".to_string()));
        }

        // 駐車場存在確認
        if !self.parking_lot_exists(parking_lot_id).await? {
            warn!("駐車場が存在しません - ID: {}", parking_lot_id);
            return Err(DatabaseError::QueryError(
                "指定された駐車場が存在しません".to_string()
            ));
        }

        Ok(())
    }

    // =============================================================================
    // 行データ変換メソッド
    // =============================================================================

    /// ParkingLotRow から TParkingLotsModel への変換
    fn row_to_parking_lot(&self, row: ParkingLotRow) -> Result<TParkingLotsModel, DatabaseError> {
        Ok(TParkingLotsModel {
            parking_lot_id: row.parking_lot_id,
            owner_id: row.owner_id,
            parking_lot_name: row.parking_lot_name,
            postal_code: row.postal_code,
            prefecture: row.prefecture,
            city: row.city,
            address_detail: row.address_detail,
            phone_number: row.phone_number,
            capacity: row.capacity,
            available_capacity: row.available_capacity,
            rental_type: row.rental_type,
            charge: row.charge,
            features_tip: row.features_tip,
            length_limit: None, // Add missing fields with None default
            width_limit: None,
            height_limit: None,
            weight_limit: None,
            car_height_limit: None,
            tire_width_limit: None,
            vehicle_type: None,
            nearest_station: row.nearest_station,
            status: row.status,
            start_date: Some(row.start_date.to_rfc3339()),
            end_date: row.end_date.map(|d| d.to_rfc3339()),
            end_start_datetime: None,
            end_end_datetime: None,
            end_reason: None,
            end_reason_detail: None,
            notes: None,
            created_datetime: Some(row.created_datetime.to_rfc3339()),
            updated_datetime: Some(row.updated_datetime.to_rfc3339()),
        })
    }

    /// ParkingLotDetailRow から TParkingLotsModel への変換
    fn detail_row_to_parking_lot(&self, row: ParkingLotDetailRow) -> Result<TParkingLotsModel, DatabaseError> {
        Ok(TParkingLotsModel {
            parking_lot_id: row.parking_lot_id,
            owner_id: row.owner_id,
            parking_lot_name: row.parking_lot_name,
            postal_code: row.postal_code,
            prefecture: row.prefecture,
            city: row.city,
            address_detail: row.address_detail,
            phone_number: row.phone_number,
            capacity: row.capacity,
            available_capacity: row.available_capacity,
            rental_type: row.rental_type,
            charge: row.charge,
            features_tip: row.features_tip,
            length_limit: None,
            width_limit: None,
            height_limit: None,
            weight_limit: None,
            car_height_limit: None,
            tire_width_limit: None,
            vehicle_type: None,
            nearest_station: row.nearest_station,
            status: row.status,
            start_date: Some(row.start_date.to_rfc3339()),
            end_date: row.end_date.map(|d| d.to_rfc3339()),
            end_start_datetime: None,
            end_end_datetime: None,
            end_reason: None,
            end_reason_detail: None,
            notes: None,
            created_datetime: Some(row.created_datetime.to_rfc3339()),
            updated_datetime: Some(row.updated_datetime.to_rfc3339()),
        })
    }

    /// RentalTypeRow から TParkingRentalTypesModel への変換
    fn row_to_rental_type(&self, row: RentalTypeRow) -> TParkingRentalTypesModel {
        TParkingRentalTypesModel {
            rental_type_id: row.rental_type_id,
            parking_lot_id: row.parking_lot_id,
            rental_type: row.rental_type,
            rental_value: row.rental_value,
            created_datetime: None, // Add missing fields
            updated_datetime: None,
        }
    }

    /// VehicleTypeRow から MParkingVehicleTypesModel への変換
    fn row_to_vehicle_type(&self, row: VehicleTypeRow) -> MParkingVehicleTypesModel {
        MParkingVehicleTypesModel {
            vehicle_type_id: row.vehicle_type_id,
            vehicle_type_name: row.vehicle_type, // Use vehicle_type as vehicle_type_name
            size_category: None,
            max_length_cm: None,
            max_width_cm: None,
            max_height_cm: None,
            display_order: None,
            description: None,
            is_active: true, // Default to active
            created_at: None,
            updated_at: None,
        }
    }

    /// ParkingFeatureRow から MParkingFeaturesModel への変換
    fn row_to_feature(&self, row: ParkingFeatureRow) -> MParkingFeaturesModel {
        MParkingFeaturesModel {
            feature_id: row.feature_id,
            feature_name: row.feature_type, // Use feature_type as feature_name
            feature_category: None,
            icon_name: None,
            display_order: None,
            description: Some(row.feature_value), // Use feature_value as description
            is_filterable: true,
            show_in_list: true,
            is_active: true,
            created_at: None,
            updated_at: None,
        }
    }

    /// GoogleMapsRow から TParkingGoogleMapsModel への変換
    fn row_to_google_maps(&self, row: GoogleMapsRow) -> TParkingGoogleMapsModel {
        TParkingGoogleMapsModel {
            google_maps_id: row.google_maps_id,
            parking_lot_id: row.parking_lot_id,
            latitude: row.latitude,
            longitude: row.longitude,
            place_id: row.place_id,
            zoom_level: row.zoom_level,
            map_type: row.map_type,
            google_maps_url: row.google_maps_url,
            google_maps_embed: row.google_maps_embed,
            description: row.description,
            created_datetime: None, // Add missing fields
            updated_datetime: None,
        }
    }
}
