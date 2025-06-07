import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:parking_app/core/api/api_constants.dart';
import 'package:parking_app/core/api/api_response.dart';
import 'package:parking_app/core/client/dio_client.dart';
import 'package:parking_app/core/models/auth_signup_model.dart';

/// サインアップAPI - DioClientを使用した統一されたAPI層
/// 認証不要のサインアップ関連エンドポイントを提供
class AuthSignUpApi {
  final DioClient _client;

  /// デフォルトコンストラクタ - 独自のDioClientインスタンスを作成
  AuthSignUpApi() : _client = DioClient();

  /// 依存性注入用のネームドコンストラクタ
  AuthSignUpApi.withClient(DioClient client) : _client = client;

  /// ユーザーサインアップ
  Future<ApiResponse> signup(AuthSignupModel signupModel) async {
    try {
      // 必須フィールドの検証
      if (signupModel.email.isEmpty) {
        return ApiResponse.error("メールアドレスは必須です");
      }
      if (signupModel.password.isEmpty) {
        return ApiResponse.error("パスワードは必須です");
      }

      debugPrint('サインアップリクエスト送信: ${signupModel.toJson()}');

      final response = await _client.post(
        ApiConstants.REGISTER_USER,
        data: signupModel.toJson(),
        requiresAuth: false, // サインアップは認証不要
      );

      debugPrint('サインアップレスポンス: ${response.data}');

      // レスポンスデータの型チェック
      if (response.data is Map<String, dynamic>) {
        return ApiResponse.fromJson(
          response.data,
          (data) => data, // 生データを返し、サービス層で処理
        );
      } else if (response.data is String) {
        // 文字列レスポンスの場合
        return ApiResponse.success(response.data);
      } else {
        // その他の型の場合
        return ApiResponse.success(response.data);
      }
    } catch (e) {
      debugPrint('サインアップエラー: $e');
      if (e is DioException && e.response != null) {
        return ApiResponse.error(
          'エラー: ${e.response!.statusCode} - ${e.response!.statusMessage ?? e.message}',
          code: e.response!.statusCode,
        );
      }
      return ApiResponse.error(e.toString());
    }
  }

  /// メール認証
  Future<ApiResponse> verifyEmail({
    required String email,
    required String verificationCode,
  }) async {
    try {
      if (email.isEmpty || verificationCode.isEmpty) {
        return ApiResponse.error("メールアドレスと認証コードは必須です");
      }

      debugPrint('メール認証リクエスト送信: $email');

      final response = await _client.post(
        ApiConstants.VERIFY_CODE,
        data: {'email': email, 'verificationCode': verificationCode},
        requiresAuth: false, // メール認証は認証不要
      );

      debugPrint('メール認証レスポンス: ${response.data}');

      // レスポンスデータの型チェック
      if (response.data is Map<String, dynamic>) {
        return ApiResponse.fromJson(response.data, (data) => data);
      } else {
        return ApiResponse.success(response.data);
      }
    } catch (e) {
      debugPrint('メール認証エラー: $e');
      if (e is DioException && e.response != null) {
        return ApiResponse.error(
          'エラー: ${e.response!.statusCode} - ${e.response!.statusMessage ?? e.message}',
          code: e.response!.statusCode,
        );
      }
      return ApiResponse.error(e.toString());
    }
  }

  /// 認証コード再送信
  Future<ApiResponse> resendVerificationCode(String email) async {
    try {
      if (email.isEmpty) {
        return ApiResponse.error("メールアドレスは必須です");
      }

      debugPrint('認証コード再送信リクエスト送信: $email');

      final response = await _client.post(
        ApiConstants.RESEND_CODE,
        data: {'email': email},
        requiresAuth: false, // 認証コード再送信は認証不要
      );

      debugPrint('認証コード再送信レスポンス: ${response.data}');

      // レスポンスデータの型チェック
      if (response.data is Map<String, dynamic>) {
        return ApiResponse.fromJson(response.data, (data) => data);
      } else {
        return ApiResponse.success(response.data);
      }
    } catch (e) {
      debugPrint('認証コード再送信エラー: $e');
      if (e is DioException && e.response != null) {
        return ApiResponse.error(
          'エラー: ${e.response!.statusCode} - ${e.response!.statusMessage ?? e.message}',
          code: e.response!.statusCode,
        );
      }
      return ApiResponse.error(e.toString());
    }
  }

  /// フォーム検証用の静的メソッド
  static String? validateEmail(String? value, BuildContext context) {
    // final l10n = Localizations.of(context);
    if (value == null || value.isEmpty) {
      return 'メールアドレスは必須です';
    }
    final emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegExp.hasMatch(value)) {
      return 'メールアドレスが正しくありません';
    }
    return null;
  }

  static String? validatePassword(String? value, BuildContext context) {
    // final l10n = Localizations.of(context);
    if (value == null || value.isEmpty) {
      return 'パスワードは必須です';
    }
    if (value.length < 6) {
      return 'パスワードは6文字以上である必要があります';
    }
    return null;
  }

  static String? validatePhone(String? value, BuildContext context) {
    // final l10n = Localizations.of(context);
    if (value == null || value.isEmpty) {
      return '電話番号は必須です';
    }
    final phoneRegExp = RegExp(r'^\d{10,15}$');
    if (!phoneRegExp.hasMatch(value.replaceAll(RegExp(r'[^0-9]'), ''))) {
      return '電話番号が正しくありません';
    }
    return null;
  }
}
