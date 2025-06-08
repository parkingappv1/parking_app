import 'package:dio/dio.dart';
import 'package:parking_app/core/api/api_constants.dart';
import 'package:parking_app/core/api/api_response.dart';
import 'package:parking_app/core/client/dio_client.dart';
import 'package:flutter/material.dart';
import 'package:parking_app/core/models/favorite_model.dart';
import 'package:parking_app/core/models/parking_status_model.dart';
import 'package:parking_app/core/models/search_history_model.dart';

class UserHomeApi {
  final DioClient _client;

  /// デフォルトコンストラクタ - 独自のDioClientインスタンスを作成
  UserHomeApi() : _client = DioClient();

  /// 依存性注入用のネームドコンストラクタ
  UserHomeApi.withClient(DioClient client) : _client = client;

  /// 入出庫状況の取得
  Future<ApiResponse<ParkingStatusModel>> getParKingStatus(
    ParkingStausRequest request,
  ) async {
    try {
      // Log request (avoid logging sensitive data in production)
      debugPrint('Sending getParKingStatus request: ${request.toJson()}');

      final response = await _client.post(
        ApiConstants.PARKING_STATUS,
        data: request.toJson(),
      );

      // Log response (avoid in production)
      debugPrint('getParKingStatus response: ${response.data}');

      return ApiResponse.success(ParkingStatusModel.fromJson(response.data));
    } catch (e) {
      debugPrint('getParKingStatus error: $e');
      if (e is DioException && e.response != null) {
        return ApiResponse.error(
          'Error: ${e.response!.statusCode} - ${e.response!.statusMessage ?? e.message}',
          code: e.response!.statusCode,
        );
      }
      return ApiResponse.error(e.toString());
    }
  }

  ///　入出庫状況の更新
  Future<ApiResponse<void>> updateParkingStatus(
    UpdateParkingStausRequest request,
  ) async {
    try {
      final response = await _client.post(
        ApiConstants.UPDATE_STATUS,
        data: request.toJson(),
      );
      return ApiResponse.fromJson(response.data, (_) {});
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  ///　駐車場検索履歴の取得
  Future<ApiResponse<List>> getSearchHistories(
    SearchHistoryRequest request,
  ) async {
    try {
      // Log request (avoid logging sensitive data in production)
      debugPrint('Sending getSearchHistories request: ${request.toJson()}');

      final response = await _client.post(
        ApiConstants.SEARCH_HISTORY,
        data: request.toJson(),
      );

      // Log response (avoid in production)
      debugPrint('getSearchHistories response: ${response.data}');

      return ApiResponse.success(response.data);
    } catch (e) {
      debugPrint('getSearchHistories error: $e');
      if (e is DioException && e.response != null) {
        return ApiResponse.error(
          'Error: ${e.response!.statusCode} - ${e.response!.statusMessage ?? e.message}',
          code: e.response!.statusCode,
        );
      }
      return ApiResponse.error(e.toString());
    }
  }

  /// お気に入りの取得
  Future<ApiResponse<List>> getFavorites(FavoriteRequest request) async {
    try {
      // Log request (avoid logging sensitive data in production)
      debugPrint('Sending getFavoriteList request: ${request.toJson()}');

      final response = await _client.post(
        ApiConstants.FFAVORITES,
        data: request.toJson(),
      );

      // Log response (avoid in production)
      debugPrint('getFavoriteList response: ${response.data}');

      return ApiResponse.success(response.data);
    } catch (e) {
      debugPrint('getFavoriteList error: $e');
      if (e is DioException && e.response != null) {
        return ApiResponse.error(
          'Error: ${e.response!.statusCode} - ${e.response!.statusMessage ?? e.message}',
          code: e.response!.statusCode,
        );
      }
      return ApiResponse.error(e.toString());
    }
  }
}
