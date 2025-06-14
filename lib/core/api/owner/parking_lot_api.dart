import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:parking_app/core/api/api_constants.dart';
import 'package:parking_app/core/api/api_response.dart';
import 'package:parking_app/core/client/dio_client.dart';
import 'package:parking_app/core/models/parking_lots_model.dart';
/// 駐車場登録API - DioClientを使用したAPIラッパー
class ParkingLotApi {
  final DioClient _client;

  /// デフォルトコンストラクタ
  ParkingLotApi() : _client = DioClient();

  /// 依存性注入用のネームドコンストラクタ
  ParkingLotApi.withClient(DioClient client) : _client = client;

  Future<ApiResponse> parkingLotCreate(ParkingLotsModel request) async {
    try {
      if (request.parkingLotName.isEmpty) {
        return ApiResponse.error("駐車場名は必須です");
      }

      debugPrint('🔵 （parking_lot_api.dart）駐車場登録リクエスト送信: ${request.toJson()}');

      final response = await _client.post(
        ApiConstants.CREATE_PARKING_LOT,
        data: request.toJson(),
        requiresAuth: false,
      );

      debugPrint('🟢 （parking_lot_api.dart）駐車場登録レスポンス: ${response}');

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
      debugPrint('❌ 駐車場登録エラー: $e');
      if (e is DioException && e.response != null) {
        return ApiResponse.error(
          'エラー: ${e.response!.statusCode} - ${e.response!.statusMessage ?? e.message}',
          code: e.response!.statusCode,
        );
      }
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<List<ParkingLotsModel>>> getParkingLotsByOwnerId(String ownerId) async {

    debugPrint('⭕️（parking_lot_api.dart）パラメータ: ownerId = $ownerId');
    try {
      final response = await _client.post(
        ApiConstants.GET_PARKING_LOTS_BY_OWNER_ID,
        data: {'owner_id': ownerId},
      );

      debugPrint('⭕️（parking_lot_api.dart）响应体: ${response.data}');

      return ApiResponse.fromJson(
        response.data,
        (data) => (data as List)
            .map((item) => ParkingLotsModel.fromJson(item))
            .toList(),
      );
    } catch (e) {
      debugPrint('❌ （parking_lot_api.dart）駐車場一覧取得失敗: $e');
      return ApiResponse.error(e.toString());
    }
  }


      // final response = await _client.post(
      //   ApiConstants.SIGNIN,
      //   data: request.toJson(),
      // );

      // // Log response (avoid in production)
      // debugPrint('Signin response: ${response.data}');

    // try {
    //   final response = await _client.post(
    //     ApiConstants.CREATE_PARKING_LOT,
    //     data: model.toJson(),
    //   );
    //   debugPrint('✅ （dart）响应状态码: ${response.statusCode}');
    //   debugPrint('✅ （dart）响应体: ${response.data}');

    //   return ApiResponse.fromJson(
    //     response.data,
    //     (json) => ParkingLotModel.fromJson(json as Map<String, dynamic>),
    //   );

    // } catch (e) {
    //   debugPrint('❌ （dart）Dio 请求失败: $e');
    //   return ApiResponse.error(e.toString());
    // }
  }



  // Future<bool> registerParkingLot(ParkingLotModel request) async {
  //   try {
  //     final response = await _client.post(
  //       '/parking_lots',
  //       data: request.toJson(),
  //     );
  //     return response.statusCode == 200 || response.statusCode == 201;
  //   } catch (e) {
  //     print('API error: $e');
  //     return false;
  //   }
  // }
  // Future<ApiResponse<ParkingLotModel>> registerParkingLot(
  //   ParkingLotModel model,
  // ) async {
  //   try {
  //     final response = await _client.post(
  //       ApiConstants.CREATE_PARKING_LOT,
  //       data: model.toJson(),
  //     );
  //     return ApiResponse.fromJson(
  //       response.data,
  //       (data) => ParkingLotModel.fromJson(data),
  //     );
  //   } catch (e) {
  //     return ApiResponse.error(e.toString());
  //   }
  // }


  // Future<ApiResponse<ParkingLotModel>> getParkingLotById(String id) async {
  //   try {
  //     final response = await _client.get(
  //       '${ApiConstants.GET_PARKING_LOT_BY_ID}/$id', 
  //     );
  //     return ApiResponse.fromJson(
  //       response.data,
  //       (data) => ParkingLotModel.fromJson(data),
  //     );
  //   } catch (e) {
  //     return ApiResponse.error(e.toString());
  //   }
  // }

  // Future<ApiResponse<ParkingLotModel>> getParkingLotById(String id) async {
  //   try {
  //     final response = await _client.post(
  //       ApiConstants.GET_PARKING_LOT_BY_ID,
  //       data: {'parkingLotId': id},
  //     );
  //     return ApiResponse.fromJson(
  //       response.data,
  //       (data) => ParkingLotModel.fromJson(data),
  //     );
  //   } catch (e) {
  //     return ApiResponse.error(e.toString());
  //   }
  // }

