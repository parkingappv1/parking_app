import 'dart:io';

import 'package:flutter/material.dart';
import 'package:parking_app/core/api/api_response.dart';
import 'package:parking_app/core/api/owner/upload_image_api.dart';

typedef ProgressCallback = void Function(int sent, int total);

class UploadImageService extends ChangeNotifier {
  final UploadImageApi _api;

  UploadImageService(this._api);

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  // /// 単一画像アップロード（進捗コールバックあり）
  // Future<ApiResponse<void>> uploadSingleImage(
  //   String parkingLotId,
  //   File image, {
  //   ProgressCallback? onProgress,
  // }) async {
  //   try {
  //     debugPrint('（parking_lot_service.dart） 画像アップロード開始: ${image.path}');

  //     final response = await _api.uploadImages(
  //       parkingLotId,
  //       image,
  //       // onProgress: onProgress,
  //     );

  //     debugPrint('🟢 （parking_lot_service.dart）単一画像アップロードレスポンス: $response');
  //     return response;
  //   } catch (e, stack) {
  //     debugPrint('💥 （parking_lot_service.dart）単一画像アップロード例外: $e');
  //     debugPrint('$stack');
  //     return ApiResponse.error('画像アップロード中に予期しないエラーが発生しました');
  //   }
  // }

  /// 複数画像アップロード（進捗は画像のインデックス付きでコールバック）
  Future<ApiResponse<void>> uploadMultipleImages(
    String parkingLotId,
    List<File> images, 
    // {
    //   required void Function(int index, int sent, int total) onProgress,
    // }
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (images.isEmpty) {
        debugPrint('⚠️ アップロード画像がありません');
        _isLoading = false;
        notifyListeners();
        return ApiResponse.error('アップロード画像がありません');
      }

      final response = await _api.uploadImages(
        parkingLotId,
        images,
        // onProgress: onProgress,
      );
      return response;
    } catch (e, stack) {
      debugPrint('💥 複数画像アップロード例外: $e');
      debugPrint('$stack');
      return ApiResponse.error('複数画像アップロード中にエラーが発生しました');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
