class ParkingLotModel {
  final String detail_id;
  final String? parking_lot_id;
  final String? parking_lot_name;
  final String? area;
  final String? entry_datetime;
  final String? exit_datetime;
  final String? start_datetime;
  final String? end_datetime;
  final String? amount;
  final DateTime? created_datetime;
  final DateTime? updated_datetime;

  ParkingLotModel({
    required this.detail_id,
    this.parking_lot_id,
    this.parking_lot_name,
    this.area,
    this.entry_datetime,
    this.exit_datetime,
    this.start_datetime,
    this.end_datetime,
    this.amount,
    this.created_datetime,
    this.updated_datetime,
  });

  // Add getters for snake_case property access

  factory ParkingLotModel.fromJson(Map<String, dynamic> json) {
    return ParkingLotModel(
      detail_id: json['detail_id'],
      parking_lot_id: json['parking_lot_id'],
      parking_lot_name: json['parking_lot_name'],
      area: json['area'],
      entry_datetime: json['entry_datetime'],
      exit_datetime: json['exit_datetime'],
      start_datetime: json['start_datetime'],
      end_datetime: json['end_datetime'],
      amount: json['amount'],
      created_datetime: DateTime.parse(json['created_datetime']),
      updated_datetime: DateTime.parse(json['updated_datetime']),
    );
  }
}

/// 駐車場基本情報のリクエスト
class ParkingLotRequest {
  final String? parking_lot_id;

  ParkingLotRequest({required this.parking_lot_id});

  Map<String, dynamic> toJson() => {'reservation_id': parking_lot_id};
}
