-- ===============================
-- DROP 语句（先清理旧表）
-- ===============================
DROP TABLE IF EXISTS t_parking_images CASCADE;
DROP TABLE IF EXISTS t_parking_vehicle_types CASCADE;
DROP TABLE IF EXISTS t_parking_limits CASCADE;
DROP TABLE IF EXISTS t_parking_lots CASCADE;


-- ===============================
-- 1. 駐車場基本情報テーブル
-- ===============================
CREATE TABLE t_parking_lots (
  parking_lot_id VARCHAR(37) NOT NULL,
  owner_id VARCHAR(37) NOT NULL,
  parking_lot_name VARCHAR(100) NOT NULL,
  postal_code VARCHAR(20) NOT NULL,
  prefecture VARCHAR(10) NOT NULL,
  city VARCHAR(50) NOT NULL,
  address_detail TEXT NOT NULL,
  latitude VARCHAR(20) NOT NULL,
  longitude VARCHAR(20) NOT NULL,
  phone_number VARCHAR(20) NOT NULL,
  capacity INTEGER NOT NULL,
  available_capacity INTEGER,
  rental_type VARCHAR(20) NOT NULL,
  charge VARCHAR(50) NOT NULL,
  features_tip TEXT,
  nearest_station VARCHAR(100),
  status VARCHAR(20) NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE,
  end_start_datetime TIMESTAMP,
  end_end_datetime TIMESTAMP,
  end_reason VARCHAR(100),
  end_reason_detail TEXT,
  notes TEXT,
  created_datetime TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_datetime TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT pk_t_parking_lots PRIMARY KEY (parking_lot_id)
);

COMMENT ON TABLE t_parking_lots IS '駐車場の基本情報を格納するテーブル';

COMMENT ON COLUMN t_parking_lots.parking_lot_id IS '駐車場の一意識別子（形式: P-000001）';
COMMENT ON COLUMN t_parking_lots.owner_id IS '関連するオーナーのID（形式: owner_XXXXXX）';
COMMENT ON COLUMN t_parking_lots.parking_lot_name IS '駐車場の名称';
COMMENT ON COLUMN t_parking_lots.postal_code IS '郵便番号（例: 123-4567）';
COMMENT ON COLUMN t_parking_lots.prefecture IS '都道府県';
COMMENT ON COLUMN t_parking_lots.city IS '市区町村';
COMMENT ON COLUMN t_parking_lots.address_detail IS '番地・建物名・部屋番号などの詳細住所';
COMMENT ON COLUMN t_parking_lots.phone_number IS '駐車場に関する問い合わせ用電話番号（重複不可）';
COMMENT ON COLUMN t_parking_lots.capacity IS '総収容台数';
COMMENT ON COLUMN t_parking_lots.available_capacity IS '現在の空き台数（NULL可能）';
COMMENT ON COLUMN t_parking_lots.rental_type IS '貸出タイプ（例: 時間貸し、月極）';
COMMENT ON COLUMN t_parking_lots.charge IS '料金情報（例: 30分200円）';
COMMENT ON COLUMN t_parking_lots.features_tip IS '駐車場の特徴や備考（NULL可能）';
COMMENT ON COLUMN t_parking_lots.nearest_station IS '最寄り駅名（例: 東京駅）';
COMMENT ON COLUMN t_parking_lots.latitude IS '緯度（例: 35.689487）';
COMMENT ON COLUMN t_parking_lots.longitude IS '経度（例: 139.691711）';
COMMENT ON COLUMN t_parking_lots.status IS '公開ステータス（例: 公開、非公開）';
COMMENT ON COLUMN t_parking_lots.start_date IS '駐車場の提供開始日';
COMMENT ON COLUMN t_parking_lots.end_date IS '提供終了日（任意）';
COMMENT ON COLUMN t_parking_lots.end_start_datetime IS '提供終了の開始日時（任意）';
COMMENT ON COLUMN t_parking_lots.end_end_datetime IS '提供終了の終了日時（任意）';
COMMENT ON COLUMN t_parking_lots.end_reason IS '提供終了理由（例: メンテナンス）';
COMMENT ON COLUMN t_parking_lots.end_reason_detail IS 'その他理由がある場合の詳細';
COMMENT ON COLUMN t_parking_lots.notes IS 'その他の備考';
COMMENT ON COLUMN t_parking_lots.created_datetime IS 'レコードの作成日時';
COMMENT ON COLUMN t_parking_lots.updated_datetime IS 'レコードの最終更新日時';


-- ===============================
-- 2. 駐車場制限情報テーブル
-- ===============================
CREATE TABLE t_parking_limits (
  parking_lot_id VARCHAR(37) PRIMARY KEY REFERENCES t_parking_lots(parking_lot_id) ON DELETE CASCADE,
  length_limit INTEGER,
  width_limit INTEGER,
  height_limit INTEGER,
  weight_limit INTEGER,
  car_height_limit VARCHAR(20),
  tire_width_limit VARCHAR(20),
  car_bottom_limit VARCHAR(20),
  created_datetime TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_datetime TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE t_parking_limits IS '駐車場ごとの車両制限情報を格納するテーブル';

COMMENT ON COLUMN t_parking_limits.parking_lot_id IS '対応する駐車場ID（t_parking_lots.parking_lot_id への外部キー）';
COMMENT ON COLUMN t_parking_limits.length_limit IS '車両の長さ制限（mm）';
COMMENT ON COLUMN t_parking_limits.width_limit IS '車両の幅制限（mm）';
COMMENT ON COLUMN t_parking_limits.height_limit IS '車両の高さ制限（mm）';
COMMENT ON COLUMN t_parking_limits.weight_limit IS '車両の重量制限（kg）';
COMMENT ON COLUMN t_parking_limits.car_height_limit IS '車高制限（例: ハイルーフ不可）';
COMMENT ON COLUMN t_parking_limits.tire_width_limit IS 'タイヤ幅制限（例: 195mm以下）';
COMMENT ON COLUMN t_parking_limits.car_bottom_limit IS '車下制限（例: エアロ不可）';
COMMENT ON COLUMN t_parking_limits.created_datetime IS 'レコード作成日時';
COMMENT ON COLUMN t_parking_limits.updated_datetime IS 'レコード更新日時';


-- ===============================
-- 3. 対応車種テーブル
-- ===============================
CREATE TABLE t_parking_vehicle_types (
  id SERIAL PRIMARY KEY,
  parking_lot_id VARCHAR(37) REFERENCES t_parking_lots(parking_lot_id) ON DELETE CASCADE,
  vehicle_type VARCHAR(50) NOT NULL,
  capacity INTEGER NOT NULL,
  created_datetime TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_datetime TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE t_parking_vehicle_types IS '駐車場ごとの対応車種情報（例: 軽自動車・中型車）';

COMMENT ON COLUMN t_parking_vehicle_types.id IS 'レコードID（連番）';
COMMENT ON COLUMN t_parking_vehicle_types.parking_lot_id IS '駐車場ID（外部キー）';
COMMENT ON COLUMN t_parking_vehicle_types.vehicle_type IS '対応車種の名称（例: 軽自動車）';
COMMENT ON COLUMN t_parking_vehicle_types.capacity IS '当該車種の収容可能台数';
COMMENT ON COLUMN t_parking_vehicle_types.created_datetime IS 'レコード作成日時';
COMMENT ON COLUMN t_parking_vehicle_types.updated_datetime IS 'レコード更新日時';


-- ===============================
-- 4. 駐車場画像テーブル
-- ===============================
CREATE TABLE t_parking_images (
  id SERIAL PRIMARY KEY,
  parking_lot_id VARCHAR(37) REFERENCES t_parking_lots(parking_lot_id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  created_datetime TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_datetime TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE t_parking_images IS '駐車場に紐づく画像情報を格納するテーブル';

COMMENT ON COLUMN t_parking_images.id IS 'レコードID（連番）';
COMMENT ON COLUMN t_parking_images.parking_lot_id IS '画像の対象となる駐車場ID（外部キー）';
COMMENT ON COLUMN t_parking_images.image_url IS '画像の保存先パスまたはURL';
COMMENT ON COLUMN t_parking_images.created_datetime IS 'レコード作成日時';
COMMENT ON COLUMN t_parking_images.updated_datetime IS 'レコード更新日時';
