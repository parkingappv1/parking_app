class ParkingStatusModel {
  final String status_id;
  final String reservation_id;
  final String parking_lot_id;
  final String parking_lot_name;
  final String entry_status;
  final String exit_status;
  final String? entry_datetime;
  final String? exit_datetime;
  final String start_datetime;
  final String end_datetime;
  final DateTime? created_datetime;
  final DateTime? updated_datetime;

  ParkingStatusModel({
    required this.status_id,
    required this.reservation_id,
    required this.parking_lot_id,
    required this.parking_lot_name,
    required this.entry_status,
    required this.exit_status,
    this.entry_datetime,
    this.exit_datetime,
    required this.start_datetime,
    required this.end_datetime,
    this.created_datetime,
    this.updated_datetime,
  });

  // Add getters for snake_case property access

  factory ParkingStatusModel.fromJson(Map<String, dynamic> json) {
    return ParkingStatusModel(
      status_id: json['status_id'],
      reservation_id: json['reservation_id'],
      parking_lot_id: json['parking_lot_id'],
      parking_lot_name: json['parking_lot_name'],
      entry_status: json['entry_status'],
      exit_status: json['exit_status'],
      entry_datetime: json['entry_datetime'],
      exit_datetime: json['exit_datetime'],
      start_datetime: json['start_datetime'],
      end_datetime: json['end_datetime'],
      created_datetime: DateTime.parse(json['created_datetime']),
      updated_datetime: DateTime.parse(json['updated_datetime']),
    );
  }
}

/// 入出庫状況のリクエスト
class ParkingStausRequest {
  final String? user_id;
  final String? status;

  ParkingStausRequest({required this.user_id, required this.status});

  Map<String, dynamic> toJson() => {'user_id': user_id, 'status': status};
}

/// 入出庫状況更新のリクエスト
class UpdateParkingStausRequest {
  final String? status_id;
  final String? reservation_id;
  final String? checkInOutKbn;

  UpdateParkingStausRequest({
    required this.status_id,
    required this.reservation_id,
    required this.checkInOutKbn,
  });

  Map<String, dynamic> toJson() => {
    'status_id': status_id,
    'reservation_id': reservation_id,
    'check_inout_kbn': checkInOutKbn,
  };
}
