class FavoriteModel {
  final String favorite_id;
  final String user_id;
  final String parking_lot_id;
  final String parking_lot_name;
  final String? nearest_station;
  final String? charge;
  final DateTime? created_datetime;
  final DateTime? updated_datetime;

  FavoriteModel({
    required this.favorite_id,
    required this.user_id,
    required this.parking_lot_id,
    required this.parking_lot_name,
    this.nearest_station,
    this.charge,
    this.created_datetime,
    this.updated_datetime,
  });

  // Add getters for snake_case property access

  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    return FavoriteModel(
      favorite_id: json['favorite_id'],
      user_id: json['user_id'],
      parking_lot_id: json['parking_lot_id'],
      parking_lot_name: json['parking_lot_name'],
      nearest_station: json['nearest_station'],
      charge: json['charge'],
      created_datetime: DateTime.parse(json['created_datetime']),
      updated_datetime: DateTime.parse(json['updated_datetime']),
    );
  }
}

/// お気に入れのリクエスト
class FavoriteRequest {
  final String? user_id;

  FavoriteRequest({required this.user_id});

  Map<String, dynamic> toJson() => {'user_id': user_id};
}
