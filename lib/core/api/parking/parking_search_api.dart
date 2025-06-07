import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:parking_app/core/api/api_constants.dart';
import 'package:parking_app/core/api/api_response.dart';
import 'package:parking_app/core/client/dio_client.dart';
import 'package:parking_app/core/models/parking_search_model.dart';

/// 駐車場検索API - DioClientを使用した統一されたAPI層
/// 駐車場検索、フィルタリング、お気に入り管理のエンドポイントを提供
class ParkingSearchApi {
  final DioClient _client;

  /// デフォルトコンストラクタ - 独自のDioClientインスタンスを作成
  ParkingSearchApi() : _client = DioClient();

  /// 依存性注入用のネームドコンストラクタ
  ParkingSearchApi.withClient(DioClient client) : _client = client;

  /// 駐車場検索
  ///
  /// [searchModel] 検索条件を含むモデル
  /// Returns: [ApiResponse<ParkingSearchResponse>] 検索結果のレスポンス
  Future<ApiResponse<ParkingSearchResponse>> searchParkingLots(
    ParkingSearchRequestModel searchModel,
  ) async {
    try {
      if (kDebugMode) {
        debugPrint('🔍 駐車場検索API開始: ${searchModel.toJson()}');
      }

      final response = await _client.post<Map<String, dynamic>>(
        ApiConstants.PARKING_SEARCH,
        data: searchModel.toJson(),
        requiresAuth: true,
      );

      if (response.data != null) {
        final searchResponse = ParkingSearchResponse.fromJson(response.data!);

        if (kDebugMode) {
          debugPrint('✅ 駐車場検索成功: ${searchResponse.parkingLots.length}件');
        }

        return ApiResponse.success(
          searchResponse,
          message: '駐車場検索が完了しました',
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.error(
          '検索結果データが取得できませんでした',
          code: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('💥 駐車場検索APIエラー: ${e.message}');
      }

      return ApiResponse.error(
        'ネットワークエラーが発生しました: ${e.message}',
        code: e.response?.statusCode,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('💥 駐車場検索予期しないエラー: $e');
      }

      return ApiResponse.error('駐車場検索中にエラーが発生しました');
    }
  }

  /// 駐車場詳細取得
  ///
  /// [parkingLotId] 駐車場ID
  /// Returns: [ApiResponse<ParkingLotDetailModel>] 駐車場詳細データ
  Future<ApiResponse<ParkingLotDetailModel>> getParkingLotDetail(
    String parkingLotId,
  ) async {
    try {
      if (kDebugMode) {
        debugPrint('🏢 駐車場詳細API開始: $parkingLotId');
      }

      final response = await _client.get<Map<String, dynamic>>(
        '${ApiConstants.PARKING_DETAILS}/$parkingLotId',
        requiresAuth: true,
      );

      if (response.data != null) {
        final detailModel = ParkingLotDetailModel.fromJson(response.data!);

        if (kDebugMode) {
          debugPrint('✅ 駐車場詳細取得成功: ${detailModel.parkingLotName}');
        }

        return ApiResponse.success(
          detailModel,
          message: '駐車場詳細の取得が完了しました',
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.error(
          '駐車場詳細データが取得できませんでした',
          code: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('💥 駐車場詳細APIエラー: ${e.message}');
      }

      return ApiResponse.error(
        'ネットワークエラーが発生しました: ${e.message}',
        code: e.response?.statusCode,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('💥 駐車場詳細予期しないエラー: $e');
      }

      return ApiResponse.error('駐車場詳細取得中にエラーが発生しました');
    }
  }

  /// お気に入り追加
  ///
  /// [parkingLotId] 駐車場ID
  /// Returns: [ApiResponse<void>] 追加結果
  Future<ApiResponse<void>> addToFavorites(String parkingLotId) async {
    try {
      if (kDebugMode) {
        debugPrint('❤️ お気に入り追加API開始: $parkingLotId');
      }

      final response = await _client.post<Map<String, dynamic>>(
        '${ApiConstants.PARKING_BASE}/favorites',
        data: {'parking_lot_id': parkingLotId},
        requiresAuth: true,
      );

      if (kDebugMode) {
        debugPrint('✅ お気に入り追加成功');
      }

      return ApiResponse.success(
        null,
        message: 'お気に入りに追加しました',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('💥 お気に入り追加APIエラー: ${e.message}');
      }

      return ApiResponse.error(
        'ネットワークエラーが発生しました: ${e.message}',
        code: e.response?.statusCode,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('💥 お気に入り追加予期しないエラー: $e');
      }

      return ApiResponse.error('お気に入り追加中にエラーが発生しました');
    }
  }

  /// お気に入り削除
  ///
  /// [parkingLotId] 駐車場ID
  /// Returns: [ApiResponse<void>] 削除結果
  Future<ApiResponse<void>> removeFromFavorites(String parkingLotId) async {
    try {
      if (kDebugMode) {
        debugPrint('💔 お気に入り削除API開始: $parkingLotId');
      }

      final response = await _client.delete<Map<String, dynamic>>(
        '${ApiConstants.PARKING_BASE}/favorites/$parkingLotId',
        requiresAuth: true,
      );

      if (kDebugMode) {
        debugPrint('✅ お気に入り削除成功');
      }

      return ApiResponse.success(
        null,
        message: 'お気に入りから削除しました',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('💥 お気に入り削除APIエラー: ${e.message}');
      }

      return ApiResponse.error(
        'ネットワークエラーが発生しました: ${e.message}',
        code: e.response?.statusCode,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('💥 お気に入り削除予期しないエラー: $e');
      }

      return ApiResponse.error('お気に入り削除中にエラーが発生しました');
    }
  }

  /// お気に入り一覧取得
  ///
  /// [page] ページ番号（デフォルト: 1）
  /// [perPage] 1ページあたりの件数（デフォルト: 20）
  /// Returns: [ApiResponse<ParkingSearchResponse>] お気に入り駐車場一覧
  Future<ApiResponse<ParkingSearchResponse>> getFavorites({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('💖 お気に入り一覧API開始: page=$page, perPage=$perPage');
      }

      final response = await _client.get<Map<String, dynamic>>(
        '${ApiConstants.PARKING_BASE}/favorites',
        queryParameters: {
          ApiConstants.PARAM_PAGE: page,
          ApiConstants.PARAM_PER_PAGE: perPage,
        },
        requiresAuth: true,
      );

      if (response.data != null) {
        final favoritesResponse = ParkingSearchResponse.fromJson(
          response.data!,
        );

        if (kDebugMode) {
          debugPrint('✅ お気に入り一覧取得成功: ${favoritesResponse.parkingLots.length}件');
        }

        return ApiResponse.success(
          favoritesResponse,
          message: 'お気に入り一覧の取得が完了しました',
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.error(
          'お気に入りデータが取得できませんでした',
          code: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('💥 お気に入り一覧APIエラー: ${e.message}');
      }

      return ApiResponse.error(
        'ネットワークエラーが発生しました: ${e.message}',
        code: e.response?.statusCode,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('💥 お気に入り一覧予期しないエラー: $e');
      }

      return ApiResponse.error('お気に入り一覧取得中にエラーが発生しました');
    }
  }

  /// リソースクリーンアップ
  void dispose() {
    // 必要に応じてリソースをクリーンアップ
    if (kDebugMode) {
      debugPrint('🧹 ParkingSearchApi disposed');
    }
  }
}
