class ParkingLotsModel {
  final String ownerId;
  final String parkingLotName;
  final String postalCode;
  final String prefecture;
  final String city;
  final String addressDetail;
  final String phoneNumber;
  final int capacity;
  final int? availableCapacity;
  final String rentalType;
  final String charge;
  final String? featuresTip;
  final String? nearestStation;
  final String latitude;
  final String longitude;
  final String status;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? endStartDatetime;
  final DateTime? endEndDatetime;
  final String? endReason;
  final String? endReasonDetail;
  final String? notes;
  final DateTime? createdDatetime;
  final DateTime? updatedDatetime;

  final ParkingLimitModel? limits;
  final List<ParkingVehicleTypeModel>? vehicleTypes;
  final List<ParkingImageModel>? images;

  ParkingLotsModel({
    required this.ownerId,
    required this.parkingLotName,
    required this.postalCode,
    required this.prefecture,
    required this.city,
    required this.addressDetail,
    required this.phoneNumber,
    required this.capacity,
    this.availableCapacity,
    required this.rentalType,
    required this.charge,
    this.featuresTip,
    this.nearestStation,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.startDate,
    this.endDate,
    this.endStartDatetime,
    this.endEndDatetime,
    this.endReason,
    this.endReasonDetail,
    this.notes,
    this.createdDatetime,
    this.updatedDatetime,
    this.limits,
    this.vehicleTypes,
    this.images,
  });

  factory ParkingLotsModel.fromJson(Map<String, dynamic> json) {
    return ParkingLotsModel(
      ownerId: json['owner_id'] as String,
      parkingLotName: json['parking_lot_name'] as String,
      postalCode: json['postal_code'] as String,
      prefecture: json['prefecture'] as String,
      city: json['city'] as String,
      addressDetail: json['address_detail'] as String,
      phoneNumber: json['phone_number'] as String,
      capacity: json['capacity'] as int,
      availableCapacity: json['available_capacity'] as int?,
      rentalType: json['rental_type'] as String,
      charge: json['charge'] as String,
      featuresTip: json['features_tip'] as String?,
      nearestStation: json['nearest_station'] as String?,
      latitude: json['latitude'].toString(),
      longitude: json['longitude'].toString(),
      status: json['status'] as String,
      startDate: DateTime.parse(json['start_date']),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      endStartDatetime: json['end_start_datetime'] != null ? DateTime.parse(json['end_start_datetime']) : null,
      endEndDatetime: json['end_end_datetime'] != null ? DateTime.parse(json['end_end_datetime']) : null,
      endReason: json['end_reason'] as String?,
      endReasonDetail: json['end_reason_detail'] as String?,
      notes: json['notes'] as String?,
      createdDatetime: json['created_datetime'] != null ? DateTime.parse(json['created_datetime']) : null,
      updatedDatetime: json['updated_datetime'] != null ? DateTime.parse(json['updated_datetime']) : null,
      limits: json['limits'] != null ? ParkingLimitModel.fromJson(json['limits']) : null,
      vehicleTypes: json['vehicle_types'] != null
          ? (json['vehicle_types'] as List)
              .map((e) => ParkingVehicleTypeModel.fromJson(e))
              .toList()
          : null,
      images: json['images'] != null
          ? (json['images'] as List)
              .map((e) => ParkingImageModel.fromJson(e))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'owner_id': ownerId,
      'parking_lot_name': parkingLotName,
      'postal_code': postalCode,
      'prefecture': prefecture,
      'city': city,
      'address_detail': addressDetail,
      'phone_number': phoneNumber,
      'capacity': capacity,
      'available_capacity': availableCapacity,
      'rental_type': rentalType,
      'charge': charge,
      'features_tip': featuresTip,
      'nearest_station': nearestStation,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'start_date': startDate.toIso8601String().split('T')[0], // 这里转换为纯日期字符串
      'end_date': endDate?.toIso8601String().split('T')[0], // 这里转换为纯日期字符串
      'end_start_datetime': endStartDatetime?.toIso8601String(),
      'end_end_datetime': endEndDatetime?.toIso8601String(),
      'end_reason': endReason,
      'end_reason_detail': endReasonDetail,
      'notes': notes,
      'created_datetime': createdDatetime?.toIso8601String(),
      'updated_datetime': updatedDatetime?.toIso8601String(),
    };

    if (limits != null) {
      data['limits'] = limits!.toJson();
    }
    if (vehicleTypes != null) {
      data['vehicle_types'] = vehicleTypes!.map((e) => e.toJson()).toList();
    }
    if (images != null) {
      data['images'] = images!.map((e) => e.toJson()).toList();
    }
    return data;
  }
}

class ParkingLimitModel {
  final int lengthLimit;
  final int widthLimit;
  final int heightLimit;
  final int weightLimit;
  final String carHeightLimit;
  final String tireWidthLimit;
  final String carBottomLimit;

  ParkingLimitModel({
    required this.lengthLimit,
    required this.widthLimit,
    required this.heightLimit,
    required this.weightLimit,
    required this.carHeightLimit,
    required this.tireWidthLimit,
    required this.carBottomLimit,
  });

  factory ParkingLimitModel.fromJson(Map<String, dynamic> json) {
    return ParkingLimitModel(
      lengthLimit: json['length_limit'] as int,
      widthLimit: json['width_limit'] as int,
      heightLimit: json['height_limit'] as int,
      weightLimit: json['weight_limit'] as int,
      carHeightLimit: json['car_height_limit'].toString(),
      tireWidthLimit: json['tire_width_limit'].toString(),
      carBottomLimit: json['car_bottom_limit'].toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'length_limit': lengthLimit,
      'width_limit': widthLimit,
      'height_limit': heightLimit,
      'weight_limit': weightLimit,
      'car_height_limit': carHeightLimit,
      'tire_width_limit': tireWidthLimit,
      'car_bottom_limit': carBottomLimit,
    };
  }
}

class ParkingVehicleTypeModel {
  final String vehicleType;
  final int capacity;

  ParkingVehicleTypeModel({
    required this.vehicleType,
    required this.capacity,
  });

  factory ParkingVehicleTypeModel.fromJson(Map<String, dynamic> json) {
    return ParkingVehicleTypeModel(
      vehicleType: json['vehicle_type'] as String,
      capacity: json['capacity'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicle_type': vehicleType,
      'capacity': capacity,
    };
  }
}

class ParkingImageModel {
  final String parkingLotId;
  final String imageUrl;

  ParkingImageModel({
    required this.parkingLotId,
    required this.imageUrl,
  });

  factory ParkingImageModel.fromJson(Map<String, dynamic> json) {
    return ParkingImageModel(
      parkingLotId: json['parking_lot_id'] as String,
      imageUrl: json['image_url'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'parking_lot_id': parkingLotId,
      'image_url': imageUrl,
    };
  }
}

class ParkingLotSummaryModel {
  final String parkingLotId;
  final String parkingLotName;

  ParkingLotSummaryModel({
    required this.parkingLotId,
    required this.parkingLotName,
  });

  factory ParkingLotSummaryModel.fromJson(Map<String, dynamic> json) {
    return ParkingLotSummaryModel(
      parkingLotId: json['parking_lot_id'],
      parkingLotName: json['parking_lot_name'],
    );
  }
}


/// 駐車場基本情報のリクエスト
class ParkingLotRequest {
  final String? parking_lot_id;

  ParkingLotRequest({required this.parking_lot_id});

  Map<String, dynamic> toJson() => {'reservation_id': parking_lot_id};
}