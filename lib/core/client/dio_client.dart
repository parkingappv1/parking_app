import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:parking_app/core/api/api_constants.dart';
import 'package:parking_app/core/api/api_client.dart';
import 'package:parking_app/core/interceptors/app_interceptor.dart';
import 'package:parking_app/core/security/csrf_token_provider.dart';
import 'package:parking_app/core/interceptors/app_token_service.dart';

/// Dioを使用したHTTPクライアントの実装
/// 共通のAPI通信、認証、CSRF保護を処理します
class DioClient implements ApiClient {
  static DioClient? _instance;
  final Dio _dio;
  final CsrfTokenProvider _csrfTokenProvider;
  final TokenService _tokenService;

  /// 無パラメータファクトリコンストラクタ - デフォルトのAppInterceptorsを使用
  factory DioClient() {
    return DioClient.withInterceptors(AppInterceptors());
  }

  /// AppInterceptorsを指定するファクトリコンストラクタ
  factory DioClient.withInterceptors(AppInterceptors appInterceptors) {
    _instance ??= DioClient._internal(appInterceptors);
    return _instance!;
  }

  /// 必要なインターセプターと設定を全て含む新しいDioClientインスタンスを作成
  DioClient._internal(AppInterceptors appInterceptors)
    : _dio = Dio(),
      _csrfTokenProvider = CsrfTokenProvider(),
      _tokenService = TokenService() {
    // Dioの基本設定を構成
    _dio.options.baseUrl = ApiConstants.BASE_URL;
    _dio.options.connectTimeout = const Duration(
      milliseconds: ApiConstants.CONNECT_TIMEOUT,
    );
    _dio.options.receiveTimeout = const Duration(
      milliseconds: ApiConstants.RECEIVE_TIMEOUT,
    );
    _dio.options.sendTimeout = const Duration(
      milliseconds: ApiConstants.SEND_TIMEOUT,
    );
    _dio.options.validateStatus = (status) => status! < 500;

    // 共通ヘッダーを設定
    _dio.options.headers.addAll({
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    });

    if (kDebugMode) {
      debugPrint('🔧 DioClient初期化完了 - ベースURL: ${ApiConstants.BASE_URL}');
    }

    // CSRFトークン管理インターセプターを追加
    _dio.interceptors.add(_createCsrfInterceptor());

    // 認証トークン管理インターセプターを追加
    _dio.interceptors.add(_createAuthTokenInterceptor());

    // メインアプリケーションインターセプターを追加
    _dio.interceptors.add(appInterceptors);

    if (kDebugMode) {
      debugPrint('🎯 全インターセプター初期化完了');
    }
  }

  // ===== CSRFトークン管理 =====

  /// CSRFトークン処理専用インターセプターを作成
  InterceptorsWrapper _createCsrfInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        // 非安全メソッド（状態を変更するメソッド）に対してのみCSRFトークンを追加
        if (!ApiConstants.SAFE_METHODS.contains(options.method.toUpperCase())) {
          await _ensureCsrfToken();
          final token = await _csrfTokenProvider.getCsrfToken();

          if (token != null && token.isNotEmpty) {
            options.headers['X-CSRF-Token'] = token;
            if (kDebugMode) {
              debugPrint('🛡️ CSRFトークンをリクエストヘッダーに追加: ${_maskToken(token)}');
            }
          } else {
            if (kDebugMode) {
              debugPrint('⚠️ CSRFトークンが取得できませんでした - メソッド: ${options.method}');
            }
          }
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        // レスポンスからCSRFトークンを抽出して保存
        _extractAndStoreCsrfToken(response);
        return handler.next(response);
      },
    );
  }

  /// CSRFトークンが存在しない場合は取得する
  Future<void> _ensureCsrfToken() async {
    final existingToken = await _csrfTokenProvider.getCsrfToken();

    if (existingToken == null || existingToken.isEmpty) {
      if (kDebugMode) {
        debugPrint('🔄 CSRFトークンが存在しないため取得を試行...');
      }

      try {
        // 本番・開発環境両方でサーバーからトークンを取得を試行
        final response = await _dio.get(
          ApiConstants.CSRF_TOKEN,
          options: Options(
            extra: {'skipCsrfCheck': true},
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          ),
        );

        if (response.data != null) {
          _extractAndStoreCsrfToken(response);

          final newToken = await _csrfTokenProvider.getCsrfToken();
          if (newToken != null && newToken.isNotEmpty) {
            if (kDebugMode) {
              debugPrint('✅ サーバーからCSRFトークン取得成功: ${_maskToken(newToken)}');
            }
            return;
          }
        }

        // レスポンスはあるがトークンが含まれていない場合
        throw Exception('CSRFトークンがレスポンスに含まれていません');
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ サーバーからのCSRFトークン取得エラー: $e');
        }

        // 開発環境での再試行ロジック
        if (kDebugMode) {
          await _setDevelopmentCsrfToken();
        } else {
          // 本番環境では例外を再スロー
          throw Exception('CSRFトークンの取得に失敗しました: $e');
        }
      }
    }
  }

  /// 開発環境用の固定CSRFトークンを設定
  Future<void> _setDevelopmentCsrfToken() async {
    if (kDebugMode) {
      debugPrint('🔄 開発環境用固定CSRFトークンを使用');
      await _csrfTokenProvider.setCsrfToken(
        ApiConstants.DEVELOPMENT_CSRF_TOKEN,
      );
      debugPrint(
        '🔐 固定CSRFトークンを設定: ${_maskToken(ApiConstants.DEVELOPMENT_CSRF_TOKEN)}',
      );
    }
  }

  /// CSRFトークンを強制的に更新
  Future<void> refreshCsrfToken() async {
    if (kDebugMode) {
      debugPrint('🔄 CSRFトークンの強制更新を開始...');
    }

    // 既存のトークンをクリア
    await _csrfTokenProvider.setCsrfToken('');

    // 新しいトークンを取得
    await _ensureCsrfToken();

    if (kDebugMode) {
      debugPrint('✅ CSRFトークンの強制更新完了');
    }
  }

  /// レスポンスからCSRFトークンを抽出して保存
  void _extractAndStoreCsrfToken(Response response) {
    String? token;

    // 1. レスポンスボディからトークンを探す
    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      token = data['csrf_token'] ?? data['csrfToken'] ?? data['token'];
    }

    // 2. Cookieからトークンを探す
    if (token == null && response.headers['set-cookie'] != null) {
      for (var cookie in response.headers['set-cookie']!) {
        if (cookie.contains('csrf_token=')) {
          token = _extractCsrfTokenFromCookie(cookie);
          break;
        }
      }
    }

    // 3. ヘッダーからトークンを探す - null-aware assignment使用
    token ??=
        response.headers.value('X-CSRF-Token') ??
        response.headers.value('x-csrf-token');

    // トークンが見つかった場合は保存
    if (token != null && token.isNotEmpty) {
      _csrfTokenProvider.setCsrfToken(token);
      if (kDebugMode) {
        debugPrint('🔐 CSRFトークンを更新: ${_maskToken(token)}');
      }
    }
  }

  /// Cookie文字列からCSRFトークンを抽出
  String? _extractCsrfTokenFromCookie(String cookie) {
    final regex = RegExp(r'csrf_token=([^;]+)');
    final match = regex.firstMatch(cookie);
    return match?.group(1);
  }

  /// トークンをマスクして安全にログ出力
  String _maskToken(String token) {
    if (token.length <= 12) return '[REDACTED]';
    return '${token.substring(0, 8)}...${token.substring(token.length - 4)}';
  }

  // ===== 認証トークン管理 =====

  /// 認証トークン処理専用インターセプターを作成
  InterceptorsWrapper _createAuthTokenInterceptor() {
    return InterceptorsWrapper(
      onResponse: (response, handler) {
        // レスポンスから認証トークンを抽出して保存
        _extractAndStoreAuthTokens(response);
        return handler.next(response);
      },
    );
  }

  /// レスポンスから認証トークンを抽出して保存
  void _extractAndStoreAuthTokens(Response response) {
    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;

      final accessToken = data['access_token'] ?? data['accessToken'];
      final refreshToken = data['refresh_token'] ?? data['refreshToken'];
      final expiresIn = data['expires_in'] ?? data['expiresIn'] ?? 3600;

      if (accessToken != null && refreshToken != null) {
        _tokenService.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
          expiresIn: expiresIn,
        );

        if (kDebugMode) {
          debugPrint('🔑 認証トークンを更新しました');
        }
      }
    }
  }

  // ===== HTTP メソッド実装 =====

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool requiresAuth = true,
  }) async {
    options = _prepareOptions(options, requiresAuth);

    if (kDebugMode) {
      debugPrint(
        '🚀 GET: $path${queryParameters != null ? " (クエリ: $queryParameters)" : ""}',
      );
    }

    try {
      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      _logSuccess('GET', path, response.statusCode);
      return response;
    } catch (e) {
      _logError('GET', path, e);
      rethrow;
    }
  }

  @override
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool requiresAuth = true,
  }) async {
    options = _prepareOptions(options, requiresAuth);

    if (kDebugMode) {
      debugPrint('🚀 POST: $path${data != null ? " (データあり)" : ""}');
    }

    try {
      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      _logSuccess('POST', path, response.statusCode);
      return response;
    } catch (e) {
      _logError('POST', path, e);
      rethrow;
    }
  }

  @override
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool requiresAuth = true,
  }) async {
    options = _prepareOptions(options, requiresAuth);

    if (kDebugMode) {
      debugPrint('🚀 PUT: $path');
    }

    try {
      final response = await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      _logSuccess('PUT', path, response.statusCode);
      return response;
    } catch (e) {
      _logError('PUT', path, e);
      rethrow;
    }
  }

  @override
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool requiresAuth = true,
  }) async {
    options = _prepareOptions(options, requiresAuth);

    if (kDebugMode) {
      debugPrint('🚀 DELETE: $path');
    }

    try {
      final response = await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      _logSuccess('DELETE', path, response.statusCode);
      return response;
    } catch (e) {
      _logError('DELETE', path, e);
      rethrow;
    }
  }

  @override
  Future<Response<T>> upload<T>(
    String path, {
    required FormData formData,
    Options? options,
    bool requiresAuth = true,
    void Function(int, int)? onSendProgress,
  }) async {
    options = _prepareOptions(options, requiresAuth);

    // ファイルアップロード用のContent-Typeを設定 - null-aware assignment使用
    options.headers ??= {};
    options.headers!['Content-Type'] = 'multipart/form-data';

    if (kDebugMode) {
      debugPrint(
        '📤 UPLOAD: $path (フィールド: ${formData.fields.length}, ファイル: ${formData.files.length})',
      );
    }

    try {
      final response = await _dio.post<T>(
        path,
        data: formData,
        options: options,
        onSendProgress:
            onSendProgress != null
                ? (sent, total) {
                  if (kDebugMode) {
                    final progress = (sent / total * 100).toStringAsFixed(1);
                    debugPrint('📊 アップロード進捗: $progress% ($sent/$total bytes)');
                  }
                  onSendProgress(sent, total);
                }
                : null,
      );
      _logSuccess('UPLOAD', path, response.statusCode);
      return response;
    } catch (e) {
      _logError('UPLOAD', path, e);
      rethrow;
    }
  }

  // ===== ヘルパーメソッド =====

  /// リクエストオプションを準備
  Options _prepareOptions(Options? options, bool requiresAuth) {
    options ??= Options();
    options.extra ??= {};
    options.extra!['requiresAuth'] = requiresAuth;
    return options;
  }

  /// 成功ログを出力
  void _logSuccess(String method, String path, int? statusCode) {
    if (kDebugMode) {
      debugPrint('✅ $method成功: $path (ステータス: $statusCode)');
    }
  }

  /// エラーログを出力
  void _logError(String method, String path, dynamic error) {
    if (kDebugMode) {
      debugPrint('💥 $method失敗: $path - エラー: $error');
    }
  }

  // ===== CSRFトークン関連ユーティリティ =====

  /// 現在のCSRFトークンを取得
  Future<String?> getCurrentCsrfToken() async {
    await _ensureCsrfToken();
    return await _csrfTokenProvider.getCsrfToken();
  }

  /// CSRFトークンを手動で設定
  Future<void> setCsrfToken(String token) async {
    await _csrfTokenProvider.setCsrfToken(token);
    if (kDebugMode) {
      debugPrint('🔐 CSRFトークンを手動設定: ${_maskToken(token)}');
    }
  }

  /// CSRFトークンをクリア
  Future<void> clearCsrfToken() async {
    await _csrfTokenProvider.setCsrfToken('');
    if (kDebugMode) {
      debugPrint('🧹 CSRFトークンをクリアしました');
    }
  }

  /// CSRFトークンの有効性をチェック
  Future<bool> validateCsrfToken() async {
    try {
      await _ensureCsrfToken();
      final token = await _csrfTokenProvider.getCsrfToken();
      final isValid = token != null && token.isNotEmpty;

      if (kDebugMode) {
        debugPrint('🔍 CSRFトークン検証結果: ${isValid ? "有効" : "無効"}');
      }

      return isValid;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ CSRFトークン検証エラー: $e');
      }
      return false;
    }
  }

  // ===== アクセサー =====

  /// 基底のDioインスタンスへのアクセス
  Dio get dio => _dio;

  /// CSRFトークンプロバイダーを取得
  CsrfTokenProvider get csrfTokenProvider => _csrfTokenProvider;

  /// 認証操作用のトークンサービスを取得
  TokenService get tokenService => _tokenService;

  /// ユーザーをサインアウトしてトークンをクリアします
  Future<bool> signOut() async {
    if (kDebugMode) {
      debugPrint('🚪 サインアウト処理開始...');
    }

    try {
      final token = await _tokenService.getAccessToken();
      if (token != null) {
        if (kDebugMode) {
          debugPrint('📡 サーバーにサインアウトリクエストを送信中...');
        }

        // サインアウトAPIを呼び出し
        await post(
          ApiConstants.SIGNOUT,
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );

        if (kDebugMode) {
          debugPrint('✅ サーバーサインアウト完了');
        }
      }

      // 全てのトークンをクリア
      await _tokenService.clearTokens();
      await clearCsrfToken();

      if (kDebugMode) {
        debugPrint('🧹 ローカルトークンクリア完了');
        debugPrint('✨ サインアウト処理完了');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ サインアウトエラー: $e');
        debugPrint('🔄 API呼び出しに失敗しましたが、ローカルトークンをクリアします');
      }

      // API呼び出しが失敗してもローカルのトークンはクリア
      await _tokenService.clearTokens();
      await clearCsrfToken();

      if (kDebugMode) {
        debugPrint('🧹 強制ローカルトークンクリア完了');
      }

      return false;
    }
  }
}
