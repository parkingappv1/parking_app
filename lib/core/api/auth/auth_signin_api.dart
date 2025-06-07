import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:parking_app/core/api/api_constants.dart';
import 'package:parking_app/core/api/api_response.dart';
import 'package:parking_app/core/client/dio_client.dart';
import 'package:parking_app/core/models/auth_signin_model.dart';

/// サインインAPI - DioClientを使用した統一されたAPI層
/// 認証不要のサインイン関連エンドポイントを提供
class AuthSignInApi {
  final DioClient _client;

  AuthSignInApi(this._client);

  /// ユーザーサインイン
  ///
  /// メールアドレスまたは電話番号でのログインをサポート
  Future<ApiResponse<AuthSigninResponse>> signin(
    AuthSigninModel signinModel,
  ) async {
    try {
      // 必須フィールドの検証
      if (signinModel.email.isEmpty) {
        return ApiResponse.error("メールアドレスまたは電話番号は必須です");
      }
      if (signinModel.password.isEmpty) {
        return ApiResponse.error("パスワードは必須です");
      }

      debugPrint('サインインリクエスト送信: ${signinModel.toJson()}');

      final response = await _client.post(
        ApiConstants.SIGNIN,
        data: signinModel.toJson(),
        requiresAuth: false, // サインインは認証不要
      );

      debugPrint('サインインレスポンス: ${response.data}');

      // レスポンスデータの型チェック
      if (response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;

        // data フィールドが存在する場合はそれを使用、そうでなければ全体を使用
        final userData = responseData['data'] ?? responseData;

        if (userData is Map<String, dynamic>) {
          final signinResponse = AuthSigninResponse.fromJson(userData);
          return ApiResponse.success(signinResponse);
        } else {
          return ApiResponse.error("無効なレスポンスデータ形式です");
        }
      } else {
        return ApiResponse.error("無効なレスポンス形式です");
      }
    } catch (e) {
      debugPrint('サインインエラー: $e');
      if (e is DioException && e.response != null) {
        // サーバーからのエラーレスポンスを処理
        final statusCode = e.response!.statusCode;
        String errorMessage = 'ログインに失敗しました';

        if (e.response!.data is Map<String, dynamic>) {
          final errorData = e.response!.data as Map<String, dynamic>;
          errorMessage = errorData['message'] ?? errorMessage;
        }

        // ステータスコードに応じたエラーメッセージ
        switch (statusCode) {
          case 401:
            errorMessage = 'メールアドレス・電話番号またはパスワードが正しくありません';
            break;
          case 403:
            errorMessage = 'アカウントがロックされています。しばらく時間をおいてから再度お試しください';
            break;
          case 429:
            errorMessage = 'ログイン試行回数が上限に達しました。しばらく時間をおいてから再度お試しください';
            break;
          case 500:
            errorMessage = 'サーバーエラーが発生しました。しばらく時間をおいてから再度お試しください';
            break;
        }

        return ApiResponse.error(errorMessage, code: statusCode);
      }

      // ネットワークエラーなどの場合
      return ApiResponse.error('ネットワークエラーが発生しました。インターネット接続を確認してください');
    }
  }

  /// パスワードリセットリクエスト
  Future<ApiResponse> requestPasswordReset({required String email}) async {
    try {
      if (email.isEmpty) {
        return ApiResponse.error("メールアドレスは必須です");
      }

      debugPrint('パスワードリセットリクエスト送信: $email');

      final response = await _client.post(
        ApiConstants.PASSWORD_RESET_REQUEST,
        data: {'email': email},
        requiresAuth: false, // パスワードリセットは認証不要
      );

      debugPrint('パスワードリセットレスポンス: ${response.data}');

      // レスポンスデータの型チェック
      if (response.data is Map<String, dynamic>) {
        return ApiResponse.fromJson(response.data, (data) => data);
      } else {
        return ApiResponse.success(response.data);
      }
    } catch (e) {
      debugPrint('パスワードリセットエラー: $e');
      if (e is DioException && e.response != null) {
        final statusCode = e.response!.statusCode;
        String errorMessage = 'パスワードリセットに失敗しました';

        if (e.response!.data is Map<String, dynamic>) {
          final errorData = e.response!.data as Map<String, dynamic>;
          errorMessage = errorData['message'] ?? errorMessage;
        }

        return ApiResponse.error(errorMessage, code: statusCode);
      }
      return ApiResponse.error(e.toString());
    }
  }

  /// パスワードリセット認証
  Future<ApiResponse> verifyPasswordReset({
    required String email,
    required String verificationCode,
  }) async {
    try {
      if (email.isEmpty || verificationCode.isEmpty) {
        return ApiResponse.error("メールアドレスと認証コードは必須です");
      }

      debugPrint('パスワードリセット認証リクエスト送信: $email');

      final response = await _client.post(
        ApiConstants.PASSWORD_RESET_VERIFY,
        data: {'email': email, 'verificationCode': verificationCode},
        requiresAuth: false,
      );

      debugPrint('パスワードリセット認証レスポンス: ${response.data}');

      if (response.data is Map<String, dynamic>) {
        return ApiResponse.fromJson(response.data, (data) => data);
      } else {
        return ApiResponse.success(response.data);
      }
    } catch (e) {
      debugPrint('パスワードリセット認証エラー: $e');
      if (e is DioException && e.response != null) {
        return ApiResponse.error(
          'パスワードリセット認証に失敗しました',
          code: e.response!.statusCode,
        );
      }
      return ApiResponse.error(e.toString());
    }
  }

  /// パスワードリセット完了
  Future<ApiResponse> completePasswordReset({
    required String email,
    required String verificationCode,
    required String newPassword,
  }) async {
    try {
      if (email.isEmpty || verificationCode.isEmpty || newPassword.isEmpty) {
        return ApiResponse.error("すべてのフィールドは必須です");
      }

      debugPrint('パスワードリセット完了リクエスト送信: $email');

      final response = await _client.post(
        ApiConstants.PASSWORD_RESET_COMPLETE,
        data: {
          'email': email,
          'verificationCode': verificationCode,
          'newPassword': newPassword,
        },
        requiresAuth: false,
      );

      debugPrint('パスワードリセット完了レスポンス: ${response.data}');

      if (response.data is Map<String, dynamic>) {
        return ApiResponse.fromJson(response.data, (data) => data);
      } else {
        return ApiResponse.success(response.data);
      }
    } catch (e) {
      debugPrint('パスワードリセット完了エラー: $e');
      if (e is DioException && e.response != null) {
        return ApiResponse.error(
          'パスワードリセットに失敗しました',
          code: e.response!.statusCode,
        );
      }
      return ApiResponse.error(e.toString());
    }
  }
}
