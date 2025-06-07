// filepath: /src/utils/validation.rs
use anyhow::{Result, anyhow};

/// 文字列が空でないことを検証
pub fn validate_not_empty(value: &str, field_name: &str) -> Result<()> {
    if value.trim().is_empty() {
        return Err(anyhow!("{}は必須項目です", field_name));
    }
    Ok(())
}

/// 文字列の長さを検証
pub fn validate_length(value: &str, field_name: &str, min_len: usize, max_len: usize) -> Result<()> {
    let len = value.chars().count();
    if len < min_len {
        return Err(anyhow!("{}は{}文字以上で入力してください", field_name, min_len));
    }
    if len > max_len {
        return Err(anyhow!("{}は{}文字以下で入力してください", field_name, max_len));
    }
    Ok(())
}

/// 数値の範囲を検証
pub fn validate_range<T: PartialOrd + std::fmt::Display>(
    value: T, 
    field_name: &str, 
    min: T, 
    max: T
) -> Result<()> {
    if value < min || value > max {
        return Err(anyhow!("{}は{}以上{}以下で入力してください", field_name, min, max));
    }
    Ok(())
}

/// メールアドレス形式の検証（簡易版）
pub fn validate_email(email: &str) -> Result<()> {
    if !email.contains('@') || !email.contains('.') {
        return Err(anyhow!("有効なメールアドレスを入力してください"));
    }
    Ok(())
}

/// 電話番号形式の検証（日本の電話番号）
pub fn validate_phone_number(phone: &str) -> Result<()> {
    let cleaned = phone.replace(&['-', ' ', '(', ')'][..], "");
    if cleaned.len() < 10 || cleaned.len() > 11 {
        return Err(anyhow!("有効な電話番号を入力してください"));
    }
    if !cleaned.chars().all(|c| c.is_numeric()) {
        return Err(anyhow!("電話番号は数字のみで入力してください"));
    }
    Ok(())
}
