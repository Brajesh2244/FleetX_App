import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fleetx_mobile/core/api_client.dart';
import 'package:fleetx_mobile/core/auth_store.dart';
import 'package:fleetx_mobile/core/format.dart';
import 'package:fleetx_mobile/models/booking.dart';
import 'package:fleetx_mobile/models/station.dart';
import 'package:fleetx_mobile/services/auth_service.dart';
import 'package:fleetx_mobile/services/booking_service.dart';
import 'package:fleetx_mobile/services/dashboard_service.dart';
import 'package:fleetx_mobile/services/station_service.dart';
import 'package:fleetx_mobile/services/vehicle_service.dart';
import 'package:fleetx_mobile/services/wallet_service.dart';

/// Walks the demo path the way the screens do:
/// Login -> Dashboard -> Stations -> Booking -> Payment -> QR -> History.
///
/// Each step calls the same service the matching screen calls, so a green run
/// means the wiring behind those screens works end to end.
void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  test('demo flow: login -> dashboard -> stations -> booking -> payment -> QR -> history',
      () async {
    // 1. Login (login_screen.dart)
    final user = await AuthService.login('ravi@fleetx.com', 'driver123');
    expect(user.email, 'ravi@fleetx.com');
    expect(AuthStore.instance.isLoggedIn, isTrue);
    expect(AuthStore.instance.token, startsWith('mock-jwt-'));

    // 2. Dashboard (dashboard_screen.dart)
    final home = await DashboardService.load();
    expect(home.nearbyStations, isNotEmpty);
    expect(home.myVehicleCount, greaterThan(0));
    expect(home.walletBalance, greaterThan(0));
    expect(home.activeBooking, isNotNull, reason: 'seed has a booking for today');

    // 3. Stations (station_list_screen.dart -> station_details_screen.dart)
    final stations = await StationService.list();
    expect(stations.length, greaterThanOrEqualTo(5));
    expect(await StationService.list(search: 'koramangala'), hasLength(1));

    final station = await StationService.get(stations.first.id);
    final chargers = await StationService.chargers(station.id);
    final slots = await ParkingService.list(stationId: station.id);
    expect(chargers, isNotEmpty);
    expect(slots, isNotEmpty);

    final Charger charger =
        chargers.firstWhere((c) => c.status.toUpperCase() == 'AVAILABLE');

    // 4. Booking (booking_screen.dart) - a free window so no 409 overlap
    final vehicles = await VehicleService.list();
    expect(vehicles, isNotEmpty);
    final date = isoDate(DateTime.now().add(const Duration(days: 5)));

    final booking = await BookingService.create(
      vehicleId: vehicles.first.id,
      stationId: station.id,
      chargerId: charger.id,
      autoAssignParking: true,
      bookingDate: date,
      startTime: '10:00',
      endTime: '11:00',
    );
    expect(booking.status, 'PENDING');
    expect(booking.needsPayment, isTrue);
    expect(booking.amount, greaterThan(0));
    expect(booking.hasParking, isTrue);
    expect(booking.reference, isNotEmpty);

    // The same charger and window is now taken - the 409 the UI surfaces.
    await expectLater(
      BookingService.create(
        vehicleId: vehicles.first.id,
        stationId: station.id,
        chargerId: charger.id,
        bookingDate: date,
        startTime: '10:30',
        endTime: '11:30',
      ),
      throwsA(isA<ApiException>()),
    );

    // 5. Payment (payment_screen.dart)
    final before = await WalletService.get();
    final payment =
        await PaymentService.pay(bookingId: booking.id, method: 'WALLET');
    expect(payment.isSuccess, isTrue);
    expect(payment.amount, booking.amount);

    final after = await WalletService.get();
    expect(after.balance, closeTo(before.balance - booking.amount, 0.01));
    expect(await WalletService.transactions(), isNotEmpty);

    // 6. QR pass (booking_success_screen.dart / booking_detail_screen.dart)
    final paid = await BookingService.get(booking.id);
    expect(paid.status, 'CONFIRMED');
    expect(paid.isPaid, isTrue);
    expect(paid.transactionRef, isNotNull);
    expect(paid.qrData, isNotEmpty);

    // 7. History (booking_history_screen.dart)
    final history = await BookingService.list();
    expect(history.map((b) => b.id), contains(booking.id));
    expect(history.any((b) => b.status == 'COMPLETED'), isTrue);

    // 8. Cancel refunds to the wallet (booking_detail_screen.dart)
    final Booking cancelled = await BookingService.cancel(booking.id);
    expect(cancelled.status, 'CANCELLED');
    final refunded = await WalletService.get();
    expect(refunded.balance, closeTo(before.balance, 0.01));
  });

  test('register grants the welcome bonus and signs the new driver in', () async {
    final user = await AuthService.register(
      name: 'Demo Driver',
      email: 'demo.driver@fleetx.com',
      phone: '9800000001',
      password: 'demo123',
    );
    expect(user.email, 'demo.driver@fleetx.com');
    expect(AuthStore.instance.isLoggedIn, isTrue);

    final wallet = await WalletService.get();
    expect(wallet.balance, 500);
    expect(await VehicleService.list(), isEmpty);
    expect(await BookingService.list(), isEmpty);

    await AuthService.logout();
    expect(AuthStore.instance.isLoggedIn, isFalse);
  });
}
