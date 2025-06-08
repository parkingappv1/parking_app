import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:parking_app/core/api/user/use_history_api.dart';
import 'package:parking_app/core/services/use_history_service.dart';
import 'package:parking_app/main.dart';
import 'package:parking_app/views/user/history_detail_screen.dart';
import 'package:parking_app/views/user/user_home_screen.dart';

class HistoryScreen extends StatefulWidget {
  final String user_id;

  const HistoryScreen({super.key, required this.user_id});

  @override
  createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // データ初期化
  int _currentIndex = 2;
  late final UseHistoryService _useHistoryService;
  bool _isLoading = true;
  late List<dynamic> _userHistories = [];

  @override
  void initState() {
    super.initState();
    _useHistoryService = UseHistoryService(UseHistoryApi());
    _getUseHistories(widget.user_id);
  }

  // 駐車場利用履歴の取得
  Future<void> _getUseHistories(String? user_id) async {
    try {
      var useHistories = await _useHistoryService.getUseHistories(user_id);
      setState(() {
        _userHistories = useHistories.data!;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error getSearchHistories: $e');
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
        title: Text(AppLocalizations.of(context).appTitle),
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
              // 利用履歴
              _buildSearchHistoryList(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildSearchHistoryList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).historys,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white),
            borderRadius: BorderRadius.circular(8),
          ),
          // 各アイテムの間にスペースなどを挟みたい場合
          child: _buildHistoryItems(),
        ),
      ],
    );
  }

  Widget _buildHistoryItems() {
    return _userHistories.isEmpty
        ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 24),
            Text(
              AppLocalizations.of(context).noUseHistory,
              style: TextStyle(color: Colors.red[600]),
            ),
          ],
        )
        : ListView.separated(
          shrinkWrap: true,
          itemCount: _userHistories.length,
          itemBuilder: (context, index) {
            return _buildHistoryItem(
              _userHistories[index]['reservation_id'],
              _userHistories[index]['area'],
              _userHistories[index]['parking_lot_name'],
              _userHistories[index]['start_datetime'],
              _userHistories[index]['end_datetime'],
              _userHistories[index]['amount'],
            );
          }, //
          separatorBuilder: (context, index) {
            return Divider();
          },
        );
  }

  Widget _buildHistoryItem(
    String reservation_id,
    String area,
    String parkinglotname,
    String startdatetime,
    String enddatetime,
    String amount,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.history, color: Colors.blue),
      title: Text(area),
      subtitle: Text('$parkinglotname\n$startdatetime～$enddatetime'),
      trailing: Text(
        NumberFormat.simpleCurrency(
              locale: Localizations.localeOf(context).toString(),
            ).currencySymbol +
            amount,
        style: TextStyle(color: Colors.red),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => HistoryDetailScreen(
                  user_id: widget.user_id,
                  reservation_id: reservation_id,
                ),
          ),
        );
      },
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
          label: AppLocalizations.of(context).home,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: AppLocalizations.of(context).search,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: AppLocalizations.of(context).history,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: AppLocalizations.of(context).account,
        ),
      ],
    );
  }
}
