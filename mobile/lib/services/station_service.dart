import '../core/api_client.dart';
import '../models/parking_slot.dart';
import '../models/station.dart';

class StationService {
  StationService._();

  static final ApiClient _api = ApiClient.instance;

  static Future<List<Station>> list({String? search}) async {
    final data = await _api.get(
      '/stations',
      query: {'search': (search != null && search.isNotEmpty) ? search : null},
    ) as List<dynamic>;
    return data.map((e) => Station.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<Station> get(int id) async {
    final data = await _api.get('/stations/$id') as Map<String, dynamic>;
    return Station.fromJson(data);
  }

  static Future<List<Charger>> chargers(int stationId) async {
    final data = await _api.get('/stations/$stationId/chargers') as List<dynamic>;
    return data.map((e) => Charger.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Admin only.
  static Future<Station> create(Map<String, dynamic> body) async {
    final data = await _api.post('/stations', body) as Map<String, dynamic>;
    return Station.fromJson(data);
  }

  /// Admin only.
  static Future<Station> update(int id, Map<String, dynamic> body) async {
    final data = await _api.put('/stations/$id', body) as Map<String, dynamic>;
    return Station.fromJson(data);
  }
}

class ParkingService {
  ParkingService._();

  static final ApiClient _api = ApiClient.instance;

  static Future<List<ParkingSlot>> list({int? stationId}) async {
    final data =
        await _api.get('/parking', query: {'stationId': stationId}) as List<dynamic>;
    return data
        .map((e) => ParkingSlot.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Reserves [slotId], or the first free slot at the station when omitted.
  static Future<ParkingSlot> reserve({required int stationId, int? slotId}) async {
    final data = await _api.post('/parking/reserve', {
      'stationId': stationId,
      'slotId': ?slotId,
    }) as Map<String, dynamic>;
    return ParkingSlot.fromJson(data);
  }

  static Future<ParkingSlot> release(int slotId) async {
    final data =
        await _api.post('/parking/$slotId/release') as Map<String, dynamic>;
    return ParkingSlot.fromJson(data);
  }
}
