// lib/core/models/parking_search_model.dart
/// 駐車場検索機能に関連するデータモデル
///
/// このモデルは以下のデータベーステーブルの構造に基づいて設計されています：
/// - t_parking_lots(駐車場基本情報)
/// - t_parking_google_maps(Google Maps関連情報)
/// - t_parking_rental_types(貸出タイプ)
/// - m_parking_vehicle_types(対応車種)
/// - m_parking_features(駐車場特徴)
/// - t_favorites(お気に入り)
library;

/// 駐車場検索リクエストモデル
class ParkingSearchRequestModel {
  /// 論理名: 検索キーワード
  /// 駐車場名または住所での部分一致検索
  final String? keyword;

  /// 論理名: 検索開始日時
  /// 利用予定の開始日時
  final DateTime? startDateTime;

  /// 論理名: 検索終了日時
  /// 利用予定の終了日時
  final DateTime? endDateTime;

  /// 論理名: 都道府県
  /// 検索対象の都道府県
  final String? prefecture;

  /// 論理名: 市区町村
  /// 検索対象の市区町村
  final String? city;

  /// 論理名: 車種
  /// 対応車種での絞り込み（例: 軽自動車、普通車、大型車）
  final String? vehicleType;

  /// 論理名: 貸出タイプ
  /// 時間単位または日間単位
  final String? rentalType;

  /// 論理名: 最低料金
  /// 検索条件の最低料金（円）
  final int? minPrice;

  /// 論理名: 最高料金
  /// 検索条件の最高料金（円）
  final int? maxPrice;

  /// 論理名: 特徴フィルタ
  /// 駐車場の特徴による絞り込み（例: 24時間営業、屋根あり）
  final List<String>? features;

  /// 論理名: 並び順
  /// 検索結果の並び順（例: price_asc, distance_asc, rating_desc）
  final String? sortBy;

  /// 論理名: ページ番号
  /// ページネーション用のページ番号
  final int page;

  /// 論理名: 1ページあたりの件数
  /// ページネーション用の件数
  final int perPage;

  /// 論理名: お気に入りのみ
  /// お気に入り駐車場のみを検索するフラグ
  final bool? favoritesOnly;

  /// 論理名: 緯度
  /// 位置情報検索用の緯度
  final double? latitude;

  /// 論理名: 経度
  /// 位置情報検索用の経度
  final double? longitude;

  /// 論理名: 検索半径
  /// 位置情報検索の半径（km）
  final double? radius;

  const ParkingSearchRequestModel({
    this.keyword,
    this.startDateTime,
    this.endDateTime,
    this.prefecture,
    this.city,
    this.vehicleType,
    this.rentalType,
    this.minPrice,
    this.maxPrice,
    this.features,
    this.sortBy,
    this.page = 1,
    this.perPage = 20,
    this.favoritesOnly,
    this.latitude,
    this.longitude,
    this.radius,
  });

  /// JSONマップからParkingSearchRequestModelを作成
  factory ParkingSearchRequestModel.fromJson(Map<String, dynamic> json) {
    return ParkingSearchRequestModel(
      keyword: json['keyword']?.toString(),
      startDateTime:
          json['start_datetime'] != null
              ? DateTime.parse(json['start_datetime'])
              : null,
      endDateTime:
          json['end_datetime'] != null
              ? DateTime.parse(json['end_datetime'])
              : null,
      prefecture: json['prefecture']?.toString(),
      city: json['city']?.toString(),
      vehicleType: json['vehicle_type']?.toString(),
      rentalType: json['rental_type']?.toString(),
      minPrice: json['min_price']?.toInt(),
      maxPrice: json['max_price']?.toInt(),
      features:
          json['features'] != null ? List<String>.from(json['features']) : null,
      sortBy: json['sort_by']?.toString(),
      page: json['page']?.toInt() ?? 1,
      perPage: json['per_page']?.toInt() ?? 20,
      favoritesOnly: json['favorites_only']?.toBool(),
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      radius: json['radius']?.toDouble(),
    );
  }

  /// ParkingSearchRequestModelをJSONマップに変換
  Map<String, dynamic> toJson() {
    return {
      if (keyword != null) 'keyword': keyword,
      if (startDateTime != null)
        'start_datetime': startDateTime!.toIso8601String(),
      if (endDateTime != null) 'end_datetime': endDateTime!.toIso8601String(),
      if (prefecture != null) 'prefecture': prefecture,
      if (city != null) 'city': city,
      if (vehicleType != null) 'vehicle_type': vehicleType,
      if (rentalType != null) 'rental_type': rentalType,
      if (minPrice != null) 'min_price': minPrice,
      if (maxPrice != null) 'max_price': maxPrice,
      if (features != null) 'features': features,
      if (sortBy != null) 'sort_by': sortBy,
      'page': page,
      'per_page': perPage,
      if (favoritesOnly != null) 'favorites_only': favoritesOnly,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (radius != null) 'radius': radius,
    };
  }

  /// クエリパラメータ用のマップに変換
  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{};

    if (keyword != null && keyword!.isNotEmpty) {
      params['keyword'] = keyword;
    }
    if (startDateTime != null) {
      params['start_datetime'] = startDateTime!.toIso8601String();
    }
    if (endDateTime != null) {
      params['end_datetime'] = endDateTime!.toIso8601String();
    }
    if (prefecture != null && prefecture!.isNotEmpty) {
      params['prefecture'] = prefecture;
    }
    if (city != null && city!.isNotEmpty) {
      params['city'] = city;
    }
    if (vehicleType != null && vehicleType!.isNotEmpty) {
      params['vehicle_type'] = vehicleType;
    }
    if (rentalType != null && rentalType!.isNotEmpty) {
      params['rental_type'] = rentalType;
    }
    if (minPrice != null) {
      params['min_price'] = minPrice.toString();
    }
    if (maxPrice != null) {
      params['max_price'] = maxPrice.toString();
    }
    if (features != null && features!.isNotEmpty) {
      params['features'] = features!.join(',');
    }
    if (sortBy != null && sortBy!.isNotEmpty) {
      params['sort_by'] = sortBy;
    }
    params['page'] = page.toString();
    params['per_page'] = perPage.toString();
    if (favoritesOnly != null) {
      params['favorites_only'] = favoritesOnly.toString();
    }
    if (latitude != null) {
      params['latitude'] = latitude.toString();
    }
    if (longitude != null) {
      params['longitude'] = longitude.toString();
    }
    if (radius != null) {
      params['radius'] = radius.toString();
    }

    return params;
  }

  /// コピーメソッド
  ParkingSearchRequestModel copyWith({
    String? keyword,
    DateTime? startDateTime,
    DateTime? endDateTime,
    String? prefecture,
    String? city,
    String? vehicleType,
    String? rentalType,
    int? minPrice,
    int? maxPrice,
    List<String>? features,
    String? sortBy,
    int? page,
    int? perPage,
    bool? favoritesOnly,
    double? latitude,
    double? longitude,
    double? radius,
  }) {
    return ParkingSearchRequestModel(
      keyword: keyword ?? this.keyword,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      prefecture: prefecture ?? this.prefecture,
      city: city ?? this.city,
      vehicleType: vehicleType ?? this.vehicleType,
      rentalType: rentalType ?? this.rentalType,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      features: features ?? this.features,
      sortBy: sortBy ?? this.sortBy,
      page: page ?? this.page,
      perPage: perPage ?? this.perPage,
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radius: radius ?? this.radius,
    );
  }

  @override
  String toString() {
    return 'ParkingSearchRequestModel(keyword: $keyword, startDateTime: $startDateTime, endDateTime: $endDateTime, prefecture: $prefecture, city: $city, vehicleType: $vehicleType, rentalType: $rentalType, minPrice: $minPrice, maxPrice: $maxPrice, features: $features, sortBy: $sortBy, page: $page, perPage: $perPage, favoritesOnly: $favoritesOnly, latitude: $latitude, longitude: $longitude, radius: $radius)';
  }
}

/// 駐車場基本情報モデル（t_parking_lotsテーブルベース）
class ParkingLotModel {
  /// 論理名: 駐車場ID
  /// 物理名: parking_lot_id（形式: P-XXXXXX）
  final String parkingLotId;

  /// 論理名: オーナーID
  /// 物理名: owner_id（形式: owner_XXXXXX）
  final String ownerId;

  /// 論理名: 駐車場名
  /// 物理名: parking_lot_name
  final String parkingLotName;

  /// 論理名: 郵便番号
  /// 物理名: postal_code（例: 123-4567）
  final String postalCode;

  /// 論理名: 都道府県
  /// 物理名: prefecture
  final String prefecture;

  /// 論理名: 市区町村
  /// 物理名: city
  final String city;

  /// 論理名: 住所詳細
  /// 物理名: address_detail
  final String addressDetail;

  /// 論理名: 電話番号
  /// 物理名: phone_number
  final String phoneNumber;

  /// 論理名: 収容台数
  /// 物理名: capacity
  final int capacity;

  /// 論理名: 空き台数
  /// 物理名: available_capacity
  final int? availableCapacity;

  /// 論理名: 貸出タイプ
  /// 物理名: rental_type（時間単位、日間単位）
  final String? rentalType;

  /// 論理名: 料金
  /// 物理名: charge
  final String charge;

  /// 論理名: 特徴概要
  /// 物理名: features_tip
  final String? featuresTip;

  /// 論理名: 最寄り駅
  /// 物理名: nearest_station
  final String? nearestStation;

  /// 論理名: 状態
  /// 物理名: status（アクティブ、停止中）
  final String status;

  /// 論理名: 利用開始日
  /// 物理名: start_date
  final DateTime startDate;

  /// 論理名: 利用停止日
  /// 物理名: end_date
  final DateTime? endDate;

  /// 論理名: お気に入りフラグ
  /// ユーザーのお気に入り状態（UI表示用）
  final bool isFavorite;

  /// 論理名: 評価スコア
  /// 計算値（UI表示用）
  final double? rating;

  /// 論理名: 距離
  /// 現在地からの距離（km、計算値）
  final double? distance;

  /// 論理名: 時間料金
  /// 1時間あたりの料金（円、UI表示用）
  final int? hourlyRate;

  const ParkingLotModel({
    required this.parkingLotId,
    required this.ownerId,
    required this.parkingLotName,
    required this.postalCode,
    required this.prefecture,
    required this.city,
    required this.addressDetail,
    required this.phoneNumber,
    required this.capacity,
    this.availableCapacity,
    this.rentalType,
    required this.charge,
    this.featuresTip,
    this.nearestStation,
    required this.status,
    required this.startDate,
    this.endDate,
    this.isFavorite = false,
    this.rating,
    this.distance,
    this.hourlyRate,
  });

  /// JSONマップからParkingLotModelを作成
  factory ParkingLotModel.fromJson(Map<String, dynamic> json) {
    return ParkingLotModel(
      parkingLotId: json['parking_lot_id']?.toString() ?? '',
      ownerId: json['owner_id']?.toString() ?? '',
      parkingLotName: json['parking_lot_name']?.toString() ?? '',
      postalCode: json['postal_code']?.toString() ?? '',
      prefecture: json['prefecture']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      addressDetail: json['address_detail']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString() ?? '',
      capacity: json['capacity']?.toInt() ?? 0,
      availableCapacity: json['available_capacity']?.toInt(),
      rentalType: json['rental_type']?.toString(),
      charge: json['charge']?.toString() ?? '',
      featuresTip: json['features_tip']?.toString(),
      nearestStation: json['nearest_station']?.toString(),
      status: json['status']?.toString() ?? '',
      startDate:
          json['start_date'] != null
              ? DateTime.parse(json['start_date'])
              : DateTime.now(),
      endDate:
          json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      isFavorite: json['is_favorite']?.toBool() ?? false,
      rating: json['rating']?.toDouble(),
      distance: json['distance']?.toDouble(),
      hourlyRate: json['hourly_rate']?.toInt(),
    );
  }

  /// ParkingLotModelをJSONマップに変換
  Map<String, dynamic> toJson() {
    return {
      'parking_lot_id': parkingLotId,
      'owner_id': ownerId,
      'parking_lot_name': parkingLotName,
      'postal_code': postalCode,
      'prefecture': prefecture,
      'city': city,
      'address_detail': addressDetail,
      'phone_number': phoneNumber,
      'capacity': capacity,
      if (availableCapacity != null) 'available_capacity': availableCapacity,
      if (rentalType != null) 'rental_type': rentalType,
      'charge': charge,
      if (featuresTip != null) 'features_tip': featuresTip,
      if (nearestStation != null) 'nearest_station': nearestStation,
      'status': status,
      'start_date': startDate.toIso8601String(),
      if (endDate != null) 'end_date': endDate!.toIso8601String(),
      'is_favorite': isFavorite,
      if (rating != null) 'rating': rating,
      if (distance != null) 'distance': distance,
      if (hourlyRate != null) 'hourly_rate': hourlyRate,
    };
  }

  /// 完全な住所を取得
  String get fullAddress => '$prefecture$city$addressDetail';

  /// 利用可能かどうかを判定
  bool get isAvailable =>
      status == 'アクティブ' &&
      (endDate == null || endDate!.isAfter(DateTime.now()));

  /// コピーメソッド
  ParkingLotModel copyWith({
    String? parkingLotId,
    String? ownerId,
    String? parkingLotName,
    String? postalCode,
    String? prefecture,
    String? city,
    String? addressDetail,
    String? phoneNumber,
    int? capacity,
    int? availableCapacity,
    String? rentalType,
    String? charge,
    String? featuresTip,
    String? nearestStation,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    bool? isFavorite,
    double? rating,
    double? distance,
    int? hourlyRate,
  }) {
    return ParkingLotModel(
      parkingLotId: parkingLotId ?? this.parkingLotId,
      ownerId: ownerId ?? this.ownerId,
      parkingLotName: parkingLotName ?? this.parkingLotName,
      postalCode: postalCode ?? this.postalCode,
      prefecture: prefecture ?? this.prefecture,
      city: city ?? this.city,
      addressDetail: addressDetail ?? this.addressDetail,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      capacity: capacity ?? this.capacity,
      availableCapacity: availableCapacity ?? this.availableCapacity,
      rentalType: rentalType ?? this.rentalType,
      charge: charge ?? this.charge,
      featuresTip: featuresTip ?? this.featuresTip,
      nearestStation: nearestStation ?? this.nearestStation,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isFavorite: isFavorite ?? this.isFavorite,
      rating: rating ?? this.rating,
      distance: distance ?? this.distance,
      hourlyRate: hourlyRate ?? this.hourlyRate,
    );
  }

  @override
  String toString() {
    return 'ParkingLotModel(parkingLotId: $parkingLotId, parkingLotName: $parkingLotName, fullAddress: $fullAddress, capacity: $capacity, availableCapacity: $availableCapacity, isFavorite: $isFavorite)';
  }
}

/// Google Maps関連情報モデル（t_parking_google_mapsテーブルベース）
class ParkingGoogleMapsModel {
  /// 論理名: Google Maps情報ID
  /// 物理名: google_maps_id
  final String googleMapsId;

  /// 論理名: 駐車場ID
  /// 物理名: parking_lot_id
  final String parkingLotId;

  /// 論理名: 緯度
  /// 物理名: latitude
  final double? latitude;

  /// 論理名: 経度
  /// 物理名: longitude
  final double? longitude;

  /// 論理名: Google Place ID
  /// 物理名: place_id
  final String? placeId;

  /// 論理名: ズームレベル
  /// 物理名: zoom_level
  final int? zoomLevel;

  /// 論理名: 地図タイプ
  /// 物理名: map_type
  final String? mapType;

  /// 論理名: Google Maps URL
  /// 物理名: google_maps_url
  final String? googleMapsUrl;

  /// 論理名: Google Maps埋め込みリンク
  /// 物理名: google_maps_embed
  final String? googleMapsEmbed;

  /// 論理名: 説明
  /// 物理名: description
  final String? description;

  const ParkingGoogleMapsModel({
    required this.googleMapsId,
    required this.parkingLotId,
    this.latitude,
    this.longitude,
    this.placeId,
    this.zoomLevel,
    this.mapType,
    this.googleMapsUrl,
    this.googleMapsEmbed,
    this.description,
  });

  /// JSONマップからParkingGoogleMapsModelを作成
  factory ParkingGoogleMapsModel.fromJson(Map<String, dynamic> json) {
    return ParkingGoogleMapsModel(
      googleMapsId: json['google_maps_id']?.toString() ?? '',
      parkingLotId: json['parking_lot_id']?.toString() ?? '',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      placeId: json['place_id']?.toString(),
      zoomLevel: json['zoom_level']?.toInt(),
      mapType: json['map_type']?.toString(),
      googleMapsUrl: json['google_maps_url']?.toString(),
      googleMapsEmbed: json['google_maps_embed']?.toString(),
      description: json['description']?.toString(),
    );
  }

  /// ParkingGoogleMapsModelをJSONマップに変換
  Map<String, dynamic> toJson() {
    return {
      'google_maps_id': googleMapsId,
      'parking_lot_id': parkingLotId,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (placeId != null) 'place_id': placeId,
      if (zoomLevel != null) 'zoom_level': zoomLevel,
      if (mapType != null) 'map_type': mapType,
      if (googleMapsUrl != null) 'google_maps_url': googleMapsUrl,
      if (googleMapsEmbed != null) 'google_maps_embed': googleMapsEmbed,
      if (description != null) 'description': description,
    };
  }

  /// 位置情報が利用可能かどうかを判定
  bool get hasLocation => latitude != null && longitude != null;
}

/// 駐車場特徴モデル（m_parking_featuresテーブルベース）
class ParkingFeatureModel {
  /// 論理名: 特徴ID
  /// 物理名: feature_id
  final String featureId;

  /// 論理名: 駐車場ID
  /// 物理名: parking_lot_id
  final String parkingLotId;

  /// 論理名: 特徴タイプ
  /// 物理名: feature_type（例: 営業時間、予約タイプ、最大料金）
  final String featureType;

  /// 論理名: 特徴値
  /// 物理名: feature_value（例: 24時間営業、再入庫可能）
  final String featureValue;

  const ParkingFeatureModel({
    required this.featureId,
    required this.parkingLotId,
    required this.featureType,
    required this.featureValue,
  });

  /// JSONマップからParkingFeatureModelを作成
  factory ParkingFeatureModel.fromJson(Map<String, dynamic> json) {
    return ParkingFeatureModel(
      featureId: json['feature_id']?.toString() ?? '',
      parkingLotId: json['parking_lot_id']?.toString() ?? '',
      featureType: json['feature_type']?.toString() ?? '',
      featureValue: json['feature_value']?.toString() ?? '',
    );
  }

  /// ParkingFeatureModelをJSONマップに変換
  Map<String, dynamic> toJson() {
    return {
      'feature_id': featureId,
      'parking_lot_id': parkingLotId,
      'feature_type': featureType,
      'feature_value': featureValue,
    };
  }
}

/// 駐車場対応車種モデル（m_parking_vehicle_typesテーブルベース）
class ParkingVehicleTypeModel {
  /// 論理名: 車種ID
  /// 物理名: vehicle_type_id
  final String vehicleTypeId;

  /// 論理名: 駐車場ID
  /// 物理名: parking_lot_id
  final String parkingLotId;

  /// 論理名: 車種
  /// 物理名: vehicle_type（例: オートバイ、軽自動車、ワンボックスカー）
  final String vehicleType;

  const ParkingVehicleTypeModel({
    required this.vehicleTypeId,
    required this.parkingLotId,
    required this.vehicleType,
  });

  /// JSONマップからParkingVehicleTypeModelを作成
  factory ParkingVehicleTypeModel.fromJson(Map<String, dynamic> json) {
    return ParkingVehicleTypeModel(
      vehicleTypeId: json['vehicle_type_id']?.toString() ?? '',
      parkingLotId: json['parking_lot_id']?.toString() ?? '',
      vehicleType: json['vehicle_type']?.toString() ?? '',
    );
  }

  /// ParkingVehicleTypeModelをJSONマップに変換
  Map<String, dynamic> toJson() {
    return {
      'vehicle_type_id': vehicleTypeId,
      'parking_lot_id': parkingLotId,
      'vehicle_type': vehicleType,
    };
  }
}

/// 駐車場貸出タイプモデル（t_parking_rental_typesテーブルベース）
class ParkingRentalTypeModel {
  /// 論理名: 貸出タイプID
  /// 物理名: rental_type_id
  final String rentalTypeId;

  /// 論理名: 駐車場ID
  /// 物理名: parking_lot_id
  final String parkingLotId;

  /// 論理名: 貸出タイプ
  /// 物理名: rental_type（時間単位、日間単位）
  final String rentalType;

  /// 論理名: 貸出値
  /// 物理名: rental_value（例: 15分、1日）
  final String rentalValue;

  const ParkingRentalTypeModel({
    required this.rentalTypeId,
    required this.parkingLotId,
    required this.rentalType,
    required this.rentalValue,
  });

  /// JSONマップからParkingRentalTypeModelを作成
  factory ParkingRentalTypeModel.fromJson(Map<String, dynamic> json) {
    return ParkingRentalTypeModel(
      rentalTypeId: json['rental_type_id']?.toString() ?? '',
      parkingLotId: json['parking_lot_id']?.toString() ?? '',
      rentalType: json['rental_type']?.toString() ?? '',
      rentalValue: json['rental_value']?.toString() ?? '',
    );
  }

  /// ParkingRentalTypeModelをJSONマップに変換
  Map<String, dynamic> toJson() {
    return {
      'rental_type_id': rentalTypeId,
      'parking_lot_id': parkingLotId,
      'rental_type': rentalType,
      'rental_value': rentalValue,
    };
  }
}

/// 駐車場詳細モデル（複数テーブル結合）
class ParkingLotDetailModel {
  /// 論理名: 駐車場基本情報
  final ParkingLotModel parkingLot;

  /// 論理名: Google Maps情報
  final ParkingGoogleMapsModel? googleMaps;

  /// 論理名: 駐車場特徴一覧
  final List<ParkingFeatureModel> features;

  /// 論理名: 対応車種一覧
  final List<ParkingVehicleTypeModel> vehicleTypes;

  /// 論理名: 貸出タイプ一覧
  final List<ParkingRentalTypeModel> rentalTypes;

  const ParkingLotDetailModel({
    required this.parkingLot,
    this.googleMaps,
    this.features = const [],
    this.vehicleTypes = const [],
    this.rentalTypes = const [],
  });

  /// JSONマップからParkingLotDetailModelを作成
  factory ParkingLotDetailModel.fromJson(Map<String, dynamic> json) {
    return ParkingLotDetailModel(
      parkingLot: ParkingLotModel.fromJson(json['parking_lot'] ?? {}),
      googleMaps:
          json['google_maps'] != null
              ? ParkingGoogleMapsModel.fromJson(json['google_maps'])
              : null,
      features:
          json['features'] != null
              ? (json['features'] as List)
                  .map((e) => ParkingFeatureModel.fromJson(e))
                  .toList()
              : [],
      vehicleTypes:
          json['vehicle_types'] != null
              ? (json['vehicle_types'] as List)
                  .map((e) => ParkingVehicleTypeModel.fromJson(e))
                  .toList()
              : [],
      rentalTypes:
          json['rental_types'] != null
              ? (json['rental_types'] as List)
                  .map((e) => ParkingRentalTypeModel.fromJson(e))
                  .toList()
              : [],
    );
  }

  /// ParkingLotDetailModelをJSONマップに変換
  Map<String, dynamic> toJson() {
    return {
      'parking_lot': parkingLot.toJson(),
      if (googleMaps != null) 'google_maps': googleMaps!.toJson(),
      'features': features.map((e) => e.toJson()).toList(),
      'vehicle_types': vehicleTypes.map((e) => e.toJson()).toList(),
      'rental_types': rentalTypes.map((e) => e.toJson()).toList(),
    };
  }

  /// 駐車場基本情報のアクセサー
  String get parkingLotId => parkingLot.parkingLotId;
  String get parkingLotName => parkingLot.parkingLotName;
  String get fullAddress => parkingLot.fullAddress;
  bool get isFavorite => parkingLot.isFavorite;

  /// 特定の特徴を取得
  String? getFeatureValue(String featureType) {
    try {
      return features
          .firstWhere((feature) => feature.featureType == featureType)
          .featureValue;
    } catch (e) {
      return null;
    }
  }

  /// 24時間営業かどうかを判定
  bool get is24Hours => getFeatureValue('営業時間') == '24時間営業';

  /// 屋根があるかどうかを判定
  bool get hasRoof => getFeatureValue('屋根') == 'あり';

  /// 再入庫可能かどうかを判定
  bool get allowsReentry => getFeatureValue('再入庫') == '再入庫可能';
}

/// 駐車場検索レスポンスモデル
class ParkingSearchResponse {
  /// 論理名: 駐車場一覧
  final List<ParkingLotModel> parkingLots;

  /// 論理名: 総件数
  final int totalCount;

  /// 論理名: 現在のページ
  final int currentPage;

  /// 論理名: 1ページあたりの件数
  final int perPage;

  /// 論理名: 総ページ数
  final int totalPages;

  /// 論理名: 次のページがあるか
  final bool hasNext;

  /// 論理名: 前のページがあるか
  final bool hasPrev;

  const ParkingSearchResponse({
    required this.parkingLots,
    required this.totalCount,
    required this.currentPage,
    required this.perPage,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  /// JSONマップからParkingSearchResponseを作成
  factory ParkingSearchResponse.fromJson(Map<String, dynamic> json) {
    return ParkingSearchResponse(
      parkingLots:
          json['parking_lots'] != null
              ? (json['parking_lots'] as List)
                  .map((e) => ParkingLotModel.fromJson(e))
                  .toList()
              : [],
      totalCount: json['total_count']?.toInt() ?? 0,
      currentPage: json['current_page']?.toInt() ?? 1,
      perPage: json['per_page']?.toInt() ?? 20,
      totalPages: json['total_pages']?.toInt() ?? 0,
      hasNext: json['has_next']?.toBool() ?? false,
      hasPrev: json['has_prev']?.toBool() ?? false,
    );
  }

  /// ParkingSearchResponseをJSONマップに変換
  Map<String, dynamic> toJson() {
    return {
      'parking_lots': parkingLots.map((e) => e.toJson()).toList(),
      'total_count': totalCount,
      'current_page': currentPage,
      'per_page': perPage,
      'total_pages': totalPages,
      'has_next': hasNext,
      'has_prev': hasPrev,
    };
  }

  /// 検索結果が空かどうかを判定
  bool get isEmpty => parkingLots.isEmpty;

  /// 検索結果があるかどうかを判定
  bool get isNotEmpty => parkingLots.isNotEmpty;
}
