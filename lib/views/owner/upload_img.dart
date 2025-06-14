import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:parking_app/core/api/owner/upload_image_api.dart';
import 'package:parking_app/core/services/upload_image_service.dart';
import 'package:parking_app/views/common/widgets/header.dart';

class ParkingLotImageUploader extends StatefulWidget {
  final String parkingLotId;

  const ParkingLotImageUploader({
    super.key,
    required this.parkingLotId,
  });

  @override
  State<ParkingLotImageUploader> createState() => _ParkingLotImageUploaderState();
}

class _ParkingLotImageUploaderState extends State<ParkingLotImageUploader> {
  final TextEditingController featuresTipController = TextEditingController();
  final List<File> _selectedImages = [];
  final Map<File, double> _uploadProgress = {}; // 每张图上传进度
  bool _isUploading = false;
  late final UploadImageService _uploadImageService;

  @override
  void initState() {
    super.initState();

        // Initialize service with simplified constructor
    final UploadImageApi _api = UploadImageApi();
    _uploadImageService = UploadImageService(_api);
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (pickedFiles.isNotEmpty) {
      setState(() {
        final newFiles = pickedFiles.map((file) => File(file.path)).toList();
        _selectedImages.addAll(newFiles);
        if (_selectedImages.length > 5) {
          _selectedImages.removeRange(5, _selectedImages.length);
        }
      });
    }
  }

  Future<void> _uploadImages(String parkingLotId) async {
    if (_selectedImages.isEmpty) return;

    setState(() => _isUploading = true);

    try {
      final response = await _uploadImageService.uploadMultipleImages(parkingLotId, _selectedImages);

      if (response.isSuccess) {
        debugPrint('✅ 画像アップロード成功');
        // 可以显示提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('画像アップロード成功')),
        );
        // 延迟关闭当前页面和上一级页面
        Future.delayed(Duration(seconds: 1), () {
          // 先pop当前页面
          Navigator.of(context).pop();
          // 再pop上一页面
          Navigator.of(context).pop();
        });
      } else {
        debugPrint('❌ 画像アップロード失敗: ${response.message}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('画像アップロード失敗: ${response.message}')),
        );
      }
    } catch (e) {
      debugPrint('💥 アップロード中にエラー: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('画像アップロード中にエラーが発生しました')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }


  void _removeImage(File image) {
    setState(() {
      _selectedImages.remove(image);
      _uploadProgress.remove(image);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonHeader(barText: '駐車場画像アップロード'),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageUploadSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return _buildFormSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('駐車場写真'),
          const Text('駐車場の外観写真（必須）', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 16),

          Stack(
            children: [
              Container(
                height: 180,
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[100],
                ),
                child: _selectedImages.isNotEmpty
                    ? SingleChildScrollView(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _selectedImages.map((image) {
                            final progress = _uploadProgress[image] ?? 0.0;
                            return Stack(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Image.file(image, fit: BoxFit.cover),
                                      ),
                                      if (_isUploading)
                                        Positioned.fill(
                                          child: Container(
                                            color: Colors.black26,
                                            child: Align(
                                              alignment: Alignment.bottomCenter,
                                              child: LinearProgressIndicator(
                                                value: progress,
                                                minHeight: 5,
                                                backgroundColor: Colors.white30,
                                                color: Colors.blue,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (!_isUploading)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: GestureDetector(
                                      onTap: () => _removeImage(image),
                                      child: const CircleAvatar(
                                        radius: 10,
                                        backgroundColor: Colors.red,
                                        child: Icon(Icons.close, size: 14, color: Colors.white),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          }).toList(),
                        ),
                      )
                    : const Center(
                        child: Text(
                          '写真を追加してください（最大5枚）',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: SizedBox(
                  height: 36,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      minimumSize: const Size(120, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                    onPressed: _selectedImages.length >= 5 || _isUploading ? null : _pickImages,
                    icon: const Icon(Icons.add_a_photo, size: 18),
                    label: const Text('写真を追加'),
                  ),
                ),
              ),
            ],
          ),

          Text(
            '最大5枚までアップロード可能',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),

          const SizedBox(height: 24),

          TextFormField(
            controller:featuresTipController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: '備考・その他',
              hintText: '例：入口が分かりにくいため、看板を設置しています。',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: () {
              _uploadImages(widget.parkingLotId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 12),
              minimumSize: const Size.fromHeight(40),
            ),
            child: const Text('アップロード実行', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
      child: child,
    );
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.w600,
          color: Color(0xFF333333),
        ),
      ),
    );
  }
}
