import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class LocationSection extends StatefulWidget {
  final void Function(double latitude, double longitude)? onLocationChanged;
  final void Function(String nearestStation)? onNearestStationChanged;  // 新增

  const LocationSection({super.key, this.onLocationChanged, this.onNearestStationChanged});

  @override
  State<LocationSection> createState() => _LocationSectionState();
}

class _LocationSectionState extends State<LocationSection> {
  final MapController _mapController = MapController();
  double? _latitude;
  double? _longitude;

  void _updateLatLon(double lat, double lon) {
    setState(() {
      _latitude = lat;
      _longitude = lon;
      _latController.text = lat.toStringAsFixed(6);
      _lonController.text = lon.toStringAsFixed(6);
    });

    // 👇 外部回调
    widget.onLocationChanged?.call(lat, lon);
  }
  
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lonController = TextEditingController();

  String _nearestStation = '未取得';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _determinePositionAndFetchStation();
    });
    // flutter_map 8.x 监听地图事件（监听移动结束，更新坐标）
    _mapController.mapEventStream.listen((event) {
      if (event is MapEventMoveEnd) {
        final center = _mapController.camera.center;
        _updateLatLon(center.latitude, center.longitude);
      }
    });

  }

  @override
  void dispose() {
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }

  Future<void> _determinePositionAndFetchStation() async {
    setState(() => _isLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception("位置サービスが無効です");
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception("位置情報の権限が拒否されました");
      }

      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation,
        );

      _updateLatLon(position.latitude, position.longitude);
      _mapController.move(LatLng(position.latitude, position.longitude), 16);
      print('Current Position: lat=${position.latitude}, lon=${position.longitude}');

      final station = await _fetchNearestStation(_latitude!, _longitude!);

      setState(() {
        if (station != null) {
          final name = station['name']?.toString() ?? '駅名なし';
          final distance = station['distance'] as double? ?? 0.0;
          _nearestStation = '$name （約${distance.toStringAsFixed(0)}m）';
        } else {
          _nearestStation = '見つかりませんでした';
        }
        _isLoading = false;
      });
      
      // 调用父组件回调
      widget.onNearestStationChanged?.call(_nearestStation);

    } catch (e) {
      // 异常时也设默认值
      _updateLatLon(35.6586, 139.7454);
      setState(() {
        _nearestStation = '取得失敗: $e';
        _isLoading = false;
      });

      // 传递给父页面最近车站信息回调
      widget.onNearestStationChanged?.call(_nearestStation);
    }
  }


  Future<Map<String, dynamic>?> _fetchNearestStation(double lat, double lon) async {
    final query = """
      [out:json];
      (
        node["railway"="station"](around:1000,$lat,$lon);
      );
      out body;
    """;

    final response = await http.post(
      Uri.parse('https://overpass-api.de/api/interpreter'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'data': query},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final elements = data['elements'] as List<dynamic>;
      if (elements.isNotEmpty) {
        // 找到最近的车站节点
        Map<String, dynamic>? nearestStation;
        double minDistance = double.infinity;

        for (var element in elements) {
          final stationLat = element['lat'];
          final stationLon = element['lon'];

          // 计算两点间距离（米）
          double distance = _calculateDistance(lat, lon, stationLat, stationLon);
          if (distance < minDistance) {
            minDistance = distance;
            nearestStation = element;
          }
        }

        if (nearestStation != null) {
          return {
            'name': nearestStation['tags']?['name'] ?? '駅名なし',
            'distance': minDistance,
          };
        }
      }
    }
    return null;
  }

  // 计算两点之间的距离，单位：米
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371000; // 地球半径（米）
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = 
      (sin(dLat / 2) * sin(dLat / 2)) +
      cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
      (sin(dLon / 2) * sin(dLon / 2));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }



  Future<void> _onLocationChanged() async {
    final lat = double.tryParse(_latController.text);
    final lon = double.tryParse(_lonController.text);
    if (lat == null || lon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('正しい数値を入力してください')),
      );
      return;
    }
    setState(() {
      _latitude = lat;
      _longitude = lon;
      _isLoading = true;
    });
    _mapController.move(LatLng(lat, lon), 16);

    final stationInfo = await _fetchNearestStation(lat, lon);
    setState(() {
      if (stationInfo != null) {
        final name = stationInfo['name']?.toString() ?? '駅名なし';
        final distance = stationInfo['distance'] as double? ?? 0.0;
        _nearestStation = '$name （約${distance.toStringAsFixed(0)}m）';
      } else {
        _nearestStation = '見つかりませんでした';
      }
      _isLoading = false;
    });
    // 调用父组件回调
    widget.onNearestStationChanged?.call(_nearestStation);
  }



  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = context.size;
      print('LocationSection size: $size');
    });

    LatLng initialPosition = (_latitude != null && _longitude != null)
        ? LatLng(_latitude!, _longitude!)
        : LatLng(35.6586, 139.7454); // fallback: 东京塔

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '位置情報',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            width: double.infinity, // 明确宽度
            child: (_latitude == null || _longitude == null)
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: initialPosition,// 初始中心点
                          initialZoom: 16,
                          onTap: (tapPosition, latlng) {
                            _updateLatLon(latlng.latitude, latlng.longitude);
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                            subdomains: const ['a', 'b', 'c'],
                            userAgentPackageName: 'com.example.app',
                          ),
                        ],
                      ),
                      const Center(
                        child: Text(
                          '📍',
                          style: TextStyle(
                            fontSize: 36,
                            color: Colors.redAccent,
                          ),
                        ),
                      )
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Flexible(
                flex: 5,
                child: TextFormField(
                  controller: _latController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    labelText: '緯度 (Latitude)',
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
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                flex: 5,
                child: TextFormField(
                  controller: _lonController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    labelText: '経度 (Longitude)',
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
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _onLocationChanged,
                  child: const Text('更新'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('最寄り駅（更新ボタンで取得・距離表示1KM以内）'), 
          const SizedBox(height: 6),
          _isLoading
              ? const CircularProgressIndicator()
              : Text(
                  _nearestStation,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.blue,
                  ),
                ),
        ],
      ),
    );
  }
}
