-- パスワードリセットコード管理テーブル
-- 論理名: パスワードリセットコード管理テーブル
-- 物理名: password_reset_codes
CREATE TABLE password_reset_codes (
    -- 論理名: リセットコードID
    -- 物理名: reset_code_id
    reset_code_id UUID NOT NULL DEFAULT uuid_generate_v4(),
    
    -- 論理名: メールアドレス
    -- 物理名: email
    email VARCHAR(255) NOT NULL,
    
    -- 論理名: リセットコード
    -- 物理名: reset_code
    reset_code VARCHAR(10) NOT NULL,
    
    -- 論理名: 有効期限
    -- 物理名: expires_at
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    
    -- 論理名: 作成日時
    -- 物理名: created_datetime
    created_datetime TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- 論理名: 使用フラグ
    -- 物理名: is_used
    -- 0: 未使用, 1: 使用済み
    is_used VARCHAR(1) NOT NULL DEFAULT '0',
    
    -- 論理名: 使用日時
    -- 物理名: used_datetime
    used_datetime TIMESTAMP WITH TIME ZONE,
    
    -- 主キー制約
    CONSTRAINT pk_password_reset_codes PRIMARY KEY (reset_code_id),
    
    -- 一意制約（同じメールアドレスに対して同時に有効なコードは1つまで）
    CONSTRAINT unique_email_active_code UNIQUE (email, is_used) DEFERRABLE INITIALLY DEFERRED
);

-- テーブルコメント
COMMENT ON TABLE password_reset_codes IS 'パスワードリセット用の認証コードを管理するテーブル';

-- カラムコメント
COMMENT ON COLUMN password_reset_codes.reset_code_id IS 'リセットコードの一意識別子（UUID v4）';
COMMENT ON COLUMN password_reset_codes.email IS '対象ユーザーのメールアドレス';
COMMENT ON COLUMN password_reset_codes.reset_code IS '6桁のランダムな認証コード';
COMMENT ON COLUMN password_reset_codes.expires_at IS 'リセットコードの有効期限（通常は発行から30分後）';
COMMENT ON COLUMN password_reset_codes.created_at IS 'リセットコードの作成日時';
COMMENT ON COLUMN password_reset_codes.is_used IS '使用フラグ（0: 未使用, 1: 使用済み）';
COMMENT ON COLUMN password_reset_codes.used_at IS 'リセットコードが使用された日時';

-- インデックス作成
CREATE INDEX idx_password_reset_codes_email ON password_reset_codes(email);
CREATE INDEX idx_password_reset_codes_expires_at ON password_reset_codes(expires_at);
CREATE INDEX idx_password_reset_codes_reset_code ON password_reset_codes(reset_code);

-- 有効期限切れのレコードを自動削除するための関数
CREATE OR REPLACE FUNCTION cleanup_expired_reset_codes() RETURNS void AS $$
BEGIN
    DELETE FROM password_reset_codes 
    WHERE expires_at < NOW() - INTERVAL '24 hours';
END;
$$ LANGUAGE plpgsql;

-- 有効期限切れレコードの定期削除用トリガー（新しいレコード挿入時に実行）
CREATE OR REPLACE FUNCTION trigger_cleanup_expired_reset_codes() RETURNS TRIGGER AS $$
BEGIN
    -- 1%の確率で有効期限切れレコードをクリーンアップ
    IF RANDOM() < 0.01 THEN
        PERFORM cleanup_expired_reset_codes();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_cleanup_on_insert
    AFTER INSERT ON password_reset_codes
    FOR EACH ROW EXECUTE FUNCTION trigger_cleanup_expired_reset_codes();
