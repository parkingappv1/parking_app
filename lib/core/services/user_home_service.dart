import 'package:flutter/material.dart';
import 'package:parking_app/core/api/api_response.dart';
import 'package:parking_app/core/api/user/user_home_api.dart';
import 'package:parking_app/core/models/favorite_model.dart';
import 'package:parking_app/core/models/parking_status_model.dart';
import 'package:parking_app/core/models/search_history_model.dart';

class UserHomeService extends ChangeNotifier {
  final UserHomeApi _api;
  bool _isLoading = false;

  UserHomeService(this._api);

  bool get isLoading => _isLoading;

  /// 入出庫状況の取得
  Future<ApiResponse<ParkingStatusModel>> getParkingStatus(
    String? user_id,
    String? status,
  ) async {
    _isLoading = true;
    //notifyListeners();

    try {
      final response = await _api.getParKingStatus(
        ParkingStausRequest(user_id: user_id, status: status),
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

  /// 入出庫状況の更新
  Future<void> updateParkingStatus(
    String? status_id,
    String? reservation_id,
    String? checkInOutKbn,
  ) async {
    _isLoading = true;
    // notifyListeners();

    try {
      await _api.updateParkingStatus(
        UpdateParkingStausRequest(
          status_id: status_id,
          reservation_id: reservation_id,
          checkInOutKbn: checkInOutKbn,
        ),
      );
    } catch (e) {
      // Even if API call fails, clear local data
      debugPrint('Error during updateParkingStatus: $e');
    } finally {
      _isLoading = false;
      // notifyListeners();
    }
  }

  /// 駐車場検索履歴の取得
  Future<ApiResponse<List>> getSearchHistories(String? user_id) async {
    _isLoading = true;
    //notifyListeners();

    try {
      final response = await _api.getSearchHistories(
        SearchHistoryRequest(user_id: user_id),
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

  /// お気に入りの取得
  Future<ApiResponse<List>> getFavorites(String? user_id) async {
    _isLoading = true;
    //notifyListeners();

    try {
      final response = await _api.getFavorites(
        FavoriteRequest(user_id: user_id),
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
}
