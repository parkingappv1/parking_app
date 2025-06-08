import 'package:flutter/material.dart';
import 'package:parking_app/core/api/api_response.dart';
import 'package:parking_app/core/api/user/use_history_api.dart';
import 'package:parking_app/core/models/parking_feature.dart';
import 'package:parking_app/core/models/parking_lot_model.dart';
import 'package:parking_app/core/models/use_history_model.dart';

class UseHistoryService extends ChangeNotifier {
  final UseHistoryApi _api;
  bool _isLoading = false;

  UseHistoryService(this._api);

  bool get isLoading => _isLoading;

  /// 駐車場利用履歴の取得
  Future<ApiResponse<List>> getUseHistories(String? user_id) async {
    _isLoading = true;
    //notifyListeners();

    try {
      final response = await _api.getUseHistories(
        UseHistoryRequest(user_id: user_id),
      );

      if (response.isSuccess && response.data != null) {
        // Save auth data to secure storage
      }

      _isLoading = false;
      // notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      //notifyListeners();
      return ApiResponse.error(e.toString());
    }
  }

  /// 駐車場利用履歴詳細の取得
  Future<ApiResponse<UseHistoryDetailModel>> getUseHistoryDetail(
    String? reservation_id,
  ) async {
    _isLoading = true;
    //notifyListeners();

    try {
      final response = await _api.getUseHistoryDetail(
        UseHistoryDetailRequest(reservation_id: reservation_id),
      );

      if (response.isSuccess && response.data != null) {}

      _isLoading = false;
      // notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      //notifyListeners();
      return ApiResponse.error(e.toString());
    }
  }

  /// 駐車場特徴の取得
  Future<ApiResponse<List>> getParkingFeatures(String? parking_lot_id) async {
    _isLoading = true;
    //notifyListeners();

    try {
      final response = await _api.getParkingFeatures(
        ParkingFeatureRequest(parking_lot_id: parking_lot_id),
      );

      if (response.isSuccess && response.data != null) {
        // Save auth data to secure storage
      }

      _isLoading = false;
      // notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      //notifyListeners();
      return ApiResponse.error(e.toString());
    }
  }

  /// 駐車場基本情報の取得
  Future<ApiResponse<ParkingLotModel>> getParkingLots(
    String? parking_lot_id,
  ) async {
    _isLoading = true;
    //notifyListeners();

    try {
      final response = await _api.getParkingLots(
        ParkingLotRequest(parking_lot_id: parking_lot_id),
      );

      if (response.isSuccess && response.data != null) {}

      _isLoading = false;
      // notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      //notifyListeners();
      return ApiResponse.error(e.toString());
    }
  }
}
