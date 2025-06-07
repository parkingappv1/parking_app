import 'package:flutter/material.dart';
import 'package:parking_app/core/api/auth/auth_signin_api.dart';
import 'package:parking_app/core/client/dio_client.dart';
import 'package:parking_app/core/models/auth_signin_model.dart';
import 'package:parking_app/core/interceptors/app_token_service.dart';
import 'package:parking_app/core/interceptors/app_interceptor.dart';
import 'package:parking_app/views/common/widgets/error.dart';
import 'package:parking_app/core/utils/logger.dart'; // Import the logger

/// サインインサービス - ビジネスロジック層
///
/// API呼び出し、トークン管理、エラーハンドリングを統合
class AuthSigninService {
  late final AuthSignInApi _api;
  late final TokenService _tokenService;

  AuthSigninService() {
    // Create AppInterceptors with default TokenService implementation
    final appInterceptors = AppInterceptors(
      getToken: () => TokenService().getAccessToken(),
      refreshToken: () => TokenService().refreshToken(),
    );

    final dioClient = DioClient.withInterceptors(appInterceptors);
    _api = AuthSignInApi(dioClient);
    _tokenService = TokenService();
  }

  /// ユーザーサインイン
  ///
  /// [email] メールアドレスまたは電話番号
  /// [password] パスワード
  /// [rememberMe] ログイン状態を保持するかどうか
  /// [context] エラーダイアログ表示用のコンテキスト
  ///
  /// 戻り値: サインインに成功した場合はAuthSigninResponse、失敗した場合はnull
  Future<AuthSigninResponse?> signin({
    required String email,
    required String password,
    bool rememberMe = false,
    required BuildContext context,
  }) async {
    try {
      // 入力値の検証
      if (email.isEmpty) {
        _showErrorDialog(context, 'メールアドレスまたは電話番号を入力してください');
        return null;
      }

      if (password.isEmpty) {
        _showErrorDialog(context, 'パスワードを入力してください');
        return null;
      }

      // サインインモデルの作成
      final signinModel = AuthSigninModel(
        email: email.trim(),
        password: password,
        rememberMe: rememberMe,
      );

      appLogger.info('サインイン処理開始: ${signinModel.email}');

      // API呼び出し
      final response = await _api.signin(signinModel);

      if (response.isSuccess && response.data != null) {
        final signinResponse = response.data!;
        appLogger.info('サインイン成功: ${signinResponse.email}');

        // トークンの保存
        await _saveTokens(signinResponse, rememberMe);

        return signinResponse;
      } else {
        // APIエラーの場合
        final errorMessage = response.message ?? 'ログインに失敗しました';
        appLogger.error('サインインエラー: $errorMessage');
        _showErrorDialog(context, errorMessage);
        return null;
      }
    } catch (e, s) {
      appLogger.error('サインイン例外', e, s);
      _showErrorDialog(context, 'ネットワークエラーが発生しました。インターネット接続を確認してください');
      return null;
    }
  }

  /// パスワードリセットリクエスト
  ///
  /// [email] メールアドレス
  /// [context] エラーダイアログ表示用のコンテキスト
  ///
  /// 戻り値: リクエストが成功した場合はtrue
  Future<bool> requestPasswordReset({
    required String email,
    required BuildContext context,
  }) async {
    try {
      if (email.isEmpty) {
        _showErrorDialog(context, 'メールアドレスを入力してください');
        return false;
      }

      appLogger.info('パスワードリセットリクエスト開始: $email');

      final response = await _api.requestPasswordReset(email: email.trim());

      if (response.isSuccess) {
        appLogger.info('パスワードリセットリクエスト成功');
        return true;
      } else {
        final errorMessage = response.message ?? 'パスワードリセットリクエストに失敗しました';
        appLogger.error('パスワードリセットリクエストエラー: $errorMessage');
        _showErrorDialog(context, errorMessage);
        return false;
      }
    } catch (e, s) {
      appLogger.error('パスワードリセットリクエスト例外', e, s);
      _showErrorDialog(context, 'ネットワークエラーが発生しました');
      return false;
    }
  }

  /// パスワードリセット認証
  ///
  /// [email] メールアドレス
  /// [verificationCode] 認証コード
  /// [context] エラーダイアログ表示用のコンテキスト
  ///
  /// 戻り値: 認証が成功した場合はtrue
  Future<bool> verifyPasswordReset({
    required String email,
    required String verificationCode,
    required BuildContext context,
  }) async {
    try {
      if (email.isEmpty || verificationCode.isEmpty) {
        _showErrorDialog(context, 'メールアドレスと認証コードを入力してください');
        return false;
      }

      appLogger.info('パスワードリセット認証開始: $email');

      final response = await _api.verifyPasswordReset(
        email: email.trim(),
        verificationCode: verificationCode.trim(),
      );

      if (response.isSuccess) {
        appLogger.info('パスワードリセット認証成功');
        return true;
      } else {
        final errorMessage = response.message ?? '認証コードが正しくありません';
        appLogger.error('パスワードリセット認証エラー: $errorMessage');
        _showErrorDialog(context, errorMessage);
        return false;
      }
    } catch (e, s) {
      appLogger.error('パスワードリセット認証例外', e, s);
      _showErrorDialog(context, 'ネットワークエラーが発生しました');
      return false;
    }
  }

  /// パスワードリセット完了
  ///
  /// [email] メールアドレス
  /// [verificationCode] 認証コード
  /// [newPassword] 新しいパスワード
  /// [context] エラーダイアログ表示用のコンテキスト
  ///
  /// 戻り値: パスワードリセットが成功した場合はtrue
  Future<bool> completePasswordReset({
    required String email,
    required String verificationCode,
    required String newPassword,
    required BuildContext context,
  }) async {
    try {
      if (email.isEmpty || verificationCode.isEmpty || newPassword.isEmpty) {
        _showErrorDialog(context, 'すべてのフィールドを入力してください');
        return false;
      }

      // パスワードの検証
      if (newPassword.length < 8) {
        _showErrorDialog(context, 'パスワードは8文字以上で入力してください');
        return false;
      }

      appLogger.info('パスワードリセット完了開始: $email');

      final response = await _api.completePasswordReset(
        email: email.trim(),
        verificationCode: verificationCode.trim(),
        newPassword: newPassword,
      );

      if (response.isSuccess) {
        appLogger.info('パスワードリセット完了成功');
        return true;
      } else {
        final errorMessage = response.message ?? 'パスワードリセットに失敗しました';
        appLogger.error('パスワードリセット完了エラー: $errorMessage');
        _showErrorDialog(context, errorMessage);
        return false;
      }
    } catch (e, s) {
      appLogger.error('パスワードリセット完了例外', e, s);
      _showErrorDialog(context, 'ネットワークエラーが発生しました');
      return false;
    }
  }

  /// 現在のユーザーがログイン中かどうかを確認
  Future<bool> isLoggedIn() async {
    return await _tokenService.hasValidToken();
  }

  /// ログアウト
  Future<void> logout() async {
    await _tokenService.clearTokens();
    appLogger.info('ログアウト完了');
  }

  /// 現在のユーザー情報を取得
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final userInfo = await _tokenService.getUserInfo();
      return userInfo;
    } catch (e, s) {
      appLogger.error('ユーザー情報取得エラー', e, s);
      return null;
    }
  }

  /// トークンの保存
  Future<void> _saveTokens(AuthSigninResponse response, bool rememberMe) async {
    try {
      // JWTトークンの保存
      await _tokenService.saveToken(response.token);

      // リフレッシュトークンの保存
      await _tokenService.saveRefreshToken(response.refreshToken);

      // ユーザー情報の保存
      final userInfo = {
        'id': response.id,
        'email': response.email,
        'phone_number': response.phoneNumber,
        'is_owner': response.isOwner,
        'full_name': response.fullName,
      };
      await _tokenService.saveUserInfo(userInfo);

      appLogger.info('トークンとユーザー情報を保存しました');
    } catch (e, s) {
      appLogger.error('トークン保存エラー', e, s);
      throw Exception('ログイン情報の保存に失敗しました');
    }
  }

  /// エラーダイアログの表示
  void _showErrorDialog(BuildContext context, String message) {
    if (context.mounted) {
      ErrorDialog.showErrorDialog(
        context: context,
        title: 'エラー',
        message: message,
      );
    } else {
      appLogger.warning(
        'エラーダイアログ表示試行失敗: BuildContextがマウントされていません。メッセージ: $message',
      );
    }
  }

  /// 入力値のバリデーション
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'メールアドレスまたは電話番号を入力してください';
    }

    final trimmedValue = value.trim();

    // メールアドレスの形式チェック
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    // 電話番号の形式チェック（日本の電話番号形式）
    final phoneRegex = RegExp(r'^[0-9+\-\s()]{10,}$');

    if (!emailRegex.hasMatch(trimmedValue) &&
        !phoneRegex.hasMatch(trimmedValue)) {
      return '有効なメールアドレスまたは電話番号を入力してください';
    }

    return null;
  }

  /// パスワードのバリデーション
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'パスワードを入力してください';
    }

    if (value.length < 8) {
      return 'パスワードは8文字以上で入力してください';
    }

    return null;
  }
}
