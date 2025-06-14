use anyhow::{Context, Result};
use rand::Rng;
use sqlx::{
    Postgres, Transaction,
    postgres::{PgPool, PgPoolOptions, PgRow},
};
use std::{env, time::Duration};
use thiserror::Error;
use tokio::time::sleep;

#[derive(Error, Debug)]
pub enum DatabaseError {
    #[error("データベース接続エラー: {0}")]
    ConnectionError(String),

    #[error("クエリ実行エラー: {0}")]
    QueryError(String),

    #[error("トランザクションエラー: {0}")]
    TransactionError(String),

    #[error("データベースタイムアウトエラー")]
    TimeoutError,

    #[error("行が見つかりません")]
    RowNotFound,

    #[error("重複エラー: {}", _0)]
    DuplicateError(String),

    #[error("バリデーションエラー: {}", _0)]
    ValidationError(String),

    #[error("リソースが見つかりません: {}", _0)]
    NotFound(String),

    #[error("その他のエラー: {0}")]
    Other(String),  // <--- Add this
}

pub struct DatabaseConfig {
    pub host: String,
    pub port: u16,
    pub username: String,
    pub password: String,
    pub database_name: String,
    pub pool_size: u32,
    pub connection_timeout: u64,
    pub idle_timeout: u64,
    pub pool_timeout: u64,
    pub max_connections: u32,
}

impl DatabaseConfig {
    pub fn from_env() -> Result<Self> {
        Ok(Self {
            host: env::var("DB_HOST").unwrap_or_else(|_| "localhost".to_string()),
            port: env::var("DB_PORT")
                .unwrap_or_else(|_| "5432".to_string())
                .parse()
                .context("データベースポートの解析に失敗しました")?,
            username: env::var("DB_USERNAME").context("DB_USERNAMEが設定されていません")?,
            password: env::var("DB_PASSWORD").context("DB_PASSWORDが設定されていません")?,
            database_name: env::var("DB_INITIAL_DATABASE")
                .context("DB_INITIAL_DATABASEが設定されていません")?,
            pool_size: env::var("DB_CONNECTION_POOL_SIZE")
                .unwrap_or_else(|_| "10".to_string())
                .parse()
                .context("コネクションプールサイズの解析に失敗しました")?,
            connection_timeout: env::var("DB_CONNECTION_TIMEOUT")
                .unwrap_or_else(|_| "10".to_string())
                .parse()
                .context("コネクションタイムアウトの解析に失敗しました")?,
            idle_timeout: env::var("DB_IDLE_TIMEOUT")
                .unwrap_or_else(|_| "5".to_string())
                .parse()
                .context("アイドルタイムアウトの解析に失敗しました")?,
            pool_timeout: env::var("DB_POOL_TIMEOUT")
                .unwrap_or_else(|_| "30".to_string())
                .parse()
                .context("プールタイムアウトの解析に失敗しました")?,
            max_connections: env::var("DB_MAX_CONNECTIONS")
                .unwrap_or_else(|_| "20".to_string())
                .parse()
                .context("最大コネクション数の解析に失敗しました")?,
        })
    }

    pub fn connection_string(&self) -> String {
        format!(
            "postgres://{}:{}@{}:{}/{}",
            self.username, self.password, self.host, self.port, self.database_name
        )
    }
}

/// PostgreSQL database connection pool
///
/// 効率的なコネクションプール管理とリソース共有を提供
#[derive(Debug, Clone)]
pub struct PostgresDatabase {
    pool: PgPool,
}

impl PostgresDatabase {
    /// データベース接続プールを作成
    ///
    /// # 引数
    /// * `config` - データベース設定
    ///
    /// # 戻り値
    /// * `Result<Self>` - 成功時はPostgresDatabaseインスタンス
    pub async fn connect(config: &DatabaseConfig) -> Result<Self> {
        let pool = PgPoolOptions::new()
            .max_connections(config.max_connections)
            .acquire_timeout(Duration::from_secs(config.connection_timeout))
            .idle_timeout(Duration::from_secs(config.idle_timeout))
            .connect(&config.connection_string())
            .await
            .context("データベースコネクションプールの作成に失敗しました")?;

        // コネクションテスト - プールの正常性を確認
        pool.acquire()
            .await
            .context("プールからのコネクション取得に失敗しました")?;

        Ok(Self { pool })
    }

    /// 内部プールへの参照を取得
    ///
    /// # 戻り値
    /// * `&sqlx::Pool<Postgres>` - コネクションプールの参照
    pub fn pool(&self) -> &sqlx::Pool<Postgres> {
        &self.pool
    }

    /// SQLクエリを実行（基本版）
    ///
    /// # 引数
    /// * `query` - 実行するSQLクエリ
    ///
    /// # 戻り値
    /// * `Result<u64>` - 影響を受けた行数
    pub async fn execute(&self, query: &str) -> Result<u64> {
        self.execute_with_retry(query, 3).await
    }

    /// リトライ機能付きクエリ実行
    async fn execute_with_retry(&self, query: &str, retries: u8) -> Result<u64> {
        let mut attempts = 0;

        loop {
            attempts += 1;

            match sqlx::query(query).execute(&self.pool).await {
                Ok(result) => return Ok(result.rows_affected()),
                Err(err) => {
                    if attempts >= retries || !is_retryable_error(&err) {
                        return Err(anyhow::anyhow!("クエリ実行に失敗しました: {}", err));
                    }

                    let backoff = calculate_backoff_ms(attempts);
                    sleep(Duration::from_millis(backoff)).await;
                }
            }
        }
    }

    /// 単一行を取得するクエリ実行
    ///
    /// # 引数
    /// * `query` - 実行するSQLクエリ
    ///
    /// # 戻り値
    /// * `Result<T>` - マッピングされたエンティティ
    pub async fn query_one<T: for<'a> sqlx::FromRow<'a, PgRow>>(&self, query: &str) -> Result<T> {
        let row = sqlx::query(query)
            .fetch_one(&self.pool)
            .await
            .map_err(|e| DatabaseError::QueryError(e.to_string()))?;

        T::from_row(&row).map_err(|e| {
            DatabaseError::QueryError(format!("行のマッピングに失敗しました: {}", e)).into()
        })
    }

    /// オプション単一行取得クエリ
    ///
    /// # 引数
    /// * `query` - 実行するSQLクエリ
    ///
    /// # 戻り値
    /// * `Result<Option<T>>` - マッピングされたエンティティ（存在しない場合はNone）
    pub async fn query_optional<T: for<'a> sqlx::FromRow<'a, PgRow>>(
        &self,
        query: &str,
    ) -> Result<Option<T>> {
        let row = sqlx::query(query)
            .fetch_optional(&self.pool)
            .await
            .map_err(|e| DatabaseError::QueryError(e.to_string()))?;

        match row {
            Some(row) => Ok(Some(T::from_row(&row).map_err(|e| {
                DatabaseError::QueryError(format!("行のマッピングに失敗しました: {}", e))
            })?)),
            None => Ok(None),
        }
    }

    /// 複数行取得クエリ
    ///
    /// # 引数
    /// * `query` - 実行するSQLクエリ
    ///
    /// # 戻り値
    /// * `Result<Vec<T>>` - マッピングされたエンティティのベクタ
    pub async fn query_many<T: for<'a> sqlx::FromRow<'a, PgRow>>(
        &self,
        query: &str,
    ) -> Result<Vec<T>> {
        let rows = sqlx::query(query)
            .fetch_all(&self.pool)
            .await
            .map_err(|e| DatabaseError::QueryError(e.to_string()))?;

        let mut results = Vec::with_capacity(rows.len());
        for row in rows {
            results.push(T::from_row(&row).map_err(|e| {
                DatabaseError::QueryError(format!("行のマッピングに失敗しました: {}", e))
            })?);
        }

        Ok(results)
    }

    /// 更新クエリ実行
    ///
    /// # 引数
    /// * `query` - 実行するUPDATEクエリ
    ///
    /// # 戻り値
    /// * `Result<u64>` - 更新された行数
    pub async fn update(&self, query: &str) -> Result<u64> {
        self.execute(query).await
    }

    /// 削除クエリ実行
    ///
    /// # 引数
    /// * `query` - 実行するDELETEクエリ
    ///
    /// # 戻り値
    /// * `Result<u64>` - 削除された行数
    pub async fn delete(&self, query: &str) -> Result<u64> {
        self.execute(query).await
    }

    /// トランザクションを開始
    ///
    /// # 戻り値
    /// * `Result<Transaction<'_, Postgres>>` - 開始されたトランザクション
    pub async fn begin_transaction(&self) -> Result<Transaction<'_, Postgres>> {
        self.pool
            .begin()
            .await
            .context("トランザクションの開始に失敗しました")
    }

    /// トランザクション内での処理実行
    ///
    /// 自動的にコミット/ロールバックを管理します
    ///
    /// # 引数
    /// * `f` - トランザクション内で実行する処理
    ///
    /// # 戻り値
    /// * `Result<R>` - 処理の結果
    pub async fn with_transaction<F, R>(&self, f: F) -> Result<R>
    where
        F: for<'c> FnOnce(
            &'c mut Transaction<'_, Postgres>,
        ) -> futures::future::BoxFuture<'c, Result<R>>,
    {
        let mut tx = self
            .pool
            .begin()
            .await
            .context("トランザクションの開始に失敗しました")?;

        match f(&mut tx).await {
            Ok(result) => {
                tx.commit()
                    .await
                    .context("トランザクションのコミットに失敗しました")?;
                Ok(result)
            }
            Err(e) => {
                if let Err(rollback_err) = tx.rollback().await {
                    eprintln!(
                        "トランザクションのロールバックに失敗しました: {}",
                        rollback_err
                    );
                }
                Err(e)
            }
        }
    }

    /// 行ロック付きクエリ実行
    ///
    /// SELECT FOR UPDATEを使用してペシミスティックロックを取得
    ///
    /// # 引数
    /// * `query` - 実行するSELECTクエリ
    /// * `tx` - 実行対象のトランザクション
    ///
    /// # 戻り値
    /// * `Result<T>` - ロックされた行のマッピング結果
    pub async fn lock_row<T: for<'a> sqlx::FromRow<'a, PgRow>>(
        &self,
        query: &str,
        tx: &mut Transaction<'_, Postgres>,
    ) -> Result<T> {
        // FOR UPDATEが含まれていない場合は追加
        let query = if !query.to_uppercase().contains("FOR UPDATE") {
            format!("{} FOR UPDATE", query)
        } else {
            query.to_string()
        };

        let row = sqlx::query(&query)
            .fetch_one(&mut **tx)
            .await
            .map_err(|e| DatabaseError::QueryError(e.to_string()))?;

        T::from_row(&row).map_err(|e| {
            DatabaseError::QueryError(format!("ロック行のマッピングに失敗しました: {}", e)).into()
        })
    }
}

/// リトライ可能なエラーかどうかを判定
///
/// コネクション問題やデッドロックなどの一時的なエラーを対象とする
fn is_retryable_error(err: &sqlx::Error) -> bool {
    match err {
        sqlx::Error::Database(db_err) => {
            // PostgreSQLのコネクション問題やデッドロック関連のエラーコード
            let error_code = db_err.code();
            if let Some(code) = error_code {
                // コネクション喪失やデッドロックエラー
                matches!(
                    code.as_ref(),
                    "40001" | "40P01" | "57P01" | "08006" | "08001" | "08004"
                )
            } else {
                false
            }
        }
        sqlx::Error::Io(_) => true,
        sqlx::Error::PoolTimedOut => true,
        _ => false,
    }
}

/// バックオフ時間を計算（指数バックオフ + ジッター）
///
/// # 引数
/// * `attempt` - 試行回数
///
/// # 戻り値
/// * `u64` - 待機時間（ミリ秒）
fn calculate_backoff_ms(attempt: u8) -> u64 {
    let base = 2_u64.saturating_pow(attempt as u32);
    let max_backoff = 5000;
    let mut rng = rand::rng();
    let jitter: u64 = rng.random_range(0..10);
    (base * 100 + jitter).min(max_backoff)
}
