import 'dart:io';

import 'package:dio/dio.dart';
import 'package:parking_app/core/api/api_constants.dart';
import 'package:parking_app/core/api/api_response.dart';
import 'package:parking_app/core/client/dio_client.dart';
/// 駐車場登録API - DioClientを使用したAPIラッパー
class UploadImageApi {
  final DioClient _client;

  /// デフォルトコンストラクタ
  UploadImageApi() : _client = DioClient();

  /// 依存性注入用のネームドコンストラクタ
  UploadImageApi.withClient(DioClient client) : _client = client;


  Future<ApiResponse> uploadImages(
    String parkingLotId,
    List<File> imageFiles
    // {
    //   ProgressCallback? onProgress,
    // }
  ) async {

    final formData = FormData.fromMap({
      'parking_lot_id': parkingLotId, // 👈 作为字段传给后端
      'images': await Future.wait(
        imageFiles.map((file) async {
          final fileName = file.path.split('/').last;
          return await MultipartFile.fromFile(file.path, filename: fileName);
        }),
      ),
    });


    // final response = await dio.post(
    //   'http://localhost:3000/v1/api/parking_lots/$parkingLotId/images/upload',
    //   data: formData,
    //   onSendProgress: onProgress,
    // );

    final response = await _client.post(
      ApiConstants.UPLOAD_PARKING_LOT_IMAGES,
      data: formData,
    );

    // 这里可根据后端返回做更详细判断
    if (response.statusCode == 200) {
      return ApiResponse.success(null, message: '画像アップロード成功');
    } else {
      return ApiResponse.error('画像アップロード失敗');
    }
  }
}


