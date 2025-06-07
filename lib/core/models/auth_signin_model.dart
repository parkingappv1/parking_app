import 'package:json_annotation/json_annotation.dart';

part 'auth_signin_model.g.dart';

/// サインインリクエストモデル
///
/// メールアドレスまたは電話番号でのログインをサポート
@JsonSerializable()
class AuthSigninModel {
  /// メールアドレス（メールでログインする場合）
  final String email;

  /// パスワード
  final String password;

  /// ログイン状態を保持するかどうか
  @JsonKey(defaultValue: false)
  final bool rememberMe;

  const AuthSigninModel({
    required this.email,
    required this.password,
    this.rememberMe = false,
  });

  /// JSONからインスタンスを作成
  factory AuthSigninModel.fromJson(Map<String, dynamic> json) =>
      _$AuthSigninModelFromJson(json);

  /// インスタンスをJSONに変換
  Map<String, dynamic> toJson() => _$AuthSigninModelToJson(this);

  /// 電話番号でのログイン用コンストラクタ
  factory AuthSigninModel.withPhone({
    required String phoneNumber,
    required String password,
    bool rememberMe = false,
  }) {
    return AuthSigninModel(
      // バックエンドでemailフィールドとして電話番号を送信
      email: phoneNumber,
      password: password,
      rememberMe: rememberMe,
    );
  }

  /// メールアドレスでのログイン用コンストラクタ
  factory AuthSigninModel.withEmail({
    required String email,
    required String password,
    bool rememberMe = false,
  }) {
    return AuthSigninModel(
      email: email,
      password: password,
      rememberMe: rememberMe,
    );
  }

  /// バリデーション
  bool get isValid {
    return email.isNotEmpty && password.isNotEmpty;
  }

  /// メールアドレスかどうかを判定
  bool get isEmail {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
  }

  /// 電話番号かどうかを判定
  bool get isPhoneNumber {
    return RegExp(r'^[0-9+\-\s()]+$').hasMatch(email) && email.length >= 10;
  }

  @override
  String toString() {
    return 'AuthSigninModel(email: $email, rememberMe: $rememberMe)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthSigninModel &&
        other.email == email &&
        other.password == password &&
        other.rememberMe == rememberMe;
  }

  @override
  int get hashCode {
    return email.hashCode ^ password.hashCode ^ rememberMe.hashCode;
  }
}

/// サインインレスポンスモデル
///
/// バックエンドからのレスポンスデータを格納
@JsonSerializable()
class AuthSigninResponse {
  /// ユーザーID（UUID）
  final String id;

  /// メールアドレス
  final String email;

  /// 電話番号
  @JsonKey(name: 'phone_number')
  final String phoneNumber;

  /// オーナーかどうか
  @JsonKey(name: 'is_owner')
  final bool isOwner;

  /// 氏名
  @JsonKey(name: 'full_name')
  final String fullName;

  /// JWTトークン
  final String token;

  /// リフレッシュトークン
  @JsonKey(name: 'refresh_token')
  final String refreshToken;

  const AuthSigninResponse({
    required this.id,
    required this.email,
    required this.phoneNumber,
    required this.isOwner,
    required this.fullName,
    required this.token,
    required this.refreshToken,
  });

  /// JSONからインスタンスを作成
  factory AuthSigninResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthSigninResponseFromJson(json);

  /// インスタンスをJSONに変換
  Map<String, dynamic> toJson() => _$AuthSigninResponseToJson(this);

  @override
  String toString() {
    return 'AuthSigninResponse(id: $id, email: $email, isOwner: $isOwner, fullName: $fullName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthSigninResponse &&
        other.id == id &&
        other.email == email &&
        other.phoneNumber == phoneNumber &&
        other.isOwner == isOwner &&
        other.fullName == fullName &&
        other.token == token &&
        other.refreshToken == refreshToken;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        email.hashCode ^
        phoneNumber.hashCode ^
        isOwner.hashCode ^
        fullName.hashCode ^
        token.hashCode ^
        refreshToken.hashCode;
  }
}
