class ParkingFeatureModel {
  final String feature_id;
  final String? feature_type;
  final String? feature_value;
  final DateTime? created_datetime;
  final DateTime? updated_datetime;

  ParkingFeatureModel({
    required this.feature_id,
    this.feature_type,
    this.feature_value,
    this.created_datetime,
    this.updated_datetime,
  });

  // Add getters for snake_case property access

  factory ParkingFeatureModel.fromJson(Map<String, dynamic> json) {
    return ParkingFeatureModel(
      feature_id: json['feature_id'],
      feature_type: json['feature_type'],
      feature_value: json['feature_value'],
      created_datetime: DateTime.parse(json['created_datetime']),
      updated_datetime: DateTime.parse(json['updated_datetime']),
    );
  }
}

/// 駐車場特徴のリクエスト
class ParkingFeatureRequest {
  final String? parking_lot_id;

  ParkingFeatureRequest({required this.parking_lot_id});

  Map<String, dynamic> toJson() => {'parking_lot_id': parking_lot_id};
}
