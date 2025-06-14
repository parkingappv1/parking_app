import 'package:flutter/material.dart';
import 'package:parking_app/core/api/api_response.dart';
import 'package:parking_app/core/api/owner/parking_lot_api.dart';
import 'package:parking_app/core/models/parking_lots_model.dart';

/// 駐車場登録サービス - ビジネスロジック & 状態管理を担当
class ParkingLotService extends ChangeNotifier {
  final ParkingLotApi _api;

  ParkingLotService(this._api);

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 駐車場登録を実行
  Future<ApiResponse<ParkingLotSummaryModel>> registerParkingLot(ParkingLotsModel model) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('（parking_lot_service.dart） 駐車場登録サービス開始');

      // 入力チェック
      final validationError = _validateParkingLotData(model);
      if (validationError != null) {
        debugPrint('❌ （parking_lot_service.dart）バリデーションエラー: $validationError');
        _error = validationError;
        _isLoading = false;
        notifyListeners();
        return ApiResponse.error(validationError);
      }

      debugPrint('（parking_lot_service.dart）送信データ: ${model.toJson()}');
      final response = await _api.parkingLotCreate(model);
      debugPrint('🟢 （parking_lot_service.dart）APIレスポンス: $response');

      if (response.isSuccess && response.data != null) {
        _isLoading = false;
        notifyListeners();

        // ParkingLotsModel ではなく Map で包んで返す
        return ApiResponse.success(ParkingLotSummaryModel.fromJson(response.data), message: "駐車場登録が完了しました");
      } else {
        final message = _enhanceErrorMessage(response.message ?? "駐車場登録に失敗しました");
        debugPrint('❌ （parking_lot_service.dart）駐車場登録失敗: $message');

        _error = message;
        _isLoading = false;
        notifyListeners();
        return ApiResponse.error(message, code: response.statusCode);
      }

    } catch (e, stack) {
      debugPrint('💥 （parking_lot_service.dart）予期しないエラー: $e');
      debugPrint('$stack');
      _isLoading = false;
      notifyListeners();
      return ApiResponse.error("駐車場登録中に予期しないエラーが発生しました");
    }
  }

  /// 駐車場登録データのバリデーション
  String? _validateParkingLotData(ParkingLotsModel model) {
    if (model.parkingLotName.trim().isEmpty) return "駐車場名は必須です";
    if (model.parkingLotName.trim().isEmpty) return "駐車場名は必須です";

    if (model.addressDetail.trim().isEmpty) return "住所詳細は必須です";
    if (model.phoneNumber.trim().isEmpty) return "電話番号は必須です";
    // 他の必要なチェック項目をここに追加可能
    return null;
  }

  /// エラーメッセージをユーザー向けに整形
  String _enhanceErrorMessage(String raw) {
    if (raw.contains("timeout")) return "サーバーへの接続がタイムアウトしました";
    if (raw.contains("401")) return "認証エラー。再ログインしてください";
    return raw;
  }



  // 获取 list_parking_lots 方法
  Future<List<ParkingLotsModel>> getParkingLotsByOwnerId(String ownerId) async {
    try {
      final response = await _api.getParkingLotsByOwnerId(ownerId);
      for (var lot in response.data ?? []) {
        debugPrint('⭕️ （parking_lot_service.dart）service 拿到的 駐車場: ${lot.toJson()}');
      }
      if (response.isSuccess && response.data != null){
        return response.data!;
      } else {
        debugPrint("❌（parking_lot_service.dart） 駐車場一覧の取得に失敗しました: ${response.message}");
        return [];
      }
    } catch (e, stack) {
      debugPrint("❌（parking_lot_service.dart） 駐車場一覧の取得例外: $e");
      debugPrint("$stack");
      return [];
    }
  }

}

