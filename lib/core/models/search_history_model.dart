class SearchHistoryModel {
  final String search_id;
  final String user_id;
  final String? parking_lot_id;
  final String? parking_lot_name;
  final String? condition_keyword_free;
  final String? condition_use_date_start;
  final String? condition_use_date_end;
  final String? condition_vehicle_type_id;
  final String? vehicle_type;
  final String? condition_rental_type_id;
  final String? rental_type;
  final String? rental_value;
  final DateTime? created_datetime;
  final DateTime? updated_datetime;

  SearchHistoryModel({
    required this.search_id,
    required this.user_id,
    this.parking_lot_id,
    this.parking_lot_name,
    this.condition_keyword_free,
    this.condition_use_date_start,
    this.condition_use_date_end,
    this.condition_vehicle_type_id,
    this.vehicle_type,
    this.condition_rental_type_id,
    this.rental_type,
    this.rental_value,
    this.created_datetime,
    this.updated_datetime,
  });

  // Add getters for snake_case property access

  factory SearchHistoryModel.fromJson(Map<String, dynamic> json) {
    return SearchHistoryModel(
      search_id: json['search_id'],
      user_id: json['user_id'],
      parking_lot_id: json['parking_lot_id'],
      parking_lot_name: json['parking_lot_name'],
      condition_keyword_free: json['condition_keyword_free'],
      condition_use_date_start: json['condition_use_date_start'],
      condition_use_date_end: json['condition_use_date_end'],
      condition_vehicle_type_id: json['condition_vehicle_type_id'],
      vehicle_type: json['vehicle_type'],
      condition_rental_type_id: json['condition_rental_type_id'],
      rental_type: json['rental_type'],
      rental_value: json['rental_value'],
      created_datetime: DateTime.parse(json['created_datetime']),
      updated_datetime: DateTime.parse(json['updated_datetime']),
    );
  }
}

/// 駐車場検索履歴のリクエスト
class SearchHistoryRequest {
  final String? user_id;

  SearchHistoryRequest({required this.user_id});

  Map<String, dynamic> toJson() => {'user_id': user_id};
}
