import 'package:flutter/foundation.dart';

/// APIレスポンスの状態を表す列挙型
enum ApiStatus {
  /// 成功
  success,

  /// エラー
  error,

  /// タイムアウト
  timeout,

  /// キャンセル
  cancelled,
}

/// 統一されたAPIレスポンス形式を提供するクラス
/// 全てのAPI呼び出しの結果を標準化し、エラーハンドリングを簡素化します
class ApiResponse<T> {
  /// レスポンスの状態
  final ApiStatus status;

  /// レスポンスデータ（成功時のみ）
  final T? data;

  /// エラーメッセージまたは説明
  final String? message;

  /// HTTPステータスコード
  final int? statusCode;

  /// レスポンス受信時刻
  final DateTime timestamp;

  /// プライベートコンストラクタ
  const ApiResponse._({
    required this.status,
    this.data,
    this.message,
    this.statusCode,
    required this.timestamp,
  });

  /// 成功レスポンスを作成
  factory ApiResponse.success(T data, {String? message, int? statusCode}) {
    if (kDebugMode) {
      debugPrint('✅ APIレスポンス成功: ${statusCode ?? 200}');
    }

    return ApiResponse._(
      status: ApiStatus.success,
      data: data,
      message: message ?? '処理が正常に完了しました',
      statusCode: statusCode ?? 200,
      timestamp: DateTime.now(),
    );
  }

  /// エラーレスポンスを作成
  factory ApiResponse.error(String message, {int? code}) {
    if (kDebugMode) {
      debugPrint('❌ APIレスポンスエラー: $message (ステータス: ${code ?? 'N/A'})');
    }

    return ApiResponse._(
      status: ApiStatus.error,
      message: message,
      statusCode: code,
      timestamp: DateTime.now(),
    );
  }

  /// タイムアウトレスポンスを作成
  factory ApiResponse.timeout({String? message}) {
    final timeoutMessage = message ?? 'リクエストがタイムアウトしました';

    if (kDebugMode) {
      debugPrint('⏰ APIタイムアウト: $timeoutMessage');
    }

    return ApiResponse._(
      status: ApiStatus.timeout,
      message: timeoutMessage,
      statusCode: 408,
      timestamp: DateTime.now(),
    );
  }

  /// キャンセルレスポンスを作成
  factory ApiResponse.cancelled({String? message}) {
    final cancelMessage = message ?? 'リクエストがキャンセルされました';

    if (kDebugMode) {
      debugPrint('🚫 APIキャンセル: $cancelMessage');
    }

    return ApiResponse._(
      status: ApiStatus.cancelled,
      message: cancelMessage,
      statusCode: 499,
      timestamp: DateTime.now(),
    );
  }

  /// ネットワークエラーレスポンスを作成
  factory ApiResponse.networkError({String? message}) {
    final networkMessage = message ?? 'ネットワーク接続エラーが発生しました';

    if (kDebugMode) {
      debugPrint('🌐 ネットワークエラー: $networkMessage');
    }

    return ApiResponse._(
      status: ApiStatus.error,
      message: networkMessage,
      statusCode: null, // ネットワークエラーではHTTPステータスがない
      timestamp: DateTime.now(),
    );
  }

  /// サーバーエラーレスポンスを作成
  factory ApiResponse.serverError({String? message, int? statusCode}) {
    final serverMessage = message ?? 'サーバーエラーが発生しました';

    if (kDebugMode) {
      debugPrint('🔧 サーバーエラー: $serverMessage (ステータス: ${statusCode ?? 500})');
    }

    return ApiResponse._(
      status: ApiStatus.error,
      message: serverMessage,
      statusCode: statusCode ?? 500,
      timestamp: DateTime.now(),
    );
  }

  // ===== ゲッターメソッド =====

  /// 成功かどうかを判定
  bool get isSuccess => status == ApiStatus.success;

  /// エラーかどうかを判定
  bool get isError => status == ApiStatus.error;

  /// タイムアウトかどうかを判定
  bool get isTimeout => status == ApiStatus.timeout;

  /// キャンセルかどうかを判定
  bool get isCancelled => status == ApiStatus.cancelled;

  /// ネットワークエラーかどうかを判定
  bool get isNetworkError => isError && statusCode == null;

  /// サーバーエラーかどうかを判定（5xx系）
  bool get isServerError => isError && statusCode != null && statusCode! >= 500;

  /// クライアントエラーかどうかを判定（4xx系）
  bool get isClientError =>
      isError && statusCode != null && statusCode! >= 400 && statusCode! < 500;

  /// データが存在するかどうかを判定
  bool get hasData => data != null;

  /// レスポンスの経過時間を取得（秒）
  double get elapsedSeconds =>
      DateTime.now().difference(timestamp).inMilliseconds / 1000.0;

  // ===== ファクトリメソッド =====

  /// JSONからApiResponseを作成
  /// サーバーのレスポンス形式を統一的に処理
  static ApiResponse<T> fromJson<T>(
    Map<String, dynamic> json,
    T Function(dynamic) fromData,
  ) {
    try {
      // レスポンス形式1: {"code": 200, "data": {}, "message": ""}
      if (json.containsKey('code')) {
        final code = json['code'] as int?;
        final message = json['message'] as String?;

        if (code == 200 || code == 201) {
          final data = fromData(json['data']);
          return ApiResponse.success(data, message: message, statusCode: code);
        } else {
          return ApiResponse.error(message ?? 'APIエラーが発生しました', code: code);
        }
      }

      // レスポンス形式2: {"success": true, "data": {}, "message": ""}
      if (json.containsKey('success')) {
        final success = json['success'] as bool? ?? false;
        final message = json['message'] as String?;

        if (success) {
          final data = fromData(json['data']);
          return ApiResponse.success(data, message: message);
        } else {
          return ApiResponse.error(message ?? 'APIエラーが発生しました');
        }
      }

      // レスポンス形式3: 直接データオブジェクト
      final data = fromData(json);
      return ApiResponse.success(data);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('💥 JSON解析エラー: $e');
        debugPrint('📄 問題のあるJSON: $json');
      }

      return ApiResponse.error('レスポンスの解析に失敗しました: $e');
    }
  }

  /// リストデータ専用のファクトリメソッド
  static ApiResponse<List<T>> fromJsonList<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromData,
  ) {
    try {
      if (json.containsKey('code')) {
        final code = json['code'] as int?;
        final message = json['message'] as String?;

        if (code == 200 || code == 201) {
          final dataList = json['data'] as List?;
          if (dataList != null) {
            final items =
                dataList
                    .cast<Map<String, dynamic>>()
                    .map((item) => fromData(item))
                    .toList();
            return ApiResponse.success(
              items,
              message: message,
              statusCode: code,
            );
          } else {
            return ApiResponse.success(
              <T>[],
              message: message,
              statusCode: code,
            );
          }
        } else {
          return ApiResponse.error(message ?? 'APIエラーが発生しました', code: code);
        }
      }

      // 直接リスト形式の場合
      final dataList = json['data'] as List? ?? json as List?;
      if (dataList != null) {
        final items =
            dataList
                .cast<Map<String, dynamic>>()
                .map((item) => fromData(item))
                .toList();
        return ApiResponse.success(items);
      }

      return ApiResponse.success(<T>[]);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('💥 JSONリスト解析エラー: $e');
      }

      return ApiResponse.error('リストデータの解析に失敗しました: $e');
    }
  }

  // ===== ユーティリティメソッド =====

  /// データを安全に取得（デフォルト値付き）
  T getDataOrElse(T defaultValue) {
    return data ?? defaultValue;
  }

  /// エラーメッセージを安全に取得
  String getErrorMessage() {
    return message ?? '不明なエラーが発生しました';
  }

  /// ユーザーフレンドリーなメッセージを取得
  String getUserFriendlyMessage() {
    switch (status) {
      case ApiStatus.success:
        return message ?? '処理が正常に完了しました';
      case ApiStatus.error:
        if (isNetworkError) {
          return 'ネットワーク接続を確認してください';
        } else if (isServerError) {
          return 'サーバーで問題が発生しています。しばらくしてから再度お試しください';
        } else if (statusCode == 401) {
          return '認証が必要です。再度ログインしてください';
        } else if (statusCode == 403) {
          return 'この操作を実行する権限がありません';
        } else if (statusCode == 404) {
          return '要求されたリソースが見つかりません';
        } else {
          return message ?? 'エラーが発生しました';
        }
      case ApiStatus.timeout:
        return '通信がタイムアウトしました。しばらくしてから再度お試しください';
      case ApiStatus.cancelled:
        return 'リクエストがキャンセルされました';
    }
  }

  /// レスポンスを別の型に変換
  ApiResponse<U> map<U>(U Function(T) transform) {
    if (isSuccess && data != null) {
      try {
        final transformedData = transform(data as T);
        return ApiResponse.success(
          transformedData,
          message: message,
          statusCode: statusCode,
        );
      } catch (e) {
        return ApiResponse.error('データ変換エラー: $e');
      }
    } else {
      return ApiResponse._(
        status: status,
        message: message,
        statusCode: statusCode,
        timestamp: timestamp,
      );
    }
  }

  /// レスポンスをfold操作で処理
  U fold<U>(
    U Function(T data) onSuccess,
    U Function(String error, int? statusCode) onError,
  ) {
    if (isSuccess && data != null) {
      return onSuccess(data as T);
    } else {
      return onError(getErrorMessage(), statusCode);
    }
  }

  /// デバッグ用の詳細情報を取得
  Map<String, dynamic> toDebugMap() {
    return {
      'status': status.toString(),
      'statusCode': statusCode,
      'message': message,
      'hasData': hasData,
      'timestamp': timestamp.toIso8601String(),
      'elapsedSeconds': elapsedSeconds,
    };
  }

  @override
  String toString() {
    final statusText =
        {
          ApiStatus.success: '成功',
          ApiStatus.error: 'エラー',
          ApiStatus.timeout: 'タイムアウト',
          ApiStatus.cancelled: 'キャンセル',
        }[status] ??
        '不明';

    return 'ApiResponse{status: $statusText, statusCode: $statusCode, message: $message, hasData: $hasData}';
  }

  /// 等価性の比較
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ApiResponse<T> &&
        other.status == status &&
        other.statusCode == statusCode &&
        other.message == message &&
        other.data == data;
  }

  @override
  int get hashCode {
    return status.hashCode ^
        (statusCode?.hashCode ?? 0) ^
        (message?.hashCode ?? 0) ^
        (data?.hashCode ?? 0);
  }
}

/// ページネーション対応データ処理用のApiResponse拡張クラス
/// リスト形式のデータとページング情報を統合的に管理
class PaginatedApiResponse<T> extends ApiResponse<List<T>> {
  /// 現在のページ番号
  final int currentPage;

  /// 全ページ数
  final int totalPages;

  /// 全アイテム数
  final int totalItems;

  /// ページあたりのアイテム数
  final int itemsPerPage;

  /// 次ページの存在フラグ
  final bool hasNextPage;

  /// 前ページの存在フラグ
  final bool hasPreviousPage;

  const PaginatedApiResponse._({
    required super.status,
    super.data,
    super.message,
    super.statusCode,
    required super.timestamp,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
    required this.hasNextPage,
    required this.hasPreviousPage,
  }) : super._();

  /// ページネーション成功レスポンスを作成
  factory PaginatedApiResponse.success(
    List<T> data, {
    required int currentPage,
    required int totalPages,
    required int totalItems,
    required int itemsPerPage,
    String? message,
    int? statusCode,
  }) {
    if (kDebugMode) {
      debugPrint(
        '📄 ページネーション成功: ${data.length}件 ($currentPage/$totalPagesページ)',
      );
    }

    return PaginatedApiResponse._(
      status: ApiStatus.success,
      data: data,
      message: message,
      statusCode: statusCode ?? 200,
      timestamp: DateTime.now(),
      currentPage: currentPage,
      totalPages: totalPages,
      totalItems: totalItems,
      itemsPerPage: itemsPerPage,
      hasNextPage: currentPage < totalPages,
      hasPreviousPage: currentPage > 1,
    );
  }

  /// ページネーションエラーレスポンスを作成
  factory PaginatedApiResponse.error(String message, {int? code}) {
    if (kDebugMode) {
      debugPrint('❌ ページネーションエラー: $message');
    }

    return PaginatedApiResponse._(
      status: ApiStatus.error,
      message: message,
      statusCode: code,
      timestamp: DateTime.now(),
      currentPage: 0,
      totalPages: 0,
      totalItems: 0,
      itemsPerPage: 0,
      hasNextPage: false,
      hasPreviousPage: false,
    );
  }

  /// JSONからページネーションレスポンスを作成
  /// サーバーからのページング情報を解析してオブジェクトを構築
  static PaginatedApiResponse<T> fromJson<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromData,
  ) {
    try {
      // 成功レスポンスの判定
      final isSuccess = json['code'] == 200 || json['success'] == true;

      if (isSuccess) {
        final dataList = json['data'] as List?;
        final pagination = json['pagination'] as Map<String, dynamic>?;

        // データリストをオブジェクトに変換
        final items =
            dataList
                ?.cast<Map<String, dynamic>>()
                .map((item) => fromData(item))
                .toList() ??
            <T>[];

        // ページング情報を抽出（デフォルト値付き）
        final currentPage = pagination?['current_page'] ?? 1;
        final totalPages = pagination?['total_pages'] ?? 1;
        final totalItems = pagination?['total_items'] ?? items.length;
        final itemsPerPage = pagination?['items_per_page'] ?? items.length;

        if (kDebugMode) {
          debugPrint(
            '📊 ページング解析完了: $currentPage/$totalPages ページ, 合計 $totalItems 件',
          );
        }

        return PaginatedApiResponse.success(
          items,
          currentPage: currentPage,
          totalPages: totalPages,
          totalItems: totalItems,
          itemsPerPage: itemsPerPage,
          message: json['message'],
          statusCode: json['code'],
        );
      } else {
        return PaginatedApiResponse.error(
          json['message'] ?? 'ページネーションAPIエラーが発生しました',
          code: json['code'],
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('💥 ページネーションJSON解析エラー: $e');
      }

      return PaginatedApiResponse.error('ページネーションデータの解析に失敗しました: $e');
    }
  }

  // ===== ページネーション専用ユーティリティメソッド =====

  /// 現在のページングサマリーを取得
  String getPageSummary() {
    if (totalItems == 0) {
      return 'データがありません';
    }

    final startItem = (currentPage - 1) * itemsPerPage + 1;
    final endItem = (startItem + data!.length - 1).clamp(startItem, totalItems);

    return '$startItem-$endItem件 / 全$totalItems件 ($currentPage/$totalPagesページ)';
  }

  /// 指定ページが有効かチェック
  bool isValidPage(int page) {
    return page >= 1 && page <= totalPages;
  }

  /// 最初のページかどうか判定
  bool get isFirstPage => currentPage == 1;

  /// 最後のページかどうか判定
  bool get isLastPage => currentPage == totalPages;

  /// 空のデータかどうか判定
  bool get isEmpty => data?.isEmpty ?? true;

  /// データが存在するかどうか判定
  bool get isNotEmpty => !isEmpty;

  /// ページネーション情報のデバッグマップを取得
  Map<String, dynamic> toPaginationDebugMap() {
    return {
      ...toDebugMap(),
      'currentPage': currentPage,
      'totalPages': totalPages,
      'totalItems': totalItems,
      'itemsPerPage': itemsPerPage,
      'hasNextPage': hasNextPage,
      'hasPreviousPage': hasPreviousPage,
      'isFirstPage': isFirstPage,
      'isLastPage': isLastPage,
      'isEmpty': isEmpty,
      'pageSummary': getPageSummary(),
    };
  }

  @override
  String toString() {
    return 'PaginatedApiResponse{${getPageSummary()}, status: $status, hasData: $hasData}';
  }
}
