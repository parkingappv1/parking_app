import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:parking_app/core/api/user/use_history_api.dart';
import 'package:parking_app/core/models/parking_lot_model.dart';
import 'package:parking_app/core/models/use_history_model.dart';
import 'package:parking_app/core/services/use_history_service.dart';
import 'package:parking_app/main.dart';
import 'package:parking_app/views/user/history_screen.dart';
import 'package:parking_app/views/user/user_home_screen.dart';
import 'package:provider/provider.dart';

class HistoryDetailScreen extends StatefulWidget {
  final String user_id;
  final String reservation_id;

  const HistoryDetailScreen({
    super.key,
    required this.user_id,
    required this.reservation_id,
  });

  @override
  createState() => _HistoryDetailScreenStatus();
}

class _HistoryDetailScreenStatus extends State<HistoryDetailScreen> {
  // データ初期化
  int _currentIndex = 2;
  late final UseHistoryService _useHistoryService;
  bool _isLoading = true;
  UseHistoryDetailModel? _useHistoryDetailModel;
  late List<dynamic> _parkingFeatures = [];
  ParkingLotModel? _parkingLotModel;

  @override
  void initState() {
    super.initState();
    _useHistoryService = UseHistoryService(UseHistoryApi());
    _getUseHistoryDetail(widget.reservation_id);
  }

  // 駐車場利用履歴詳細
  Future<void> _getUseHistoryDetail(String? reservation_id) async {
    try {
      final useHistoryService = Provider.of<UseHistoryService>(
        context,
        listen: false,
      );
      final useHistoryDetailModel = await useHistoryService.getUseHistoryDetail(
        reservation_id,
      );
      setState(() {
        _useHistoryDetailModel = useHistoryDetailModel.data;
        if (_useHistoryDetailModel != null) {
          _getParkingFeatures(_useHistoryDetailModel?.parking_lot_id);
          _getParkingLots(_useHistoryDetailModel?.parking_lot_id);
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error getUseHistoryDetail: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 駐車場特徴の取得
  Future<void> _getParkingFeatures(String? parking_lot_id) async {
    try {
      var parkingFeatures = await _useHistoryService.getParkingFeatures(
        parking_lot_id,
      );
      setState(() {
        _parkingFeatures = parkingFeatures.data!;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error _getParkingFeatures: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 駐車場基本情報の取得
  Future<void> _getParkingLots(String? parking_lot_id) async {
    try {
      var parkingLotMoel = await _useHistoryService.getParkingLots(
        parking_lot_id,
      );
      setState(() {
        _parkingLotModel = parkingLotMoel.data!;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error _getParkingLots: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.appTitle),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [LanguageSwitcher()],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 駐車場の特徴
              _buildFeaturesList(),
              SizedBox(height: 24),
              //
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildFeaturesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.features,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white),
            borderRadius: BorderRadius.circular(8),
          ),
          // 各アイテムの間にスペースなどを挟みたい場合
          child: _buildFeatureItems(),
        ),
      ],
    );
  }

  Widget _buildFeatureItems() {
    return _parkingFeatures.isEmpty
        ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 24),
            Text(
              AppLocalizations.of(context).nofeatures,
              style: TextStyle(color: Colors.red[600]),
            ),
          ],
        )
        : ListView.separated(
          shrinkWrap: true,
          itemCount: _parkingFeatures.length,
          itemBuilder: (context, index) {
            return _buildFeatureItem(
              _parkingFeatures[index]['feature_type'],
              _parkingFeatures[index]['feature_value'],
            );
          }, //
          separatorBuilder: (context, index) {
            return Divider();
          },
        );
  }

  Widget _buildFeatureItem(String type, String value) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.check, color: Colors.green, size: 30),
      title: Text(''),
      subtitle: Text('$type:$value'),
      trailing: Text(''),
      onTap: null,
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });

        switch (index) {
          case 0:
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserHomeScreen(user_id: widget.user_id),
              ),
            );
          case 1:
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HistoryScreen(user_id: widget.user_id),
              ),
            );
          case 2:
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HistoryScreen(user_id: widget.user_id),
              ),
            );
          default:
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HistoryScreen(user_id: widget.user_id),
              ),
            );
        }
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: AppLocalizations.of(context)!.home,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: AppLocalizations.of(context)!.search,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: AppLocalizations.of(context)!.history,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: AppLocalizations.of(context)!.account,
        ),
      ],
    );
  }
}
