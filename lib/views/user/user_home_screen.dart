import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:parking_app/core/api/user/user_home_api.dart';
import 'package:parking_app/core/models/parking_status_model.dart';
import 'package:parking_app/core/services/user_home_service.dart';
import 'package:parking_app/main.dart';
import 'package:parking_app/views/user/history_screen.dart';

class UserHomeScreen extends StatefulWidget {
  final String user_id;

  const UserHomeScreen({super.key, required this.user_id});

  @override
  createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  // データ初期化
  int _currentIndex = 0;
  late final UserHomeService _homeService;
  bool _isLoading = true;
  ParkingStatusModel? _parkingStatusModel;
  late List<dynamic> _favorites = [];
  late List<dynamic> _searchHistories = [];

  @override
  void initState() {
    super.initState();
    _homeService = UserHomeService(UserHomeApi());
    _getParkingStatus(widget.user_id, '2');
    _getSearchHistories(widget.user_id);
    _getFavorites(widget.user_id);
  }

  // 入出庫状況の取得
  Future<void> _getParkingStatus(String? user_id, String? status) async {
    try {
      final parkingStatusModel = await _homeService.getParkingStatus(
        user_id,
        status,
      );
      setState(() {
        _parkingStatusModel = parkingStatusModel.data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error getParkingStatus: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 入出庫状況の更新
  Future<void> _updateParkingStatus(
    String statusid,
    String reservationid,
    String checkInOutKbn,
  ) async {
    try {
      await _homeService.updateParkingStatus(
        statusid,
        reservationid,
        checkInOutKbn,
      );
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error updateParkingStatus: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 駐車場検索履歴の取得
  Future<void> _getSearchHistories(String? user_id) async {
    try {
      var searchHistories = await _homeService.getSearchHistories(user_id);
      setState(() {
        _searchHistories = searchHistories.data!;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error getSearchHistories: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // お気に入りの取得
  Future<void> _getFavorites(String? user_id) async {
    try {
      var favorites = await _homeService.getFavorites(user_id);
      setState(() {
        _favorites = favorites.data!;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error getFavorites: $e');
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
              // 入出庫状況
              _buildCurrentParkingCard(),
              SizedBox(height: 24),
              // 最近の検索履歴
              _buildSearchHistoryList(),
              SizedBox(height: 24),
              // お気に入り
              _buildFavoriteParkingList(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildCurrentParkingCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
        side: BorderSide(color: Colors.blue, width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).parkingStatus,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            if (_parkingStatusModel == null)
              Text(
                AppLocalizations.of(context).noReservation,
                style: TextStyle(color: Colors.red[600]),
              ),
            if (_parkingStatusModel != null)
              Text(
                _parkingStatusModel!.parking_lot_name,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            if (_parkingStatusModel != null)
              Text(
                '${AppLocalizations.of(context).reservationStart}${_parkingStatusModel!.start_datetime}',
                style: TextStyle(color: Colors.red[600]),
              ),
            if (_parkingStatusModel != null)
              Text('～', style: TextStyle(color: Colors.grey[600])),
            if (_parkingStatusModel != null)
              Text(
                '${AppLocalizations.of(context).reservationEnd}${_parkingStatusModel!.end_datetime}',
                style: TextStyle(color: Colors.red[600]),
              ),
            SizedBox(height: 8),
            if (_parkingStatusModel != null)
              Text(
                '${AppLocalizations.of(context).entryDate}${_parkingStatusModel!.entry_datetime}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            if (_parkingStatusModel != null)
              Text('～', style: TextStyle(color: Colors.grey[600])),
            if (_parkingStatusModel?.exit_datetime != null)
              Text(
                '${AppLocalizations.of(context).exitDate}${_parkingStatusModel!.exit_datetime}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (_parkingStatusModel != null)
                  _buildStatusButton(
                    _parkingStatusModel!.status_id,
                    _parkingStatusModel!.reservation_id,
                    _parkingStatusModel!.entry_status,
                    '1',
                    AppLocalizations.of(context).checkIn,
                    Icons.input,
                    Colors.green,
                  ),
                if (_parkingStatusModel != null)
                  _buildStatusButton(
                    _parkingStatusModel!.status_id,
                    _parkingStatusModel!.reservation_id,
                    _parkingStatusModel!.exit_status,
                    '2',
                    AppLocalizations.of(context).checkOut,
                    Icons.output,
                    Colors.blue,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHistoryList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).recentSearches,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white),
            borderRadius: BorderRadius.circular(8),
          ),
          // 各アイテムの間にスペースなどを挟みたい場合
          child: _buildSearchHistoryItems(),
        ),
      ],
    );
  }

  Widget _buildFavoriteParkingList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).favorites,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white),
            borderRadius: BorderRadius.circular(8),
          ),
          // 各アイテムの間にスペースなどを挟みたい場合
          child: _buildFavoriteItems(),
        ),
      ],
    );
  }

  Widget _buildStatusButton(
    String statusid,
    String reservationid,
    String status,
    String checkInOutKbn,
    String text,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: checkInOutKbn == '1' ? Colors.blue : Colors.orange,
            shape: BoxShape.rectangle,
          ),
          child: IconButton(
            icon: Icon(icon),
            color: color,
            iconSize: 40.0,
            onPressed:
                status == '1'
                    ? null
                    : () async {
                      final bool confirm =
                          await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text(
                                  checkInOutKbn == '1'
                                      ? AppLocalizations.of(
                                        context,
                                      ).checkInConfirmTitle
                                      : AppLocalizations.of(
                                        context,
                                      ).checkOutConfirmTitle,
                                ),
                                content: Text(
                                  checkInOutKbn == '1'
                                      ? AppLocalizations.of(
                                        context,
                                      ).checkInConfirmMessage
                                      : AppLocalizations.of(
                                        context,
                                      ).checkOutConfirmMessage,
                                ),
                                actions: [
                                  TextButton(
                                    child: Text(
                                      AppLocalizations.of(context).cancel,
                                    ),
                                    onPressed:
                                        () => Navigator.of(context).pop(false),
                                  ),
                                  TextButton(
                                    child: Text(
                                      AppLocalizations.of(context).confirm,
                                    ),
                                    onPressed:
                                        () => Navigator.of(context).pop(true),
                                  ),
                                ],
                              );
                            },
                          ) ??
                          false;

                      if (confirm) {
                        _updateParkingStatus(
                          statusid,
                          reservationid,
                          checkInOutKbn,
                        );
                        _getParkingStatus(widget.user_id, '2');
                        _getSearchHistories(widget.user_id);
                        _getFavorites(widget.user_id);
                      }
                    },
            tooltip: text,
          ),
        ),
        SizedBox(height: 8),
        Text(text),
      ],
    );
  }

  Widget _buildSearchHistoryItems() {
    return _searchHistories.isEmpty
        ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 24),
            Text(
              AppLocalizations.of(context).noSearchHistory,
              style: TextStyle(color: Colors.red[600]),
            ),
          ],
        )
        : ListView.separated(
          shrinkWrap: true,
          itemCount: _searchHistories.length,
          itemBuilder: (context, index) {
            return _buildSearchHistoryItem(
              _searchHistories[index]['search_id'],
              _searchHistories[index]['parking_lot_name'],
              _searchHistories[index]['condition_keyword_free'],
              _searchHistories[index]['condition_use_date_start'],
              _searchHistories[index]['condition_use_date_end'],
              _searchHistories[index]['vehicle_type'],
              _searchHistories[index]['rental_value'],
            );
          }, //
          separatorBuilder: (context, index) {
            return Divider();
          },
        );
  }

  Widget _buildSearchHistoryItem(
    String searchid,
    String parkinglotname,
    String conditionkeywordfree,
    String conditionusedatestart,
    String conditionusedateend,
    String vehicletype,
    String rental_value,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.search, color: Colors.blue),
      title: Text(parkinglotname),
      subtitle: Text(
        '${AppLocalizations.of(context).keyword}$conditionkeywordfree\n${AppLocalizations.of(context).carType}$vehicletype\n${AppLocalizations.of(context).rentalType}$rental_value',
      ),
      trailing: Text(
        '${AppLocalizations.of(context).useStartDate}$conditionusedatestart\n～\n${AppLocalizations.of(context).useEndDate}:$conditionusedateend',
        style: TextStyle(color: Colors.red[600]),
      ),
      onTap: () {
        print('${searchid}Icon Button Pressed!');
      },
    );
  }

  Widget _buildFavoriteItems() {
    return _favorites.isEmpty
        ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 24),
            Text(
              AppLocalizations.of(context).noFavorite,
              style: TextStyle(color: Colors.red[600]),
            ),
          ],
        )
        : ListView.separated(
          shrinkWrap: true,
          itemCount: _favorites.length,
          itemBuilder: (context, index) {
            return _buildFavoriteItem(
              _favorites[index]['favorite_id'],
              _favorites[index]['parking_lot_name'],
              _favorites[index]['nearest_station'],
              _favorites[index]['charge'],
            );
          }, //
          separatorBuilder: (context, index) {
            return Divider();
          },
        );
  }

  Widget _buildFavoriteItem(
    String favoriteid,
    String parkinglotname,
    String neareststation,
    String charge,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.favorite, color: Colors.red[600]),
      title: Text(parkinglotname),
      subtitle: Text(neareststation),
      trailing: Text(charge, style: TextStyle(color: Colors.red[600])),
      onTap: () {
        print('${favoriteid}Icon Button Pressed!');
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
