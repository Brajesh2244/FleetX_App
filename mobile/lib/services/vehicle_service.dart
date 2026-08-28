import '../core/api_client.dart';
import '../models/vehicle.dart';

class VehicleService {
  VehicleService._();

  static final ApiClient _api = ApiClient.instance;

  static Future<List<Vehicle>> list() async {
    final data = await _api.get('/vehicles') as List<dynamic>;
    return data.map((e) => Vehicle.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<Vehicle> get(int id) async {
    final data = await _api.get('/vehicles/$id') as Map<String, dynamic>;
    return Vehicle.fromJson(data);
  }

  static Future<Vehicle> create(Map<String, dynamic> body) async {
    final data = await _api.post('/vehicles', body) as Map<String, dynamic>;
    return Vehicle.fromJson(data);
  }

  static Future<Vehicle> update(int id, Map<String, dynamic> body) async {
    final data = await _api.put('/vehicles/$id', body) as Map<String, dynamic>;
    return Vehicle.fromJson(data);
  }

  static Future<void> delete(int id) => _api.delete('/vehicles/$id');

  /// Builds the request body the backend expects, dropping blank optionals.
  static Map<String, dynamic> body({
    required String vehicleNumber,
    required String vehicleType,
    String? driverName,
    String? driverContact,
    double? batteryCapacity,
    double? currentRange,
    String? status,
  }) {
    final map = <String, dynamic>{
      'vehicleNumber': vehicleNumber.trim().toUpperCase(),
      'vehicleType': vehicleType,
    };
    if (driverName != null && driverName.trim().isNotEmpty) {
      map['driverName'] = driverName.trim();
    }
    if (driverContact != null && driverContact.trim().isNotEmpty) {
      map['driverContact'] = driverContact.trim();
    }
    if (batteryCapacity != null) map['batteryCapacity'] = batteryCapacity;
    if (currentRange != null) map['currentRange'] = currentRange;
    if (status != null) map['status'] = status;
    return map;
  }
}
