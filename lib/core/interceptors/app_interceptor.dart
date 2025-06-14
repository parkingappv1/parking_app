// lib/core/interceptors/interceptors.dart
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:parking_app/core/interceptors/app_token_service.dart';

/// アプリケーション全体のHTTPインターセプターを統合管理するクラス
/// 認証、キャッシュ、リトライ、ログ記録機能を統合的に提供
class AppInterceptors extends Interceptor {
  // ===== 依存関係 =====
  /// トークン取得関数 - 認証ヘッダー追加用
  final Future<String?> Function() getToken;

  /// トークン更新関数 - 401エラー時の自動更新用
  final Future<bool> Function() refreshToken;

  // ===== 設定パラメータ =====
  /// ログ記録を有効にするか（デバッグモードでデフォルト有効）
  final bool enableLogging;

  /// キャッシュ機能を有効にするか
  final bool enableCache;

  /// リトライ機能を有効にするか
  final bool enableRetry;

  /// 最大リトライ回数
  final int maxRetryCount;

  // ===== 内部状態管理 =====
  /// メモリキャッシュストレージ
  final Map<String, _CacheEntry> _cache = {};

  /// トークン更新処理中フラグ
  bool _isRefreshingToken = false;

  /// トークン更新待ちリクエストキュー
  final List<_RetryRequest> _tokenRefreshQueue = [];

  /// AppInterceptorsコンストラクタ
  /// カスタムトークン処理関数が未提供の場合、TokenServiceのデフォルト実装を使用
  AppInterceptors({
    Future<String?> Function()? getToken,
    Future<bool> Function()? refreshToken,
    this.enableLogging = kDebugMode,
    this.enableCache = true,
    this.enableRetry = true,
    this.maxRetryCount = 3,
  }) : getToken = getToken ?? TokenService().getAccessToken,
       refreshToken = refreshToken ?? TokenService().refreshToken {
    if (kDebugMode) {
      debugPrint('🔧 （app_interceptor.dart）AppInterceptors初期化完了');
      debugPrint(
        '📊 設定: ログ=$enableLogging, キャッシュ=$enableCache, リトライ=$enableRetry',
      );
    }
  }

  /// リクエスト前処理インターセプター
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      // 1. ネットワーク接続状態チェック
      if (!await _hasNetworkConnection()) {
        return _handleOfflineRequest(options, handler);
      }

      // 2. GETリクエストのキャッシュ処理
      if (enableCache && _isGetRequest(options)) {
        final cachedResponse = _getCachedResponse(options);
        if (cachedResponse != null) {
          if (kDebugMode) debugPrint('📦 （app_interceptor.dart）キャッシュからレスポンス返却: ${options.uri}');
          return handler.resolve(cachedResponse);
        }
      }

      // 3. 認証ヘッダー追加
      await _addAuthenticationHeader(options);

      // 4. 共通ヘッダー追加
      _addCommonHeaders(options);

      // 5. リクエストログ記録
      if (enableLogging) {
        _logRequest(options);
      }

      return handler.next(options);
    } catch (e) {
      if (kDebugMode) debugPrint('💥 （app_interceptor.dart）リクエストインターセプターエラー: $e');
      return handler.reject(
        DioException(
          requestOptions: options,
          error: 'リクエスト前処理エラー: $e',
          type: DioExceptionType.unknown,
        ),
      );
    }
  }

  /// レスポンス後処理インターセプター
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    try {
      // 1. 成功レスポンスのキャッシュ保存
      if (enableCache && _shouldCacheResponse(response)) {
        _saveToCache(response);
      }

      // 2. レスポンスログ記録
      if (enableLogging) {
        _logResponse(response);
      }

      // 3. 統一API形式の処理
      final processedResponse = _processUnifiedApiResponse(response);

      return handler.next(processedResponse);
    } catch (e) {
      if (kDebugMode) debugPrint('💥 （app_interceptor.dart）レスポンスインターセプターエラー: $e');
      return handler.next(response); // エラーが発生してもレスポンスは返す
    }
  }

  /// エラー処理インターセプター
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    try {
      // 1. エラーログ記録
      if (enableLogging) {
        _logError(err);
      }

      // 2. 401エラー（認証失敗）の自動トークン更新処理
      if (_isUnauthorizedError(err) && !_isRetryAfterTokenRefresh(err)) {
        final retryHandled = await _handleTokenRefreshAndRetry(err, handler);
        if (retryHandled) return; // 処理完了
      }

      // 3. オフライン時のキャッシュフォールバック
      if (enableCache &&
          _isNetworkError(err) &&
          _isGetRequest(err.requestOptions)) {
        final cachedResponse = _getCachedResponse(err.requestOptions);
        if (cachedResponse != null) {
          if (kDebugMode) debugPrint('🔄 ネットワークエラー - キャッシュからフォールバック');
          return handler.resolve(cachedResponse);
        }
      }

      // 4. リトライ可能エラーの自動リトライ処理
      if (enableRetry && _shouldRetryRequest(err)) {
        final retryHandled = await _executeRetryLogic(err, handler);
        if (retryHandled) return; // 処理完了
      }

      // 5. エラー情報の日本語化と詳細化
      final enhancedError = _enhanceErrorWithJapaneseMessage(err);

      return handler.next(enhancedError);
    } catch (e) {
      if (kDebugMode) debugPrint('💥 エラーインターセプター内部エラー: $e');
      return handler.next(err); // 元のエラーを返す
    }
  }

  // ===== ネットワーク関連ヘルパーメソッド =====

  /// ネットワーク接続状態をチェック
  Future<bool> _hasNetworkConnection() async {
    try {
      final connectivityResults = await Connectivity().checkConnectivity();
      return !connectivityResults.contains(ConnectivityResult.none);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ ネットワーク状態チェック失敗: $e');
      return true; // エラー時は接続ありと仮定
    }
  }

  /// オフライン時のリクエスト処理
  void _handleOfflineRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    if (kDebugMode) debugPrint('📵 オフライン状態でリクエスト: ${options.uri}');

    // GETリクエストの場合はキャッシュを確認
    if (enableCache && _isGetRequest(options)) {
      final cachedResponse = _getCachedResponse(options);
      if (cachedResponse != null) {
        if (kDebugMode) debugPrint('📦 オフライン - キャッシュからレスポンス');
        return handler.resolve(cachedResponse);
      }
    }

    // キャッシュなしの場合はネットワークエラーを返す
    return handler.reject(
      DioException(
        requestOptions: options,
        error: 'インターネット接続がありません',
        type: DioExceptionType.connectionError,
      ),
    );
  }

  // ===== 認証関連ヘルパーメソッド =====

  /// 認証ヘッダーを追加
  Future<void> _addAuthenticationHeader(RequestOptions options) async {
    // 認証が明示的に無効化されている場合はスキップ
    if (options.extra['requiresAuth'] == false) {
      return;
    }

    try {
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
        if (kDebugMode) debugPrint('🔐 認証ヘッダー追加完了');
      } else if (kDebugMode) {
        debugPrint('⚠️ 認証トークンが見つかりません');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ 認証ヘッダー追加エラー: $e');
    }
  }

  /// 共通ヘッダーを追加
  void _addCommonHeaders(RequestOptions options) {
    // 基本的なContent-Typeヘッダー - null-aware assignment使用
    options.headers['Accept'] ??= 'application/json';
    if (options.data != null && !options.headers.containsKey('Content-Type')) {
      options.headers['Content-Type'] = 'application/json';
    }

    // アプリケーション情報ヘッダー - null-aware assignment使用
    options.headers['X-App-Version'] ??= '1.0.0';
    options.headers['X-Platform'] ??= Platform.isIOS ? 'iOS' : 'Android';
    options.headers['X-Client-Type'] ??= 'mobile';
  }

  // ===== キャッシュ関連ヘルパーメソッド =====

  /// キャッシュからレスポンスを取得
  Response? _getCachedResponse(RequestOptions options) {
    // 強制更新が指定されている場合はキャッシュを無視
    if (options.extra['forceRefresh'] == true) {
      return null;
    }

    final cacheKey = _generateCacheKey(options);
    final cacheEntry = _cache[cacheKey];

    if (cacheEntry != null && !cacheEntry.isExpired) {
      // キャッシュからのレスポンスであることを示すフラグを追加
      final cachedResponse = Response(
        data: cacheEntry.data,
        headers: cacheEntry.headers,
        requestOptions: options,
        statusCode: cacheEntry.statusCode,
        statusMessage: 'OK (Cache)',
        extra: {'fromCache': true},
      );
      return cachedResponse;
    }

    return null;
  }

  /// レスポンスをキャッシュに保存
  void _saveToCache(Response response) {
    final cacheKey = _generateCacheKey(response.requestOptions);
    final cacheDuration = _getCacheDuration(response.requestOptions);

    _cache[cacheKey] = _CacheEntry(
      data: response.data,
      headers: response.headers,
      statusCode: response.statusCode ?? 200,
      expiryTime: DateTime.now().add(cacheDuration),
    );

    if (kDebugMode) {
      debugPrint(
        '💾 レスポンスをキャッシュ保存: $cacheKey (有効期限: ${cacheDuration.inMinutes}分)',
      );
    }
  }

  /// キャッシュキーを生成
  String _generateCacheKey(RequestOptions options) {
    final uri = options.uri.toString();
    final queryParams = jsonEncode(options.queryParameters);
    return '${options.method}:$uri:$queryParams';
  }

  /// キャッシュ期間を取得
  Duration _getCacheDuration(RequestOptions options) {
    return options.extra['cacheDuration'] as Duration? ??
        const Duration(minutes: 5);
  }

  // ===== トークン更新関連ヘルパーメソッド =====

  /// トークン更新とリトライ処理
  Future<bool> _handleTokenRefreshAndRetry(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final retryRequest = _RetryRequest(
      options: err.requestOptions,
      handler: handler,
    );
    _tokenRefreshQueue.add(retryRequest);

    // 既にトークン更新中の場合は待機
    if (_isRefreshingToken) {
      return true;
    }

    _isRefreshingToken = true;
    if (kDebugMode) debugPrint('🔄 トークン更新開始...');

    try {
      final refreshSuccess = await refreshToken();

      if (refreshSuccess) {
        if (kDebugMode) debugPrint('✅ トークン更新成功');
        await _retryQueuedRequests();
      } else {
        if (kDebugMode) debugPrint('❌ トークン更新失敗');
        _rejectQueuedRequests('トークン更新に失敗しました');
      }

      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('💥 トークン更新エラー: $e');
      _rejectQueuedRequests('トークン更新中にエラーが発生しました: $e');
      return true;
    } finally {
      _isRefreshingToken = false;
    }
  }

  /// キューに溜まったリクエストを再実行
  Future<void> _retryQueuedRequests() async {
    final newToken = await getToken();

    while (_tokenRefreshQueue.isNotEmpty) {
      final request = _tokenRefreshQueue.removeAt(0);

      // 新しいトークンでAuthorizationヘッダーを更新
      if (newToken != null && newToken.isNotEmpty) {
        request.options.headers['Authorization'] = 'Bearer $newToken';
      }

      // 無限ループ防止フラグを設定
      request.options.extra['isRetryAfterRefresh'] = true;

      try {
        // 新しいDioインスタンスでリトライ（インターセプター無限ループ回避）
        final response = await Dio().fetch(request.options);
        request.handler.resolve(response);
      } catch (e) {
        final error =
            e is DioException
                ? e
                : DioException(
                  requestOptions: request.options,
                  error: e.toString(),
                );
        request.handler.reject(error);
      }
    }
  }

  /// キューに溜まったリクエストを全て拒否
  void _rejectQueuedRequests(String errorMessage) {
    while (_tokenRefreshQueue.isNotEmpty) {
      final request = _tokenRefreshQueue.removeAt(0);
      request.handler.reject(
        DioException(
          requestOptions: request.options,
          error: errorMessage,
          type: DioExceptionType.unknown,
        ),
      );
    }
  }

  // ===== リトライ関連ヘルパーメソッド =====

  /// リトライロジックを実行
  Future<bool> _executeRetryLogic(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final currentRetryCount = options.extra['retryCount'] ?? 0;

    // リトライ回数を増加 - null-aware assignment使用
    options.extra['retryCount'] = currentRetryCount + 1;

    // 指数バックオフでの待機時間計算
    final delayMs = 300 * (1 << currentRetryCount);
    final delay = Duration(milliseconds: delayMs);

    if (kDebugMode) {
      debugPrint(
        '🔄 リクエストリトライ実行 (${currentRetryCount + 1}/$maxRetryCount): ${options.uri}',
      );
      debugPrint('⏰ ${delay.inMilliseconds}ms待機後にリトライ');
    }

    try {
      await Future.delayed(delay);
      final response = await Dio().fetch(options);
      handler.resolve(response);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('💥 リトライ失敗: $e');
      return false;
    }
  }

  // ===== レスポンス処理ヘルパーメソッド =====

  /// 統一API形式のレスポンス処理
  Response _processUnifiedApiResponse(Response response) {
    // API共通形式 {"code": 0, "data": {}, "message": ""} の処理
    if (response.data is Map<String, dynamic>) {
      final responseData = response.data as Map<String, dynamic>;

      if (responseData.containsKey('code') &&
          responseData.containsKey('data')) {
        final code = responseData['code'];

        if (code == 0 || code == 200 || code == 201) {
          // 成功時はdataフィールドを抽出
          response.data = responseData['data'];
        } else {
          // 業務エラーの場合は例外として処理
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            type: DioExceptionType.badResponse,
            error: responseData['message'] ?? 'API業務エラー',
          );
        }
      }
    }

    return response;
  }

  // ===== エラー処理ヘルパーメソッド =====

  /// エラーメッセージを日本語化
  DioException _enhanceErrorWithJapaneseMessage(DioException err) {
    String friendlyMessage = _getFriendlyErrorMessage(err);

    // APIレスポンスからより具体的なエラーメッセージを取得
    if (err.response?.data is Map<String, dynamic>) {
      final responseData = err.response!.data as Map<String, dynamic>;
      final apiMessage = responseData['message'] ?? responseData['error'];
      if (apiMessage != null) {
        friendlyMessage = apiMessage.toString();
      }
    }

    return DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: friendlyMessage,
    );
  }

  /// ユーザーフレンドリーなエラーメッセージを取得
  String _getFriendlyErrorMessage(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return '通信がタイムアウトしました。しばらくしてから再度お試しください。';

      case DioExceptionType.badResponse:
        return _getHttpStatusErrorMessage(err.response?.statusCode);

      case DioExceptionType.cancel:
        return 'リクエストがキャンセルされました。';

      case DioExceptionType.connectionError:
        if (err.error is SocketException) {
          return 'サーバーに接続できません。ネットワーク接続を確認してください。';
        }
        return 'ネットワーク接続エラーが発生しました。';

      case DioExceptionType.badCertificate:
        return 'サーバーの証明書に問題があります。';

      case DioExceptionType.unknown:
        return '予期しないエラーが発生しました。';
    }
  }

  /// HTTPステータスコード別エラーメッセージ
  String _getHttpStatusErrorMessage(int? statusCode) {
    switch (statusCode) {
      case 400:
        return '送信されたデータに問題があります。';
      case 401:
        return '認証が必要です。再度ログインしてください。';
      case 403:
        return 'この操作を実行する権限がありません。';
      case 404:
        return '要求されたリソースが見つかりません。';
      case 408:
        return 'リクエストがタイムアウトしました。';
      case 409:
        return 'データが競合しています。';
      case 422:
        return '入力データの形式に問題があります。';
      case 429:
        return 'リクエストが多すぎます。しばらく待ってから再度お試しください。';
      case 500:
        return 'サーバー内部エラーが発生しました。';
      case 502:
        return 'サーバーゲートウェイエラーです。';
      case 503:
        return 'サービスが一時的に利用できません。';
      case 504:
        return 'サーバーのレスポンスがタイムアウトしました。';
      default:
        return 'サーバーエラーが発生しました。(${statusCode ?? "不明"})';
    }
  }

  // ===== 判定ヘルパーメソッド =====

  bool _isGetRequest(RequestOptions options) =>
      options.method.toUpperCase() == 'GET';
  bool _isUnauthorizedError(DioException err) =>
      err.response?.statusCode == 401;
  bool _isRetryAfterTokenRefresh(DioException err) =>
      err.requestOptions.extra['isRetryAfterRefresh'] == true;
  bool _isNetworkError(DioException err) =>
      err.type == DioExceptionType.connectionError ||
      err.error is SocketException;
  bool _isServerError(DioException err) {
    final statusCode = err.response?.statusCode;
    return statusCode != null && statusCode >= 500;
  }

  bool _shouldCacheResponse(Response response) {
    return _isGetRequest(response.requestOptions) &&
        response.statusCode == 200 &&
        response.requestOptions.extra['noCache'] != true;
  }

  bool _shouldRetryRequest(DioException err) {
    final retryCount = err.requestOptions.extra['retryCount'] ?? 0;
    if (retryCount >= maxRetryCount) return false;

    return _isNetworkError(err) ||
        _isServerError(err) ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout;
  }

  // ===== ログ記録ヘルパーメソッド =====

  void _logRequest(RequestOptions options) {
    debugPrint('┌─────────────────── REQUEST ───────────────────');
    debugPrint('│ URL: ${options.uri}');
    debugPrint('│ METHOD: ${options.method}');

    // X-CSRF-Tokenの存在を明示的にログ出力
    final sanitizedHeaders = _sanitizeHeaders(options.headers);
    if (options.headers.containsKey('X-CSRF-Token')) {
      debugPrint('│ X-CSRF-TOKEN: ${sanitizedHeaders['X-CSRF-Token']}');
    }

    debugPrint('│ HEADERS: $sanitizedHeaders');

    if (options.data != null) {
      try {
        final data =
            options.data is String ? options.data : jsonEncode(options.data);
        debugPrint('│ BODY: $data');
      } catch (e) {
        debugPrint('│ BODY: [Serialization failed]');
      }
    }

    debugPrint('└───────────────────────────────────────────────');
  }

  void _logResponse(Response response) {
    debugPrint('┌─────────────────── RESPONSE ──────────────────');
    debugPrint('│ URL: ${response.requestOptions.uri}');
    debugPrint('│ STATUS: ${response.statusCode} ${response.statusMessage}');

    if (response.extra['fromCache'] == true) {
      debugPrint('│ SOURCE: Cache');
    }

    if (response.data != null) {
      try {
        final data =
            response.data is String ? response.data : jsonEncode(response.data);
        final truncatedData =
            data.length > 200 ? '${data.substring(0, 200)}...' : data;
        debugPrint('│ BODY: $truncatedData');
      } catch (e) {
        debugPrint('│ BODY: [Serialization failed]');
      }
    }

    debugPrint('└───────────────────────────────────────────────');
  }

  void _logError(DioException err) {
    // エラーの種類を判別
    final errorSource = _determineErrorSource(err);

    debugPrint('┌─────────────────── ERROR ─────────────────────');
    debugPrint('│ URL: ${err.requestOptions.uri}');
    debugPrint('│ TYPE: ${err.type}');
    debugPrint('│ ERROR_SOURCE: $errorSource');
    debugPrint(
      '│ STATUS: ${err.response?.statusCode} ${err.response?.statusMessage}',
    );
    debugPrint('│ MESSAGE: ${err.error ?? err.message}');

    // サーバーエラーの場合は詳細なレスポンス情報を出力
    if (err.response?.data != null) {
      try {
        final data =
            err.response?.data is String
                ? err.response?.data
                : jsonEncode(err.response?.data);
        debugPrint('│ SERVER_RESPONSE: $data');
      } catch (e) {
        debugPrint('│ SERVER_RESPONSE: [Serialization failed]');
      }
    }

    // Flutter/Dartエラーの場合はスタックトレースヒントを追加
    if (errorSource == 'FLUTTER_ERROR' && err.error != null) {
      debugPrint('│ FLUTTER_ERROR_DETAIL: ${err.error.runtimeType}');
    }

    debugPrint('└───────────────────────────────────────────────');
  }

  /// エラーの発生源を判別
  String _determineErrorSource(DioException err) {
    // ネットワーク関連エラー
    if (err.type == DioExceptionType.connectionError ||
        err.error is SocketException) {
      return 'NETWORK_ERROR';
    }

    // タイムアウトエラー
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      return 'TIMEOUT_ERROR';
    }

    // サーバーからのHTTPレスポンスエラー
    if (err.response != null) {
      final statusCode = err.response!.statusCode;
      if (statusCode != null) {
        if (statusCode >= 500) {
          return 'SERVER_ERROR';
        } else if (statusCode >= 400) {
          return 'CLIENT_ERROR';
        }
        return 'HTTP_ERROR';
      }
    }

    // Flutter/Dartアプリケーション内部エラー
    if (err.type == DioExceptionType.unknown && err.error != null) {
      // 具体的なエラータイプをチェック
      final errorType = err.error.runtimeType.toString();
      if (errorType.contains('Format') || errorType.contains('Parse')) {
        return 'PARSING_ERROR';
      }
      if (errorType.contains('State') || errorType.contains('Assertion')) {
        return 'FLUTTER_STATE_ERROR';
      }
      return 'FLUTTER_ERROR';
    }

    // キャンセルエラー
    if (err.type == DioExceptionType.cancel) {
      return 'REQUEST_CANCELLED';
    }

    // 証明書エラー
    if (err.type == DioExceptionType.badCertificate) {
      return 'CERTIFICATE_ERROR';
    }

    return 'UNKNOWN_ERROR';
  }

  /// 機密情報を除去してヘッダーを安全化
  Map<String, dynamic> _sanitizeHeaders(Map<String, dynamic> headers) {
    final sanitized = Map<String, dynamic>.from(headers);

    if (sanitized.containsKey('Authorization')) {
      sanitized['Authorization'] = 'Bearer [REDACTED]';
    }

    if (sanitized.containsKey('X-CSRF-Token')) {
      final token = sanitized['X-CSRF-Token'] as String?;
      if (token != null && token.isNotEmpty) {
        // トークンの最初の8文字と最後の4文字のみ表示
        if (token.length > 12) {
          sanitized['X-CSRF-Token'] =
              '${token.substring(0, 8)}...${token.substring(token.length - 4)}';
        } else {
          sanitized['X-CSRF-Token'] = '[REDACTED]';
        }
      }
    }

    return sanitized;
  }
}

// ===== 内部データクラス =====

/// キャッシュエントリ
class _CacheEntry {
  final dynamic data;
  final Headers headers;
  final int statusCode;
  final DateTime expiryTime;

  _CacheEntry({
    required this.data,
    required this.headers,
    required this.statusCode,
    required this.expiryTime,
  });

  bool get isExpired => DateTime.now().isAfter(expiryTime);
}

/// トークン更新待ちリクエスト
class _RetryRequest {
  final RequestOptions options;
  final ErrorInterceptorHandler handler;

  _RetryRequest({required this.options, required this.handler});
}
