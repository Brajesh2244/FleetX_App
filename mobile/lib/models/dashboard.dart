import '../core/format.dart';
import 'booking.dart';
import 'station.dart';
import 'vehicle.dart';

/// Everything the home dashboard needs, from a single `/api/dashboard` call.
class DashboardData {
  DashboardData({
    required this.userName,
    required this.walletBalance,
    this.primaryVehicle,
    required this.myVehicleCount,
    required this.nearbyStations,
    required this.availableChargers,
    required this.availableParkingSlots,
    this.activeBooking,
  });

  final String userName;
  final double walletBalance;
  final Vehicle? primaryVehicle;
  final int myVehicleCount;
  final List<Station> nearbyStations;
  final int availableChargers;
  final int availableParkingSlots;
  final Booking? activeBooking;

  factory DashboardData.fromJson(Map<String, dynamic> json) => DashboardData(
        userName: asText(json['userName'], 'Driver'),
        walletBalance: asDouble(json['walletBalance']) ?? 0,
        primaryVehicle: json['primaryVehicle'] == null
            ? null
            : Vehicle.fromJson(json['primaryVehicle'] as Map<String, dynamic>),
        myVehicleCount: asInt(json['myVehicleCount']),
        nearbyStations: (json['nearbyStations'] as List<dynamic>? ?? const [])
            .map((e) => Station.fromJson(e as Map<String, dynamic>))
            .toList(),
        availableChargers: asInt(json['availableChargers']),
        availableParkingSlots: asInt(json['availableParkingSlots']),
        activeBooking: json['activeBooking'] == null
            ? null
            : Booking.fromJson(json['activeBooking'] as Map<String, dynamic>),
      );
}

class AdminStats {
  AdminStats({
    required this.totalUsers,
    required this.totalVehicles,
    required this.totalStations,
    required this.totalChargers,
    required this.totalBookings,
    required this.activeBookings,
    required this.revenue,
  });

  final int totalUsers;
  final int totalVehicles;
  final int totalStations;
  final int totalChargers;
  final int totalBookings;
  final int activeBookings;
  final double revenue;

  factory AdminStats.fromJson(Map<String, dynamic> json) => AdminStats(
        totalUsers: asInt(json['totalUsers']),
        totalVehicles: asInt(json['totalVehicles']),
        totalStations: asInt(json['totalStations']),
        totalChargers: asInt(json['totalChargers']),
        totalBookings: asInt(json['totalBookings']),
        activeBookings: asInt(json['activeBookings']),
        revenue: asDouble(json['revenue']) ?? 0,
      );
}
