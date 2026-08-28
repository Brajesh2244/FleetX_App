import '../core/format.dart';

class Vehicle {
  Vehicle({
    required this.id,
    required this.vehicleNumber,
    required this.vehicleType,
    this.driverName,
    this.driverContact,
    this.batteryCapacity,
    this.currentRange,
    required this.status,
    this.ownerId,
    this.ownerName,
  });

  final int id;
  final String vehicleNumber;
  final String vehicleType;
  final String? driverName;
  final String? driverContact;
  final double? batteryCapacity;
  final double? currentRange;
  final String status;
  final int? ownerId;
  final String? ownerName;

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        id: asInt(json['id']),
        vehicleNumber: asText(json['vehicleNumber']),
        vehicleType: asText(json['vehicleType'], 'CAR'),
        driverName: json['driverName'] as String?,
        driverContact: json['driverContact'] as String?,
        batteryCapacity: asDouble(json['batteryCapacity']),
        currentRange: asDouble(json['currentRange']),
        status: asText(json['status'], 'ACTIVE'),
        ownerId: json['ownerId'] == null ? null : asInt(json['ownerId']),
        ownerName: json['ownerName'] as String?,
      );

  static const List<String> types = [
    'CAR',
    'SUV',
    'BIKE',
    'AUTO',
    'BUS',
    'TRUCK',
  ];

  static const List<String> statuses = [
    'ACTIVE',
    'IDLE',
    'CHARGING',
    'MAINTENANCE',
  ];
}
