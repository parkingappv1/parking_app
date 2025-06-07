import 'package:flutter/foundation.dart';
import 'package:parking_app/core/api/api_response.dart';
import 'package:parking_app/core/api/auth/auth_signup_api.dart';
import 'package:parking_app/core/models/auth_signup_model.dart';

/// サインアップサービス - 上位レベルのビジネスロジック層
/// API層を使用してデータ変換、バリデーション、エラーハンドリングを処理
class AuthSignUpService extends ChangeNotifier {
  final AuthSignUpApi _api;

  // Provider 用: AuthSignUpApi を引数で受け取る
  AuthSignUpService(this._api);

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  /// サインアップ処理を実行
  /// フォームデータをモデルに変換してAPI呼び出し、レスポンス処理
  Future<ApiResponse> signup({
    required String email,
    required String password,
    required String phoneNumber,
    required String role,
    required String fullName,
    required String address,
    required bool promotionalEmailOptIn,
    required bool serviceEmailOptIn,
    String? registrantType,
    String? fullNameKana,
    String? postalCode,
    String? remarks,
    String? birthday,
    required String gender,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (kDebugMode) {
        debugPrint('🚀 サインアップサービス開始');
        debugPrint('📧 メール: $email, ロール: $role');
      }

      // 入力データのバリデーション
      final validationError = _validateSignupData(
        email: email,
        password: password,
        phoneNumber: phoneNumber,
        role: role,
        fullName: fullName,
        address: address,
        gender: gender,
      );

      if (validationError != null) {
        if (kDebugMode) {
          debugPrint('❌ バリデーションエラー: $validationError');
        }
        _error = validationError;
        _isLoading = false;
        notifyListeners();
        return ApiResponse.error(validationError);
      }

      // モデル作成
      final signupModel = AuthSignupModel(
        email: email,
        password: password,
        phoneNumber: phoneNumber,
        role: role,
        fullName: fullName,
        address: address,
        promotionalEmailOptIn: promotionalEmailOptIn,
        serviceEmailOptIn: serviceEmailOptIn,
        registrantType: registrantType,
        fullNameKana: fullNameKana,
        postalCode: postalCode,
        remarks: remarks,
        birthday: birthday,
        gender: gender,
      );

      // API層を使用してサインアップ実行
      final apiResponse = await _api.signup(signupModel);

      if (apiResponse.isSuccess) {
        if (kDebugMode) {
          debugPrint('✅ サインアップサービス成功');
        }

        _isLoading = false;
        notifyListeners();
        return ApiResponse.success(
          apiResponse.data,
          message: _getSuccessMessage(role),
        );
      } else {
        if (kDebugMode) {
          debugPrint('❌ サインアップサービス失敗: ${apiResponse.message}');
        }

        _error = _enhanceErrorMessage(apiResponse.message ?? 'サインアップに失敗しました');
        _isLoading = false;
        notifyListeners();
        return ApiResponse.error(
          _enhanceErrorMessage(apiResponse.message ?? 'サインアップに失敗しました'),
          code: apiResponse.statusCode,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('💥 サインアップサービス予期しないエラー: $e');
      }

      _error = 'サインアップ処理中に予期しないエラーが発生しました';
      _isLoading = false;
      notifyListeners();
      return ApiResponse.error('サインアップ処理中に予期しないエラーが発生しました');
    }
  }

  /// メール認証コードを検証
  Future<ApiResponse> verifyEmail({
    required String email,
    required String verificationCode,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('📧 メール認証サービス開始: $email');
      }

      // 入力バリデーション
      if (email.isEmpty) {
        return ApiResponse.error('メールアドレスを入力してください');
      }

      if (verificationCode.isEmpty) {
        return ApiResponse.error('認証コードを入力してください');
      }

      if (!_isValidEmail(email)) {
        return ApiResponse.error('有効なメールアドレスを入力してください');
      }

      if (verificationCode.length < 4) {
        return ApiResponse.error('認証コードは4文字以上で入力してください');
      }

      // API層を使用してメール認証実行
      final apiResponse = await _api.verifyEmail(
        email: email,
        verificationCode: verificationCode,
      );

      if (apiResponse.isSuccess) {
        if (kDebugMode) {
          debugPrint('✅ メール認証サービス成功');
        }

        return ApiResponse.success(
          apiResponse.data,
          message: 'メール認証が完了しました。ログインできます。',
        );
      } else {
        return ApiResponse.error(
          _enhanceErrorMessage(apiResponse.message ?? 'メール認証に失敗しました'),
          code: apiResponse.statusCode,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('💥 メール認証サービスエラー: $e');
      }

      return ApiResponse.error('メール認証中に予期しないエラーが発生しました');
    }
  }

  /// メール認証コードを再送信
  Future<ApiResponse> resendVerificationCode(String email) async {
    try {
      if (kDebugMode) {
        debugPrint('🔄 認証コード再送信サービス開始: $email');
      }

      // 入力バリデーション
      if (email.isEmpty) {
        return ApiResponse.error('メールアドレスを入力してください');
      }

      if (!_isValidEmail(email)) {
        return ApiResponse.error('有効なメールアドレスを入力してください');
      }

      // API層を使用して再送信実行
      final apiResponse = await _api.resendVerificationCode(email);

      if (apiResponse.isSuccess) {
        if (kDebugMode) {
          debugPrint('✅ 認証コード再送信サービス成功');
        }

        return ApiResponse.success(
          apiResponse.data,
          message: '認証コードを再送信しました。メールをご確認ください。',
        );
      } else {
        return ApiResponse.error(
          _enhanceErrorMessage(apiResponse.message ?? '認証コードの再送信に失敗しました'),
          code: apiResponse.statusCode,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('💥 認証コード再送信サービスエラー: $e');
      }

      return ApiResponse.error('認証コード再送信中に予期しないエラーが発生しました');
    }
  }

  // ===== プライベートヘルパーメソッド =====

  /// サインアップデータの包括的バリデーション
  String? _validateSignupData({
    required String email,
    required String password,
    required String phoneNumber,
    required String role,
    required String fullName,
    required String address,
    required String gender,
  }) {
    // 必須フィールドチェック
    if (email.isEmpty) return 'メールアドレスを入力してください';
    if (password.isEmpty) return 'パスワードを入力してください';
    if (phoneNumber.isEmpty) return '電話番号を入力してください';
    if (role.isEmpty) return 'ユーザータイプを選択してください';
    if (fullName.isEmpty) return '氏名を入力してください';
    if (address.isEmpty) return '住所を入力してください';
    if (gender.isEmpty) return '性別を選択してください';

    // フォーマットバリデーション
    if (!_isValidEmail(email)) return '有効なメールアドレスを入力してください';
    if (!_isValidPassword(password)) return 'パスワードは6文字以上、大小英字・数字を含む必要があります';
    if (!_isValidPhoneNumber(phoneNumber)) return '有効な電話番号を入力してください（10-15桁）';
    if (!_isValidRole(role)) return 'ユーザータイプは「user」または「owner」を選択してください';
    if (!_isValidGender(gender)) return '性別は「male」、「female」、「other」から選択してください';

    return null; // バリデーション成功
  }

  /// メールアドレス形式チェック
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// パスワード強度チェック
  bool _isValidPassword(String password) {
    if (password.length < 6) return false;
    // 大文字、小文字、数字を含む
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasDigits = password.contains(RegExp(r'[0-9]'));
    return hasUppercase && hasLowercase && hasDigits;
  }

  /// 電話番号形式チェック
  bool _isValidPhoneNumber(String phoneNumber) {
    final phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
    final numbersOnly = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    return phoneRegex.hasMatch(numbersOnly);
  }

  /// ロール有効性チェック
  bool _isValidRole(String role) {
    return role == 'user' || role == 'owner';
  }

  /// 性別有効性チェック
  bool _isValidGender(String gender) {
    return ['male', 'female', 'other'].contains(gender);
  }

  /// 成功メッセージをロールに応じてカスタマイズ
  String _getSuccessMessage(String role) {
    switch (role) {
      case 'user':
        return 'ユーザー登録が完了しました。メール認証を行ってください。';
      case 'owner':
        return 'オーナー登録が完了しました。メール認証後、駐車場の登録が可能になります。';
      default:
        return '登録が完了しました。メール認証を行ってください。';
    }
  }

  /// エラーメッセージをユーザーフレンドリーに変換
  String _enhanceErrorMessage(String originalMessage) {
    final lowerMessage = originalMessage.toLowerCase();

    // 一般的なAPIエラーの日本語化
    if (lowerMessage.contains('duplicate') ||
        lowerMessage.contains('already exists')) {
      return 'このメールアドレスは既に登録されています';
    }

    if (lowerMessage.contains('invalid email')) {
      return 'メールアドレスの形式が正しくありません';
    }

    if (lowerMessage.contains('password')) {
      return 'パスワードの要件を満たしていません';
    }

    if (lowerMessage.contains('phone')) {
      return '電話番号の形式が正しくありません';
    }

    if (lowerMessage.contains('network') ||
        lowerMessage.contains('connection')) {
      return 'ネットワーク接続を確認してください';
    }

    if (lowerMessage.contains('timeout')) {
      return '通信がタイムアウトしました。しばらくしてから再度お試しください';
    }

    if (lowerMessage.contains('server error')) {
      return 'サーバーで問題が発生しています。しばらくしてから再度お試しください';
    }

    // 元のメッセージを返す（すでに日本語の可能性もある）
    return originalMessage;
  }
}
