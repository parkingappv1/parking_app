import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:parking_app/core/api/owner/parking_lot_api.dart';
import 'package:parking_app/core/models/parking_lots_model.dart';
import 'package:parking_app/core/services/parking_lot_service.dart';
import 'package:parking_app/core/utils/dialog_helper.dart';
import 'package:parking_app/core/utils/validators.dart';
import 'package:parking_app/views/common/widgets/header.dart';
import 'package:parking_app/views/common/widgets/input_fields2.dart';
import 'package:parking_app/views/common/widgets/location_section.dart';
import 'package:parking_app/views/owner/upload_img.dart';

class AddParkingSpaceScreenScreen extends StatefulWidget {
  final String ownerId;

  const AddParkingSpaceScreenScreen({
    super.key,
    required this.ownerId,
  });

  @override
  State<AddParkingSpaceScreenScreen> createState() => _AddParkingSpaceScreenScreenState();
}

class _AddParkingSpaceScreenScreenState extends State<AddParkingSpaceScreenScreen> {
  final formKey = GlobalKey<FormState>();
  final _postalCodeFocus = FocusNode();

    // Service instances - created directly instead of using Provider
  late final ParkingLotService _parkingLotService;

  //基本信息
  final TextEditingController parkingLotNameController = TextEditingController();
  final TextEditingController postalCodeController = TextEditingController();
  final TextEditingController prefectureController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController addressDetailController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();

  //収容信息
  final TextEditingController capacityController = TextEditingController();
  final TextEditingController availableCapacityController = TextEditingController();

  //貸出信息
  String _rentalType = 'hourly';

  //料金信息
  final TextEditingController chargeController = TextEditingController();
  // final TextEditingController featuresTipController = TextEditingController();
  
  // サイズ制限
  final TextEditingController lengthLimitController = TextEditingController();
  final TextEditingController widthLimitController = TextEditingController();
  final TextEditingController heightLimitController = TextEditingController();
  final TextEditingController weightLimitController = TextEditingController();
  // 下拉选择的值
  String carHeightLimit = 'none';
  String tireWidthLimit = 'none';
  String carBottomLimit = 'none';
  // 下拉选项
  final List<DropdownMenuItem<String>> carHeightLimitOptions = [
    DropdownMenuItem(value: 'none', child: Text('制限なし')),
    DropdownMenuItem(value: '150', child: Text('150cm以下')),
    DropdownMenuItem(value: '180', child: Text('180cm以下')),
    DropdownMenuItem(value: '200', child: Text('200cm以下')),
  ];
  final List<DropdownMenuItem<String>> tireWidthLimitOptions = [
    DropdownMenuItem(value: 'none', child: Text('制限なし')),
    DropdownMenuItem(value: '185', child: Text('185mm以下')),
    DropdownMenuItem(value: '195', child: Text('195mm以下')),
    DropdownMenuItem(value: '215', child: Text('215mm以下')),
  ];
  final List<DropdownMenuItem<String>> carBottomLimitOptions = [
    DropdownMenuItem(value: 'none', child: Text('制限なし')),
    DropdownMenuItem(value: '10', child: Text('10cm以上')),
    DropdownMenuItem(value: '15', child: Text('15cm以上')),
    DropdownMenuItem(value: '20', child: Text('20cm以上')),
  ];

  // 车型选中状态
  final Map<String, bool> _vehicleTypes = {
    'オートバイ': false,
    '軽自動車': false,
    'コンパクトカー': false,
    '中型車': false,
    'ワンボックス': false,
    '大型車・SUV': false,
  };

  // 车型对应的 TextEditingController
  final Map<String, TextEditingController> _capacityControllers = {};
  // 车型对应的 FocusNode
  final Map<String, FocusNode> _capacityFocusNodes = {};


  double? selectedLat;
  double? selectedLon;
  String _nearestStation = 'まだ取得していません';
  // 
  @override
  void initState() {
    super.initState();

        // Initialize service with simplified constructor
    final ParkingLotApi api = ParkingLotApi();
    _parkingLotService = ParkingLotService(api);

    for (var key in _vehicleTypes.keys) {
      _capacityControllers[key] = TextEditingController();
      _capacityFocusNodes[key] = FocusNode();
    }
  }
  // 定位 最近車站
  final TextEditingController nearestStationController = TextEditingController();

  @override
  void dispose() {
    _postalCodeFocus.dispose();
    parkingLotNameController.dispose();
    postalCodeController.dispose();
    prefectureController.dispose();
    cityController.dispose();
    addressDetailController.dispose();
    phoneNumberController.dispose();
    capacityController.dispose();
    availableCapacityController.dispose();
    chargeController.dispose();
    lengthLimitController.dispose();
    widthLimitController.dispose();
    heightLimitController.dispose();
    weightLimitController.dispose();
    nearestStationController.dispose();

    for (var controller in _capacityControllers.values) {
      controller.dispose();
    }
    for (var node in _capacityFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonHeader(barText: '駐車場新規追加'),

      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 基本信息
                _buildBasicInfoSection(),
                const SizedBox(height: 24),
                
                // 駐車場の位置
                // LocationSection(),
                LocationSection(
                  onLocationChanged: (lat, lon) {
                    setState(() {
                      selectedLat = lat;
                      selectedLon = lon;
                    });
                  },
                  onNearestStationChanged: (String newStation) {
                    setState(() {
                      _nearestStation = newStation;
                    });
                  },
                ),

                const SizedBox(height: 24),

                // 収容信息
                // _buildCapacityInputSection(),
                _buildCapacityVehicleTypesSection(),
                const SizedBox(height: 24),

                // 貸出情報
                _buildRentalTypeSection(),
                const SizedBox(height: 24),

                //料金
                _buildPriceInputSection(),
                const SizedBox(height: 24),

                // サイズ制限
                _buildSizeRestrictionsSection(),
                const SizedBox(height: 24),

                Center(
                  child: ElevatedButton(
                    onPressed: () async {

                      // 关闭键盘
                      FocusScope.of(context).unfocus();
                      final errors = <String, String?>{};
                      final postalCodeError = postalCodeValidator(postalCodeController.text);
                      if (postalCodeError != null) errors['postalCode'] = postalCodeError;

                      if (errors.isNotEmpty) {
                        final firstError = errors.entries.first;
                        if (firstError.key == 'postalCode') {
                          _postalCodeFocus.requestFocus();
                        }
                        await DialogHelper.showErrorDialog(
                          context,
                          '入力エラー',
                          firstError.value ?? '入力に誤りがあります。',
                        );
                        return;

                        // 如果有其他字段，继续类似处理...
                      } else {

                        // 验证通过，执行提交逻辑
                        final snapshot = DateTime.now();
                        // 1. 先从表单收集“车型 + 容量”数据，只收集已勾选且容量填写有效的项
                          List<ParkingVehicleTypeModel> vehicleTypes = [];
                          _vehicleTypes.forEach((vehicleType, isChecked) {
                            if (isChecked) {
                              final text = _capacityControllers[vehicleType]?.text ?? '';
                              final capacity = int.tryParse(text) ?? 0;
                              if (capacity > 0) {
                                vehicleTypes.add(ParkingVehicleTypeModel(
                                  vehicleType: vehicleType,
                                  capacity: capacity,
                                ));
                              }
                            }
                          });

                          final totalCapacity = vehicleTypes.fold<int>(0, (sum, v) => sum + v.capacity);

                          //  构造ParkingLotModel实例（这里写固定数据示例）
                          final parkingLot = ParkingLotsModel(
                            ownerId: widget.ownerId, // 你可以从用户登录态或者输入获取
                            parkingLotName: parkingLotNameController.text,  // 从输入框取值
                            postalCode: postalCodeController.text,
                            prefecture: prefectureController.text,
                            city: cityController.text,
                            addressDetail: addressDetailController.text,
                            latitude: selectedLat?.toStringAsFixed(6) ?? '',
                            longitude: selectedLon?.toStringAsFixed(6) ?? '', 
                            phoneNumber: phoneNumberController.text,
                            capacity: totalCapacity,
                            availableCapacity: totalCapacity,
                            rentalType: _rentalType,
                            charge: chargeController.text,
                            featuresTip: "屋根付き",
                            nearestStation: _nearestStation,
                            status: 'active',
                            startDate: DateTime(snapshot.year, snapshot.month, snapshot.day),

                            // ✅ 添加 limits（限制信息）
                            limits: ParkingLimitModel(
                              lengthLimit: int.tryParse(lengthLimitController.text) ?? 0,
                              widthLimit: int.tryParse(widthLimitController.text) ?? 0,
                              heightLimit: int.tryParse(heightLimitController.text) ?? 0,
                              weightLimit: int.tryParse(weightLimitController.text) ?? 0,
                              carHeightLimit: carHeightLimit,
                              tireWidthLimit: tireWidthLimit,
                              carBottomLimit: carBottomLimit,
                            ),

                            vehicleTypes: vehicleTypes,

                            // ✅ 可选字段（建议为 null 或不传）
                            endDate: null,
                            endStartDatetime: null,
                            endEndDatetime: null,
                            endReason: null,
                            endReasonDetail: null,
                            notes: null,
                          );

                        final response = await _parkingLotService.registerParkingLot(parkingLot);
                        // print('⭕️ （add_pakking_lot_screen.dart）注册接口返回:'+ response.toString());
                        if (!mounted) return;
                        if (response.isSuccess) {
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('停车场注册成功！')),
                          );
                          
                          await Future.delayed(const Duration(seconds: 1));// 等待提示显示
                          if (!mounted) return;
                          // 跳转到上传图片页面，并传递必要信息（如 parkingLotId）
                          Navigator.push(
                            // ignore: use_build_context_synchronously
                            context,
                            MaterialPageRoute(
                              builder: (context) => ParkingLotImageUploader(
                                parkingLotId: response.data!.parkingLotId, // 假设返回里有 id
                              ),
                            ),
                          );
                        } else {
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('注册失败，请重试')),
                          );
                            // ignore: use_build_context_synchronously
                            Navigator.pop(context, false);// 返回上一页  
                        }
                      }
                    },
                    child: Text('登録'),  
                  )

                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildCapacityVehicleTypesSection() {
    return _buildFormSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('収容台数・対応車種'),
          const SizedBox(height: 8),
          ..._vehicleTypes.entries.map((entry) {
                    final vehicleType = entry.key;
                    final isChecked = entry.value;
                    final controller = _capacityControllers[vehicleType]!;
                    final focusNode = _capacityFocusNodes[vehicleType] ?? FocusNode();


            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Checkbox(
                    value: isChecked,
                    onChanged: (bool? val) {
                      setState(() {
                        _vehicleTypes[vehicleType] = val ?? false;
                        if (!val!) {
                          controller.clear();
                        }
                      });
                    },
                  ),
                  Expanded(
                    child: Text(
                      vehicleType,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: AppTextField2(
                      controller: controller,
                      focusNode: focusNode,
                      label: '',
                      hintText: '台数',
                      keyboardType: TextInputType.number,
                      readOnly: !isChecked,
                      validator: isChecked
                          ? (value) {
                              if (value == null || value.trim().isEmpty) {
                                return '$vehicleType の台数を入力してください';
                              }
                              if (int.tryParse(value.trim()) == null) {
                                return '数字を入力してください';
                              }
                              if (int.parse(value.trim()) > 50) {
                                return '最大50台まで設定可能です';
                              }
                              return null;
                            }
                          : null,
                    )
                  ),
                  const SizedBox(width: 4),
                  const Text('台'),
                ],
              ),
            );
          }),
          const SizedBox(height: 6),
          const Text(
            '最大50台まで設定可能です',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSizeRestrictionsSection() {
    return _buildFormSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'サイズ制限',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildTableRow(
            label: '長さ制限',
            inputWidget: _buildNumberInput(lengthLimitController, 'cm'),
          ),
          _buildTableRow(
            label: '幅制限',
            inputWidget: _buildNumberInput(widthLimitController, 'cm'),
          ),
          _buildTableRow(
            label: '高さ制限',
            inputWidget: _buildNumberInput(heightLimitController, 'cm'),
          ),
          _buildTableRow(
            label: '重量制限',
            inputWidget: _buildNumberInput(weightLimitController, 'kg'),
          ),
          _buildTableRow(
            label: '車高制限',
            inputWidget: _buildDropdown(carHeightLimit, carHeightLimitOptions, (val) {
              if (val != null) setState(() => carHeightLimit = val);
            }),
          ),
          _buildTableRow(
            label: 'タイヤ幅制限',
            inputWidget: _buildDropdown(tireWidthLimit, tireWidthLimitOptions, (val) {
              if (val != null) setState(() => tireWidthLimit = val);
            }),
          ),
          _buildTableRow(
            label: '車下制限',
            inputWidget: _buildDropdown(carBottomLimit, carBottomLimitOptions, (val) {
              if (val != null) setState(() => carBottomLimit = val);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberInput(TextEditingController controller, String unit) {
    return SizedBox(
      width: 100,
      height: 40,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.blue.shade400),
                ),
              ),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            unit,
            style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String value, List<DropdownMenuItem<String>> items, ValueChanged<String?> onChanged) {
    return SizedBox(
      width: 150,
      height: 40,
      child: DropdownButtonFormField<String>(
        value: value,
        items: items,
        onChanged: onChanged,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.blue.shade400),
          ),
        ),
      ),
    );
  }

  Widget _buildTableRow({
    required String label,
    required Widget inputWidget,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: Color(0xFF555555)),
            ),
          ),
          Expanded(
            flex: 6,
            child: Align(
              alignment: Alignment.centerRight,
              child: inputWidget,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceInputSection() {
    return _buildFormSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('料金設定'),
          _buildRequiredLabel('時間あたりの料金'),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                '¥',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF333333),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: chargeController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 16),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    // ThousandsSeparatorInputFormatter(),
                  ],
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
              ),
              const Text(
                '/時間',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 貸出タイプ选择部分
  Widget _buildRentalTypeSection() {
    return _buildFormSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('貸出タイプ'),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildRadioOption('hourly', '時間単位'),
              const SizedBox(width: 20),
              _buildRadioOption('monthly', '月極'),
            ],
          ),
        ],
      ),
    );
  }

  // 单选按钮构建
  Widget _buildRadioOption(String value, String label) {
    final bool selected = _rentalType == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _rentalType = value;
        });
      },
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? Colors.blue : Colors.grey,
                width: 2,
              ),
              color: selected ? Colors.blue : Colors.transparent,
            ),
            child: selected
                ? const Center(
                    child: Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 16)),
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

  Widget _buildBasicInfoSection() {
    return _buildFormSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('基本情報'),
          _buildRequiredLabel('駐車場名'),
          AppTextField2(
            label: '',
            hintText: '例：東京駅前駐車場',
            controller: parkingLotNameController,
            validator: (value) => Validators.validateRequired(context, value),
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: 16),

          _buildRequiredLabel('郵便番号'),
          _buildPostalCodeRow(),
          const SizedBox(height: 16),

          _buildRequiredLabel('都道府県'),
          AppTextField2(
            label: '',
            hintText: '例：東京都',
            controller: prefectureController,
            validator: (value) => Validators.validateRequired(context, value),
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: 16),

          _buildRequiredLabel('市区町村'),
          AppTextField2(
            label: '',
            hintText: '例：千代田区',
            controller: cityController,
            validator: (value) => Validators.validateRequired(context, value),
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: 16),

          _buildRequiredLabel('番地・建物名'),
          AppTextField2(
            label: '',
            hintText: '例：丸の内1-1-1 東京ビル1F',
            controller: addressDetailController,
            validator: (value) => Validators.validateRequired(context, value),
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: 16),

          // const Text('電話番号（任意）', style: TextStyle(fontSize: 16)),
          _buildRequiredLabel('電話番号'),
          AppTextField2(
            label: '',
            hintText: '例：090-1234-5678',
            controller: phoneNumberController,
            keyboardType: TextInputType.text,
          ),
        ],
      ),
    );
  }
  void _handleSearchAddress() async {
    final zip = postalCodeController.text.replaceAll('-', '');
    final url = Uri.parse('https://zipcloud.ibsnet.co.jp/api/search?zipcode=$zip');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['results'] != null && data['results'].isNotEmpty) {
        final result = data['results'][0];
        setState(() {
          prefectureController.text = result['address1'];
          cityController.text = '${result['address2']}${result['address3']}';
        });
      } else {
        _showAlert('住所が見つかりませんでした。');
      }
    } else {
      _showAlert('住所検索に失敗しました。');
    }
  }

  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }
  
  // 示例自定义验证函数
  String? postalCodeValidator(String? value) {
    if (value == null || value.isEmpty) return '郵便番号を入力してください';
    final regex = RegExp(r'^\d{3}-\d{4}$');
    if (!regex.hasMatch(value)) return '正しい形式で入力してください（例: 114-0001）';
    return null;
  }

  Widget _buildPostalCodeRow() {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: AppTextField2(
            label: '',
            hintText: '例：114-0001',
            controller: postalCodeController,
            keyboardType: TextInputType.number,
            focusNode: _postalCodeFocus,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 5,
          child: ElevatedButton(
            onPressed: _handleSearchAddress,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3366CC),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              '住所を検索',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
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

  Widget _buildRequiredLabel(String text) {
    return RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFF555555),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        children: const [
          TextSpan(
            text: ' *',
            style: TextStyle(
              color: Color(0xFFFF3B30),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

}
