// lib/core/models/auth_signup_model.dart
/// Represents the data sent to the server during the user registration process.
/// This model is constructed based on the fields in signup_screen.dart and the
/// requirements of the backend API, which in turn interacts with the database
/// tables m_login, m_users, and m_owners.
class AuthSignupModel {
  // --- m_login fields ---
  /// 論理名: メールアドレス
  final String email;

  /// 論理名: パスワード
  final String password;

  /// 論理名: 電話番号
  final String phoneNumber;

  /// 論理名: オーナー区分
  /// 'user' or 'owner'
  final String role;

  // --- m_users fields (for user role) ---
  /// 論理名: 氏名
  final String fullName;

  /// 論理名: 住所
  final String address;

  // --- m_owners fields (for owner role) ---
  /// 論理名: 登録者種別
  /// 例: 'individual', 'corporation', 'sole_proprietor', 'voluntary_organization'
  final String? registrantType;

  /// 論理名: 氏名（カナ）
  final String? fullNameKana;

  /// 論理名: 郵便番号
  final String? postalCode;

  /// 論理名: 備考
  final String? remarks;

  // --- Fields for client-side use, not necessarily sent to backend ---
  /// 論理名: プロモーションメール受信設定
  /// 1: 受け取る, 0: 受け取らない
  final int? promotionalEmailOptIn;

  /// 論理名: サービスメール受信設定
  /// 1: 受け取る, 0: 受け取らない
  final int? serviceEmailOptIn;

  // --- 追加: UI入力項目 ---
  /// 論理名: 生年月日 (YYYY-MM-DD 形式)
  final String? birthday;

  /// 論理名: 性別
  /// 'male', 'female', 'other'
  final String? gender;

  /// Creates a new AuthSignupModel instance.
  ///
  /// The [promotionalEmailOptIn] and [serviceEmailOptIn] can be provided as either:
  /// - Boolean values: true (converted to 1), false (converted to 0)
  /// - Integer values: directly as 1 (opt-in) or 0 (opt-out)
  AuthSignupModel({
    required this.email,
    required this.password,
    required this.phoneNumber,
    required this.role,
    required this.fullName,
    required this.address,
    dynamic promotionalEmailOptIn, // Accept dynamic for bool/int
    dynamic serviceEmailOptIn, // Accept dynamic for bool/int
    this.registrantType,
    this.fullNameKana, // Added
    this.postalCode, // Added
    this.remarks, // Added
    this.birthday,
    this.gender,
  }) : // Convert boolean values to integers if provided as boolean, otherwise use as int?
       promotionalEmailOptIn =
           promotionalEmailOptIn is bool
               ? (promotionalEmailOptIn ? 1 : 0)
               : (promotionalEmailOptIn as int?),
       serviceEmailOptIn =
           serviceEmailOptIn is bool
               ? (serviceEmailOptIn ? 1 : 0)
               : (serviceEmailOptIn as int?) {
    // Basic validation:
    if (role == 'owner') {
      if (registrantType == null || registrantType!.isEmpty) {
        throw ArgumentError('registrantType is required when role is "owner".');
      }
      if (postalCode == null || postalCode!.isEmpty) {
        throw ArgumentError('postalCode is required when role is "owner".');
      }
    } else if (role != 'user') {
      throw ArgumentError('role must be either "user" or "owner".');
    }
  }

  /// Converts the [AuthSignupModel] object into a JSON map suitable for sending to the API.
  /// The backend API will use this data to populate m_login and either m_users or m_owners.
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'email': email,
      'password': password,
      'phone_number': phoneNumber,
      // 'role': role, // Role is determined by the endpoint, not sent in payload
      'full_name': fullName,
      'address': address,
    };

    if (role == 'owner') {
      data['registrant_type'] = registrantType;
      if (fullNameKana != null) {
        data['full_name_kana'] = fullNameKana;
      }
      data['postal_code'] =
          postalCode; // Already validated as non-null for owner
      if (remarks != null) {
        data['remarks'] = remarks;
      }
      // Note: promotionalEmailOptIn and serviceEmailOptIn are not typically owner-specific.
      // If they were, they'd be added here.
    } else if (role == 'user') {
      // promotional_email_opt_in and service_email_opt_in are NOT sent to the backend
      // for user registration as per UserSignupRequest in Rust.
      // They are only for client-side use via the helper methods.
    }

    // Common optional fields for both user and owner (sent to backend if present)
    if (birthday != null) {
      data['birthday'] = birthday;
    }
    if (gender != null) {
      data['gender'] = gender;
    }

    return data;
  }

  /// Helper method to check if promotional emails are enabled
  bool isPromotionalEmailEnabled() {
    return promotionalEmailOptIn == 1;
  }

  /// Helper method to check if service emails are enabled
  bool isServiceEmailEnabled() {
    return serviceEmailOptIn == 1;
  }
}
