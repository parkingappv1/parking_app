use serde::{Deserialize, Serialize};
use crate::utils::validation::validate_not_empty;

/// 駐車場設備・機能マスターモデル
/// データベーステーブル: m_parking_features
/// 駐車場が提供する設備や機能（24時間営業、屋根付き、EV充電等）を管理
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MParkingFeaturesModel {
    /// 設備・機能ID（主キー）
    pub feature_id: String,
    /// 設備・機能名称（例：24時間営業、屋根付き、EV充電設備等）
    pub feature_name: String,
    /// 設備カテゴリ（parking, safety, convenience, payment等）
    pub feature_category: Option<String>,
    /// アイコンファイル名またはアイコンコード
    pub icon_name: Option<String>,
    /// 表示順序
    pub display_order: Option<i32>,
    /// 説明・詳細情報
    pub description: Option<String>,
    /// 検索フィルターとして使用可能か
    pub is_filterable: bool,
    /// 一覧画面でアイコン表示するか
    pub show_in_list: bool,
    /// アクティブフラグ（true: 有効, false: 無効）
    pub is_active: bool,
    /// 作成日時
    pub created_at: Option<chrono::DateTime<chrono::Utc>>,
    /// 更新日時
    pub updated_at: Option<chrono::DateTime<chrono::Utc>>,
}

/// 設備・機能登録・更新用リクエストモデル
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ParkingFeatureRequest {
    /// 設備・機能名称
    pub feature_name: String,
    /// 設備カテゴリ
    pub feature_category: Option<String>,
    /// アイコンファイル名またはアイコンコード
    pub icon_name: Option<String>,
    /// 表示順序
    pub display_order: Option<i32>,
    /// 説明・詳細情報
    pub description: Option<String>,
    /// 検索フィルターとして使用可能か
    pub is_filterable: bool,
    /// 一覧画面でアイコン表示するか
    pub show_in_list: bool,
    /// アクティブフラグ
    pub is_active: bool,
}

/// 設備・機能レスポンスモデル
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ParkingFeatureResponse {
    /// 設備・機能ID
    pub feature_id: String,
    /// 設備・機能名称
    pub feature_name: String,
    /// 設備カテゴリ
    pub feature_category: Option<String>,
    /// カテゴリ表示名
    pub category_display_name: Option<String>,
    /// アイコン情報
    pub icon_info: Option<FeatureIconInfo>,
    /// 表示順序
    pub display_order: Option<i32>,
    /// 説明・詳細情報
    pub description: Option<String>,
    /// 検索フィルターとして使用可能か
    pub is_filterable: bool,
    /// 一覧画面でアイコン表示するか
    pub show_in_list: bool,
    /// アクティブフラグ
    pub is_active: bool,
}

/// 設備・機能アイコン情報
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FeatureIconInfo {
    /// アイコンファイル名またはアイコンコード
    pub icon_name: String,
    /// アイコンURL（存在する場合）
    pub icon_url: Option<String>,
    /// アイコンタイプ（file, font, emoji等）
    pub icon_type: String,
}

impl From<MParkingFeaturesModel> for ParkingFeatureResponse {
    fn from(model: MParkingFeaturesModel) -> Self {
        Self {
            feature_id: model.feature_id,
            feature_name: model.feature_name,
            feature_category: model.feature_category.clone(),
            category_display_name: model.feature_category,
            icon_info: model.icon_name.map(|name| FeatureIconInfo {
                icon_name: name.clone(),
                icon_url: None,
                icon_type: "file".to_string(),
            }),
            display_order: model.display_order,
            description: model.description,
            is_filterable: model.is_filterable,
            show_in_list: model.show_in_list,
            is_active: model.is_active,
        }
    }
}

/// 設備・機能リストレスポンス
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ParkingFeatureListResponse {
    /// 設備・機能リスト
    pub features: Vec<ParkingFeatureResponse>,
    /// カテゴリ別グループ化された設備・機能
    pub features_by_category: std::collections::HashMap<String, Vec<ParkingFeatureResponse>>,
    /// 総件数
    pub total_count: i64,
}

/// 設備・機能カテゴリ定義
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum FeatureCategory {
    /// 駐車場基本機能
    Parking,
    /// セキュリティ・安全
    Safety,
    /// 利便性・サービス
    Convenience,
    /// 支払い方法
    Payment,
    /// その他
    Other,
}

impl MParkingFeaturesModel {
    /// 新しい設備・機能インスタンスを作成
    pub fn new(
        feature_id: String,
        feature_name: String,
        feature_category: Option<String>,
        icon_name: Option<String>,
        display_order: Option<i32>,
        description: Option<String>,
        is_filterable: bool,
        show_in_list: bool,
        is_active: bool,
    ) -> Self {
        Self {
            feature_id,
            feature_name,
            feature_category,
            icon_name,
            display_order,
            description,
            is_filterable,
            show_in_list,
            is_active,
            created_at: Some(chrono::Utc::now()),
            updated_at: Some(chrono::Utc::now()),
        }
    }

    /// 設備・機能名称のバリデーション
    pub fn validate_feature_name(&self) -> Result<(), String> {
        validate_not_empty(&self.feature_name, "設備・機能名称")
            .map_err(|e| e.to_string())?;
        
        if self.feature_name.len() > 100 {
            return Err("設備・機能名称は100文字以内で入力してください".to_string());
        }
        
        Ok(())
    }

    /// カテゴリのバリデーション
    pub fn validate_category(&self) -> Result<(), String> {
        if let Some(category) = &self.feature_category {
            if category.is_empty() {
                return Err("カテゴリが指定されている場合は空文字にできません".to_string());
            }
            
            if category.len() > 50 {
                return Err("カテゴリは50文字以内で入力してください".to_string());
            }

            // 定義済みカテゴリのチェック
            let valid_categories = vec!["parking", "safety", "convenience", "payment", "other"];
            if !valid_categories.contains(&category.as_str()) {
                return Err("無効なカテゴリが指定されています".to_string());
            }
        }
        Ok(())
    }

    /// 表示順序のバリデーション
    pub fn validate_display_order(&self) -> Result<(), String> {
        if let Some(order) = self.display_order {
            if order < 0 || order > 9999 {
                return Err("表示順序は0以上9999以下で入力してください".to_string());
            }
        }
        Ok(())
    }

    /// 全体のバリデーション
    pub fn validate(&self) -> Result<(), String> {
        self.validate_feature_name()?;
        self.validate_category()?;
        self.validate_display_order()?;
        Ok(())
    }

    /// アイコンが設定されているかチェック
    pub fn has_icon(&self) -> bool {
        self.icon_name.is_some() && !self.icon_name.as_ref().unwrap().is_empty()
    }

    /// カテゴリ表示名を取得
    pub fn get_category_display_name(&self) -> Option<String> {
        self.feature_category.as_ref().map(|category| {
            match category.as_str() {
                "parking" => "駐車場機能".to_string(),
                "safety" => "セキュリティ・安全".to_string(),
                "convenience" => "利便性・サービス".to_string(),
                "payment" => "支払い方法".to_string(),
                "other" => "その他".to_string(),
                _ => category.clone(),
            }
        })
    }

    /// アイコンタイプを判定
    pub fn get_icon_type(&self) -> Option<String> {
        if let Some(icon) = &self.icon_name {
            if icon.starts_with("http://") || icon.starts_with("https://") {
                Some("url".to_string())
            } else if icon.ends_with(".png") || icon.ends_with(".jpg") || icon.ends_with(".svg") {
                Some("file".to_string())
            } else if icon.starts_with("fa-") || icon.starts_with("material-") {
                Some("font".to_string())
            } else if icon.len() <= 4 {
                Some("emoji".to_string())
            } else {
                Some("custom".to_string())
            }
        } else {
            None
        }
    }

    /// アイコンURLを生成（ファイルの場合）
    pub fn generate_icon_url(&self, base_url: &str) -> Option<String> {
        if let Some(icon) = &self.icon_name {
            if icon.starts_with("http://") || icon.starts_with("https://") {
                Some(icon.clone())
            } else if icon.ends_with(".png") || icon.ends_with(".jpg") || icon.ends_with(".svg") {
                Some(format!("{}/icons/features/{}", base_url, icon))
            } else {
                None
            }
        } else {
            None
        }
    }

    /// 検索フィルターとして利用可能な設備・機能かチェック
    pub fn is_search_filterable(&self) -> bool {
        self.is_filterable && self.is_active
    }

    /// 一覧画面で表示すべき設備・機能かチェック
    pub fn should_show_in_list(&self) -> bool {
        self.show_in_list && self.is_active
    }

    /// レスポンスモデルに変換
    pub fn to_response(&self, base_icon_url: Option<&str>) -> ParkingFeatureResponse {
        let icon_info = if self.has_icon() {
            let icon_type = self.get_icon_type().unwrap_or("custom".to_string());
            let icon_url = if let Some(base_url) = base_icon_url {
                self.generate_icon_url(base_url)
            } else {
                None
            };

            Some(FeatureIconInfo {
                icon_name: self.icon_name.clone().unwrap(),
                icon_url,
                icon_type,
            })
        } else {
            None
        };

        ParkingFeatureResponse {
            feature_id: self.feature_id.clone(),
            feature_name: self.feature_name.clone(),
            feature_category: self.feature_category.clone(),
            category_display_name: self.get_category_display_name(),
            icon_info,
            display_order: self.display_order,
            description: self.description.clone(),
            is_filterable: self.is_filterable,
            show_in_list: self.show_in_list,
            is_active: self.is_active,
        }
    }
}

impl ParkingFeatureRequest {
    /// リクエストモデルのバリデーション
    pub fn validate(&self) -> Result<(), String> {
        validate_not_empty(&self.feature_name, "設備・機能名称")
            .map_err(|e| e.to_string())?;
        
        if self.feature_name.len() > 100 {
            return Err("設備・機能名称は100文字以内で入力してください".to_string());
        }

        // カテゴリのバリデーション
        if let Some(category) = &self.feature_category {
            if category.is_empty() {
                return Err("カテゴリが指定されている場合は空文字にできません".to_string());
            }
            
            if category.len() > 50 {
                return Err("カテゴリは50文字以内で入力してください".to_string());
            }

            let valid_categories = vec!["parking", "safety", "convenience", "payment", "other"];
            if !valid_categories.contains(&category.as_str()) {
                return Err("無効なカテゴリが指定されています".to_string());
            }
        }

        // 表示順序のバリデーション
        if let Some(order) = self.display_order {
            if order < 0 || order > 9999 {
                return Err("表示順序は0以上9999以下で入力してください".to_string());
            }
        }

        Ok(())
    }

    /// モデルインスタンスに変換（新規作成用）
    pub fn to_model(&self, feature_id: String) -> MParkingFeaturesModel {
        MParkingFeaturesModel::new(
            feature_id,
            self.feature_name.clone(),
            self.feature_category.clone(),
            self.icon_name.clone(),
            self.display_order,
            self.description.clone(),
            self.is_filterable,
            self.show_in_list,
            self.is_active,
        )
    }
}

impl FeatureCategory {
    /// カテゴリの文字列表現を取得
    pub fn as_str(&self) -> &str {
        match self {
            FeatureCategory::Parking => "parking",
            FeatureCategory::Safety => "safety",
            FeatureCategory::Convenience => "convenience",
            FeatureCategory::Payment => "payment",
            FeatureCategory::Other => "other",
        }
    }

    /// カテゴリの表示名を取得
    pub fn display_name(&self) -> &str {
        match self {
            FeatureCategory::Parking => "駐車場機能",
            FeatureCategory::Safety => "セキュリティ・安全",
            FeatureCategory::Convenience => "利便性・サービス",
            FeatureCategory::Payment => "支払い方法",
            FeatureCategory::Other => "その他",
        }
    }

    /// 文字列からカテゴリを作成
    pub fn from_str(s: &str) -> Option<Self> {
        match s {
            "parking" => Some(FeatureCategory::Parking),
            "safety" => Some(FeatureCategory::Safety),
            "convenience" => Some(FeatureCategory::Convenience),
            "payment" => Some(FeatureCategory::Payment),
            "other" => Some(FeatureCategory::Other),
            _ => None,
        }
    }

    /// 全カテゴリのリストを取得
    pub fn all_categories() -> Vec<Self> {
        vec![
            FeatureCategory::Parking,
            FeatureCategory::Safety,
            FeatureCategory::Convenience,
            FeatureCategory::Payment,
            FeatureCategory::Other,
        ]
    }
}
