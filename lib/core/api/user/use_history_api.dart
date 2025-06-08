import 'package:dio/dio.dart';
import 'package:parking_app/core/api/api_constants.dart';
import 'package:parking_app/core/api/api_response.dart';
import 'package:parking_app/core/client/dio_client.dart';
import 'package:flutter/material.dart';
import 'package:parking_app/core/models/parking_feature.dart';
import 'package:parking_app/core/models/parking_lot_model.dart';
import 'package:parking_app/core/models/use_history_model.dart';

class UseHistoryApi {
  final DioClient _client;

  /// デフォルトコンストラクタ - 独自のDioClientインスタンスを作成
  UseHistoryApi() : _client = DioClient();

  /// 依存性注入用のネームドコンストラクタ
  UseHistoryApi.withClient(DioClient client) : _client = client;

  ///　駐車場利用履歴の取得
  Future<ApiResponse<List>> getUseHistories(UseHistoryRequest request) async {
    try {
      // Log request (avoid logging sensitive data in production)
      debugPrint('Sending getUseHistories request: ${request.toJson()}');

      final response = await _client.post(
        ApiConstants.USE_HISTORY,
        data: request.toJson(),
      );

      // Log response (avoid in production)
      debugPrint('getUseHistories response: ${response.data}');

      return ApiResponse.success(response.data);
    } catch (e) {
      debugPrint('getUseHistories error: $e');
      if (e is DioException && e.response != null) {
        return ApiResponse.error(
          'Error: ${e.response!.statusCode} - ${e.response!.statusMessage ?? e.message}',
          code: e.response!.statusCode,
        );
      }
      return ApiResponse.error(e.toString());
    }
  }

  /// 利用履歴詳細の取得
  Future<ApiResponse<UseHistoryDetailModel>> getUseHistoryDetail(
    UseHistoryDetailRequest request,
  ) async {
    try {
      // Log request (avoid logging sensitive data in production)
      debugPrint('Sending getUseHistoryDetail request: ${request.toJson()}');

      final response = await _client.post(
        ApiConstants.USE_HISTORY_DETAIL,
        data: request.toJson(),
      );

      // Log response (avoid in production)
      debugPrint('getUseHistoryDetail response: ${response.data}');

      return ApiResponse.success(UseHistoryDetailModel.fromJson(response.data));
    } catch (e) {
      debugPrint('getUseHistoryDetail error: $e');
      if (e is DioException && e.response != null) {
        return ApiResponse.error(
          'Error: ${e.response!.statusCode} - ${e.response!.statusMessage ?? e.message}',
          code: e.response!.statusCode,
        );
      }
      return ApiResponse.error(e.toString());
    }
  }

  /// 駐車場特徴の取得
  Future<ApiResponse<List>> getParkingFeatures(
    ParkingFeatureRequest request,
  ) async {
    try {
      // Log request (avoid logging sensitive data in production)
      debugPrint('Sending getParkingFeatures request: ${request.toJson()}');

      final response = await _client.post(
        ApiConstants.PARKING_FEATURES,
        data: request.toJson(),
      );

      // Log response (avoid in production)
      debugPrint('getParkingFeatures response: ${response.data}');

      return ApiResponse.success(response.data);
    } catch (e) {
      debugPrint('getParkingFeatures error: $e');
      if (e is DioException && e.response != null) {
        return ApiResponse.error(
          'Error: ${e.response!.statusCode} - ${e.response!.statusMessage ?? e.message}',
          code: e.response!.statusCode,
        );
      }
      return ApiResponse.error(e.toString());
    }
  }

  /// 駐車場基本情報の取得
  Future<ApiResponse<ParkingLotModel>> getParkingLots(
    ParkingLotRequest request,
  ) async {
    try {
      // Log request (avoid logging sensitive data in production)
      debugPrint('Sending getParkingLots request: ${request.toJson()}');

      final response = await _client.post(
        ApiConstants.PARKING_LOTS,
        data: request.toJson(),
      );

      // Log response (avoid in production)
      debugPrint('getParkingLots response: ${response.data}');

      return ApiResponse.success(ParkingLotModel.fromJson(response.data));
    } catch (e) {
      debugPrint('getParkingLots error: $e');
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
