import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:parking_app/core/utils/logger.dart'; // Import the logger

/// API通信に関連する定数値を管理するクラス
class ApiConstants {
  // ==================== 基本設定 ====================

  /// APIバージョン
  static const String API_VERSION = 'v1';

  /// ベースURL - .env設定から動的に構築
  static final String BASE_URL = _buildBaseUrl();

  // ==================== URL構築ロジック ====================

  /// 基礎URLを構築 - .env設定を優先使用
  static String _buildBaseUrl() {
    // 直接指定されたバックエンドURLを最優先
    final backendUrl = dotenv.env['FLUTTER_APP_BACKEND_URL'];

    if (kDebugMode) {
      appLogger.debug('=== API設定デバッグ情報 ===');
      appLogger.debug('FLUTTER_APP_BACKEND_URL: $backendUrl');
      appLogger.debug(
        'FLUTTER_APP_BACKEND_DEBUG_URL: ${dotenv.env['FLUTTER_APP_BACKEND_DEBUG_URL']}',
      );
      appLogger.debug(
        'FLUTTER_APP_BACKEND_RELEASE_URL: ${dotenv.env['FLUTTER_APP_BACKEND_RELEASE_URL']}',
      );
    }

    String selectedUrl;

    if (backendUrl?.isNotEmpty == true) {
      selectedUrl = backendUrl!;
    } else {
      // フォールバック: デバッグ/リリース専用URL
      final debugUrl = dotenv.env['FLUTTER_APP_BACKEND_DEBUG_URL'];
      final releaseUrl = dotenv.env['FLUTTER_APP_BACKEND_RELEASE_URL'];

      final envUrl = kDebugMode ? debugUrl : releaseUrl;
      if (envUrl?.isEmpty ?? true) {
        throw Exception('.envファイルにバックエンドURLが設定されていません');
      }
      selectedUrl = envUrl!;
    }

    // API パス形式の正規化
    final normalizedUrl =
        selectedUrl.endsWith('/')
            ? selectedUrl.substring(0, selectedUrl.length - 1)
            : selectedUrl;

    final result =
        normalizedUrl.contains('/$API_VERSION/api')
            ? normalizedUrl
            : '$normalizedUrl/$API_VERSION/api';

    if (kDebugMode) {
      appLogger.debug('構築されたベースURL: $result');
      appLogger.debug('=============================');
    }

    return result;
  }

  // ==================== タイムアウト設定 ====================

  /// 接続タイムアウト (ミリ秒)
  static const int CONNECT_TIMEOUT = 30000;

  /// 受信タイムアウト (ミリ秒)
  static const int RECEIVE_TIMEOUT = 30000;

  /// 送信タイムアウト (ミリ秒)
  static const int SEND_TIMEOUT = 30000;

  // ==================== HTTP設定 ====================

  /// 状態を変更しない安全なHTTPメソッド
  static const List<String> SAFE_METHODS = ['GET', 'HEAD', 'OPTIONS', 'TRACE'];

  // ==================== 認証関連エンドポイント ====================

  /// 認証ベースパス
  static const String AUTH_BASE = '/auth';

  /// サインイン
  static const String SIGNIN = '$AUTH_BASE/signin';

  /// サインアウト
  static const String SIGNOUT = '$AUTH_BASE/signout';

  /// トークンリフレッシュ
  static const String REFRESH_TOKEN = '$AUTH_BASE/refresh-token';

  /// CSRFトークン取得
  static const String CSRF_TOKEN = '$AUTH_BASE/csrf-token';

  // ==================== 登録関連エンドポイント ====================

  /// 一般ユーザー登録
  static const String REGISTER_USER = '$AUTH_BASE/signup/user';

  /// 駐車場オーナー登録
  static const String REGISTER_OWNER = '$AUTH_BASE/signup/owner';

  // ==================== 認証確認エンドポイント ====================

  /// コード認証
  static const String VERIFY_CODE = '$AUTH_BASE/verify-code';

  /// コード再送信
  static const String RESEND_CODE = '$AUTH_BASE/resend-code';

  /// パスワードリセット要求
  static const String PASSWORD_RESET_REQUEST =
      '$AUTH_BASE/password-reset-request';

  /// パスワードリセット認証
  static const String PASSWORD_RESET_VERIFY =
      '$AUTH_BASE/password-reset-verify';

  /// パスワードリセット完了
  static const String PASSWORD_RESET_COMPLETE =
      '$AUTH_BASE/password-reset-complete';

  // ==================== 開発環境用設定 ====================

  /// 開発環境用固定CSRFトークン (サーバー取得失敗時のフォールバック)
  static const String DEVELOPMENT_CSRF_TOKEN =
      'BlShzBuQSbEmx9jJictkKeKEUpa9OYmH-1747923404';

  // ==================== ユーザープロファイルエンドポイント ====================

  /// ユーザーベースパス
  static const String USER_BASE = '/user';

  /// ユーザー情報取得
  static const String USER_INFO = '$USER_BASE/info';

  /// ユーザー情報更新
  static const String UPDATE_USER = '$USER_BASE/update';

  /// パスワード変更
  static const String CHANGE_PASSWORD = '$USER_BASE/change-password';

  /// アバター画像アップロード
  static const String UPLOAD_AVATAR = '$USER_BASE/upload-avatar';

  // ==================== 駐車場関連エンドポイント ====================

  /// 駐車場ベースパス
  static const String PARKING_BASE = '/parking';

  /// 駐車場検索
  static const String PARKING_SEARCH = '$PARKING_BASE/search';

  /// 駐車場詳細
  static const String PARKING_DETAILS = '$PARKING_BASE/details';

  /// 駐車場予約
  static const String PARKING_RESERVE = '$PARKING_BASE/reserve';

  /// 予約キャンセル
  static const String PARKING_CANCEL = '$PARKING_BASE/cancel';

  /// 利用履歴
  static const String PARKING_HISTORY = '$PARKING_BASE/history';

  // ==================== APIレスポンス構造 ====================

  /// 成功フラグキー
  static const String RESPONSE_SUCCESS_KEY = 'success';

  /// データキー
  static const String RESPONSE_DATA_KEY = 'data';

  /// メッセージキー
  static const String RESPONSE_MESSAGE_KEY = 'message';

  /// エラーキー
  static const String RESPONSE_ERROR_KEY = 'error';

  /// コードキー
  static const String RESPONSE_CODE_KEY = 'code';

  // ==================== クエリパラメータ ====================

  /// ページ番号
  static const String PARAM_PAGE = 'page';

  /// ページ単位件数
  static const String PARAM_PER_PAGE = 'per_page';

  /// ソート基準
  static const String PARAM_SORT_BY = 'sort_by';

  /// ソート順序
  static const String PARAM_ORDER = 'order';

  /// 検索キーワード
  static const String PARAM_SEARCH = 'search';

  /// フィルター条件
  static const String PARAM_FILTER = 'filter';

  // ==================== デフォルト値 ====================

  /// デフォルトページ番号
  static const int DEFAULT_PAGE = 1;

  /// デフォルトページ単位件数
  static const int DEFAULT_PER_PAGE = 20;

  /// デフォルトキャッシュ持続時間
  static const Duration DEFAULT_CACHE_DURATION = Duration(minutes: 5);

  // ==================== ユーティリティメソッド ====================

  /// デバッグ用: 完全なエンドポイントURLを取得
  static String getFullUrl(String endpoint) {
    final fullUrl = '$BASE_URL$endpoint';
    if (kDebugMode) {
      appLogger.debug('完全エンドポイントURL: $fullUrl');
    }
    return fullUrl;
  }
}
