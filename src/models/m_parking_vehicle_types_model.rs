use serde::{Deserialize, Serialize};
use crate::utils::validation::validate_not_empty;

/// 駐車場対応車両タイプマスターモデル
/// データベーステーブル: m_parking_vehicle_types
/// 駐車場が対応可能な車両タイプ（普通車、軽自動車、大型車等）を管理
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MParkingVehicleTypesModel {
    /// 車両タイプID（主キー）
    pub vehicle_type_id: String,
    /// 車両タイプ名称（例：普通車、軽自動車、大型車、バイク等）
    pub vehicle_type_name: String,
    /// 車両サイズカテゴリ（S,M,L,XL等）
    pub size_category: Option<String>,
    /// 最大車長（cm）
    pub max_length_cm: Option<i32>,
    /// 最大車幅（cm）
    pub max_width_cm: Option<i32>,
    /// 最大車高（cm）
    pub max_height_cm: Option<i32>,
    /// 表示順序
    pub display_order: Option<i32>,
    /// 説明・備考
    pub description: Option<String>,
    /// アクティブフラグ（true: 有効, false: 無効）
    pub is_active: bool,
    /// 作成日時
    pub created_at: Option<chrono::DateTime<chrono::Utc>>,
    /// 更新日時
    pub updated_at: Option<chrono::DateTime<chrono::Utc>>,
}

/// 車両タイプ登録・更新用リクエストモデル
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VehicleTypeRequest {
    /// 車両タイプ名称
    pub vehicle_type_name: String,
    /// 車両サイズカテゴリ
    pub size_category: Option<String>,
    /// 最大車長（cm）
    pub max_length_cm: Option<i32>,
    /// 最大車幅（cm）
    pub max_width_cm: Option<i32>,
    /// 最大車高（cm）
    pub max_height_cm: Option<i32>,
    /// 表示順序
    pub display_order: Option<i32>,
    /// 説明・備考
    pub description: Option<String>,
    /// アクティブフラグ
    pub is_active: bool,
}

/// 車両タイプレスポンスモデル
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VehicleTypeResponse {
    /// 車両タイプID
    pub vehicle_type_id: String,
    /// 車両タイプ名称
    pub vehicle_type_name: String,
    /// 車両サイズカテゴリ
    pub size_category: Option<String>,
    /// 車両サイズ情報
    pub size_info: Option<VehicleSizeInfo>,
    /// 表示順序
    pub display_order: Option<i32>,
    /// 説明・備考
    pub description: Option<String>,
    /// アクティブフラグ
    pub is_active: bool,
}

/// 車両サイズ情報
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VehicleSizeInfo {
    /// 最大車長（cm）
    pub max_length_cm: Option<i32>,
    /// 最大車幅（cm）
    pub max_width_cm: Option<i32>,
    /// 最大車高（cm）
    pub max_height_cm: Option<i32>,
    /// サイズ表示用文字列
    pub size_display: String,
}

/// 車両タイプリストレスポンス
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VehicleTypeListResponse {
    /// 車両タイプリスト
    pub vehicle_types: Vec<VehicleTypeResponse>,
    /// 総件数
    pub total_count: i64,
}

impl MParkingVehicleTypesModel {
    /// 新しい車両タイプインスタンスを作成
    pub fn new(
        vehicle_type_id: String,
        vehicle_type_name: String,
        size_category: Option<String>,
        max_length_cm: Option<i32>,
        max_width_cm: Option<i32>,
        max_height_cm: Option<i32>,
        display_order: Option<i32>,
        description: Option<String>,
        is_active: bool,
    ) -> Self {
        Self {
            vehicle_type_id,
            vehicle_type_name,
            size_category,
            max_length_cm,
            max_width_cm,
            max_height_cm,
            display_order,
            description,
            is_active,
            created_at: Some(chrono::Utc::now()),
            updated_at: Some(chrono::Utc::now()),
        }
    }

    /// 車両タイプ名称のバリデーション
    pub fn validate_vehicle_type_name(&self) -> Result<(), String> {
        validate_not_empty(&self.vehicle_type_name, "車両タイプ名称")
            .map_err(|e| e.to_string())?;
        
        if self.vehicle_type_name.len() > 50 {
            return Err("車両タイプ名称は50文字以内で入力してください".to_string());
        }
        
        Ok(())
    }

    /// サイズ情報のバリデーション
    pub fn validate_size_info(&self) -> Result<(), String> {
        // 車長の妥当性チェック
        if let Some(length) = self.max_length_cm {
            if length <= 0 || length > 2000 {
                return Err("車長は1cm以上2000cm以下で入力してください".to_string());
            }
        }

        // 車幅の妥当性チェック
        if let Some(width) = self.max_width_cm {
            if width <= 0 || width > 500 {
                return Err("車幅は1cm以上500cm以下で入力してください".to_string());
            }
        }

        // 車高の妥当性チェック
        if let Some(height) = self.max_height_cm {
            if height <= 0 || height > 500 {
                return Err("車高は1cm以上500cm以下で入力してください".to_string());
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
        self.validate_vehicle_type_name()?;
        self.validate_size_info()?;
        self.validate_display_order()?;
        Ok(())
    }

    /// サイズカテゴリが設定されているかチェック
    pub fn has_size_category(&self) -> bool {
        self.size_category.is_some() && !self.size_category.as_ref().unwrap().is_empty()
    }

    /// サイズ情報が設定されているかチェック
    pub fn has_size_info(&self) -> bool {
        self.max_length_cm.is_some() || self.max_width_cm.is_some() || self.max_height_cm.is_some()
    }

    /// サイズ表示用文字列を生成
    pub fn generate_size_display(&self) -> String {
        let mut parts = Vec::new();

        if let Some(length) = self.max_length_cm {
            parts.push(format!("長さ{}cm", length));
        }
        if let Some(width) = self.max_width_cm {
            parts.push(format!("幅{}cm", width));
        }
        if let Some(height) = self.max_height_cm {
            parts.push(format!("高さ{}cm", height));
        }

        if parts.is_empty() {
            "サイズ制限なし".to_string()
        } else {
            parts.join(" × ")
        }
    }

    /// 車両が指定された車両タイプに適合するかチェック
    pub fn is_vehicle_compatible(&self, vehicle_length: Option<i32>, vehicle_width: Option<i32>, vehicle_height: Option<i32>) -> bool {
        // 車長チェック
        if let (Some(max_length), Some(v_length)) = (self.max_length_cm, vehicle_length) {
            if v_length > max_length {
                return false;
            }
        }

        // 車幅チェック
        if let (Some(max_width), Some(v_width)) = (self.max_width_cm, vehicle_width) {
            if v_width > max_width {
                return false;
            }
        }

        // 車高チェック
        if let (Some(max_height), Some(v_height)) = (self.max_height_cm, vehicle_height) {
            if v_height > max_height {
                return false;
            }
        }

        true
    }

    /// レスポンスモデルに変換
    pub fn to_response(&self) -> VehicleTypeResponse {
        let size_info = if self.has_size_info() {
            Some(VehicleSizeInfo {
                max_length_cm: self.max_length_cm,
                max_width_cm: self.max_width_cm,
                max_height_cm: self.max_height_cm,
                size_display: self.generate_size_display(),
            })
        } else {
            None
        };

        VehicleTypeResponse {
            vehicle_type_id: self.vehicle_type_id.clone(),
            vehicle_type_name: self.vehicle_type_name.clone(),
            size_category: self.size_category.clone(),
            size_info,
            display_order: self.display_order,
            description: self.description.clone(),
            is_active: self.is_active,
        }
    }
}

impl VehicleTypeRequest {
    /// リクエストモデルのバリデーション
    pub fn validate(&self) -> Result<(), String> {
        validate_not_empty(&self.vehicle_type_name, "車両タイプ名称")
            .map_err(|e| e.to_string())?;
        
        if self.vehicle_type_name.len() > 50 {
            return Err("車両タイプ名称は50文字以内で入力してください".to_string());
        }

        // サイズ情報のバリデーション
        if let Some(length) = self.max_length_cm {
            if length <= 0 || length > 2000 {
                return Err("車長は1cm以上2000cm以下で入力してください".to_string());
            }
        }

        if let Some(width) = self.max_width_cm {
            if width <= 0 || width > 500 {
                return Err("車幅は1cm以上500cm以下で入力してください".to_string());
            }
        }

        if let Some(height) = self.max_height_cm {
            if height <= 0 || height > 500 {
                return Err("車高は1cm以上500cm以下で入力してください".to_string());
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
    pub fn to_model(&self, vehicle_type_id: String) -> MParkingVehicleTypesModel {
        MParkingVehicleTypesModel::new(
            vehicle_type_id,
            self.vehicle_type_name.clone(),
            self.size_category.clone(),
            self.max_length_cm,
            self.max_width_cm,
            self.max_height_cm,
            self.display_order,
            self.description.clone(),
            self.is_active,
        )
    }
}

/// Convert MParkingVehicleTypesModel to VehicleTypeResponse
impl From<MParkingVehicleTypesModel> for VehicleTypeResponse {
    fn from(model: MParkingVehicleTypesModel) -> Self {
        let size_info = if model.max_length_cm.is_some() || model.max_width_cm.is_some() || model.max_height_cm.is_some() {
            Some(VehicleSizeInfo {
                max_length_cm: model.max_length_cm,
                max_width_cm: model.max_width_cm,
                max_height_cm: model.max_height_cm,
                size_display: format!(
                    "{}x{}x{}cm",
                    model.max_length_cm.map(|v| v.to_string()).unwrap_or("-".to_string()),
                    model.max_width_cm.map(|v| v.to_string()).unwrap_or("-".to_string()),
                    model.max_height_cm.map(|v| v.to_string()).unwrap_or("-".to_string())
                ),
            })
        } else {
            None
        };

        Self {
            vehicle_type_id: model.vehicle_type_id,
            vehicle_type_name: model.vehicle_type_name,
            size_category: model.size_category,
            size_info,
            display_order: model.display_order,
            description: model.description,
            is_active: model.is_active,
        }
    }
}
