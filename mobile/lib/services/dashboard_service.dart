import '../core/api_client.dart';
import '../models/app_user.dart';
import '../models/booking.dart';
import '../models/dashboard.dart';
import '../models/station.dart';
import '../models/vehicle.dart';

class DashboardService {
  DashboardService._();

  /// One call for the whole home screen.
  static Future<DashboardData> load() async {
    final data = await ApiClient.instance.get('/dashboard') as Map<String, dynamic>;
    return DashboardData.fromJson(data);
  }
}

/// Everything behind `/api/admin` - requires an ADMIN token.
class AdminService {
  AdminService._();

  static final ApiClient _api = ApiClient.instance;

  static Future<AdminStats> stats() async {
    final data = await _api.get('/admin/stats') as Map<String, dynamic>;
    return AdminStats.fromJson(data);
  }

  static Future<List<AppUser>> users() async {
    final data = await _api.get('/admin/users') as List<dynamic>;
    return data.map((e) => AppUser.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<Vehicle>> vehicles() async {
    final data = await _api.get('/admin/vehicles') as List<dynamic>;
    return data.map((e) => Vehicle.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<Station>> stations() async {
    final data = await _api.get('/admin/stations') as List<dynamic>;
    return data.map((e) => Station.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<Booking>> bookings() async {
    final data = await _api.get('/admin/bookings') as List<dynamic>;
    return data.map((e) => Booking.fromJson(e as Map<String, dynamic>)).toList();
  }
}
