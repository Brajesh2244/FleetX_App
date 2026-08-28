import '../core/format.dart';

class ParkingSlot {
  ParkingSlot({
    required this.id,
    required this.slotNumber,
    required this.status,
    this.stationId,
    this.stationName,
  });

  final int id;
  final String slotNumber;
  final String status;
  final int? stationId;
  final String? stationName;

  bool get isFree => status.toUpperCase() == 'AVAILABLE';

  factory ParkingSlot.fromJson(Map<String, dynamic> json) => ParkingSlot(
        id: asInt(json['id']),
        slotNumber: asText(json['slotNumber']),
        status: asText(json['status'], 'AVAILABLE'),
        stationId: json['stationId'] == null ? null : asInt(json['stationId']),
        stationName: json['stationName'] as String?,
      );
}
