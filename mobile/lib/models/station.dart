import '../core/format.dart';

class Charger {
  Charger({
    required this.id,
    required this.code,
    required this.type,
    required this.power,
    required this.pricePerKwh,
    required this.status,
    this.stationId,
  });

  final int id;
  final String code;
  final String type;
  final double power;
  final double pricePerKwh;
  final String status;
  final int? stationId;

  bool get isBookable => status.toUpperCase() != 'OUT_OF_SERVICE';

  factory Charger.fromJson(Map<String, dynamic> json) => Charger(
        id: asInt(json['id']),
        code: asText(json['code']),
        type: asText(json['type']),
        power: asDouble(json['power']) ?? 0,
        pricePerKwh: asDouble(json['pricePerKwh']) ?? 0,
        status: asText(json['status'], 'AVAILABLE'),
        stationId: json['stationId'] == null ? null : asInt(json['stationId']),
      );
}

class Station {
  Station({
    required this.id,
    required this.name,
    required this.address,
    this.latitude,
    this.longitude,
    this.distance,
    this.rating,
    this.operatingHours,
    required this.status,
    required this.totalChargers,
    required this.availableChargers,
    required this.totalParkingSlots,
    required this.availableParkingSlots,
    this.chargers = const [],
  });

  final int id;
  final String name;
  final String address;
  final double? latitude;
  final double? longitude;
  final double? distance;
  final double? rating;
  final String? operatingHours;
  final String status;
  final int totalChargers;
  final int availableChargers;
  final int totalParkingSlots;
  final int availableParkingSlots;
  final List<Charger> chargers;

  String get distanceLabel =>
      distance == null ? '-' : '${distance!.toStringAsFixed(1)} km';

  factory Station.fromJson(Map<String, dynamic> json) => Station(
        id: asInt(json['id']),
        name: asText(json['name']),
        address: asText(json['address']),
        latitude: asDouble(json['latitude']),
        longitude: asDouble(json['longitude']),
        distance: asDouble(json['distance']),
        rating: asDouble(json['rating']),
        operatingHours: json['operatingHours'] as String?,
        status: asText(json['status'], 'AVAILABLE'),
        totalChargers: asInt(json['totalChargers']),
        availableChargers: asInt(json['availableChargers']),
        totalParkingSlots: asInt(json['totalParkingSlots']),
        availableParkingSlots: asInt(json['availableParkingSlots']),
        chargers: (json['chargers'] as List<dynamic>? ?? const [])
            .map((e) => Charger.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
