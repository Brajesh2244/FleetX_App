import '../core/api_client.dart';
import '../models/booking.dart';
import '../models/payment.dart';

class BookingService {
  BookingService._();

  static final ApiClient _api = ApiClient.instance;

  /// The core flow. The backend rejects overlapping charger/slot times with 409.
  static Future<Booking> create({
    required int vehicleId,
    required int stationId,
    required int chargerId,
    int? parkingSlotId,
    bool autoAssignParking = false,
    required String bookingDate,
    required String startTime,
    required String endTime,
  }) async {
    final data = await _api.post('/bookings', {
      'vehicleId': vehicleId,
      'stationId': stationId,
      'chargerId': chargerId,
      'parkingSlotId': ?parkingSlotId,
      'autoAssignParking': autoAssignParking,
      'bookingDate': bookingDate,
      'startTime': startTime,
      'endTime': endTime,
    }) as Map<String, dynamic>;
    return Booking.fromJson(data);
  }

  static Future<List<Booking>> list() async {
    final data = await _api.get('/bookings') as List<dynamic>;
    return data.map((e) => Booking.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Null when the driver has nothing upcoming.
  static Future<Booking?> active() async {
    final data = await _api.get('/bookings/active');
    return data == null ? null : Booking.fromJson(data as Map<String, dynamic>);
  }

  static Future<Booking> get(int id) async {
    final data = await _api.get('/bookings/$id') as Map<String, dynamic>;
    return Booking.fromJson(data);
  }

  static Future<Booking> cancel(int id) async {
    final data = await _api.put('/bookings/$id/cancel') as Map<String, dynamic>;
    return Booking.fromJson(data);
  }
}

class PaymentService {
  PaymentService._();

  static final ApiClient _api = ApiClient.instance;

  /// Simulated payment - always succeeds unless the wallet is short.
  static Future<Payment> pay({required int bookingId, required String method}) async {
    final data = await _api.post('/payments', {
      'bookingId': bookingId,
      'method': method,
    }) as Map<String, dynamic>;
    return Payment.fromJson(data);
  }

  static Future<Payment> get(int id) async {
    final data = await _api.get('/payments/$id') as Map<String, dynamic>;
    return Payment.fromJson(data);
  }
}
