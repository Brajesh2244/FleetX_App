import '../core/api_client.dart';
import '../core/auth_store.dart';
import '../core/pricing.dart';

/// In-memory stand-in for the FleetX backend.
///
/// [ApiClient] routes every request here while [ApiConfig.useMockData] is true,
/// so the demo runs with no server, no database and no network. The payload
/// shapes are identical to the real REST responses, which means the models,
/// services, widgets and screens are all unchanged - flipping the flag is the
/// only thing needed to talk to the live backend instead.
class MockBackend {
  MockBackend._() {
    _seed();
  }

  static final MockBackend instance = MockBackend._();

  /// Small delay so loading spinners actually appear in the demo.
  static const Duration latency = Duration(milliseconds: 280);

  static const Set<String> _liveStatuses = {'PENDING', 'CONFIRMED'};

  final List<Map<String, dynamic>> _users = [];
  final List<Map<String, dynamic>> _vehicles = [];
  final List<Map<String, dynamic>> _stations = [];
  final List<Map<String, dynamic>> _chargers = [];
  final List<Map<String, dynamic>> _slots = [];
  final List<Map<String, dynamic>> _bookings = [];
  final List<Map<String, dynamic>> _transactions = [];
  final Map<int, double> _wallets = {};

  int _ids = 0;
  int _currentUserId = 1;

  int get _nextId => ++_ids;

  // ---------------------------------------------------------------- dispatch

  /// Routes `method path` to a handler. Unknown routes throw a 404 so a typo
  /// surfaces the same way it would against the real API.
  Future<dynamic> handle(
    String method,
    String path,
    Object? body,
    Map<String, dynamic>? query,
  ) async {
    await Future<void>.delayed(latency);
    _syncSession();

    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    final payload = body is Map<String, dynamic> ? body : const <String, dynamic>{};
    final route = '$method ${segments.join('/')}';

    switch (route) {
      case 'GET health':
        return {'message': 'FleetX mock backend is running'};

      case 'POST auth/login':
        return _login(payload);
      case 'POST auth/register':
        return _register(payload);
      case 'GET auth/me':
        return _publicUser(_requireCurrentUser());
      case 'POST auth/forgot-password':
        return {
          'message': 'If ${payload['email']} is registered, a reset link has '
              'been sent. (Simulated - no email leaves the app.)'
        };

      case 'GET vehicles':
        return _myVehicles();
      case 'POST vehicles':
        return _createVehicle(payload);

      case 'GET stations':
        return _listStations(query?['search'] as String?);

      case 'GET parking':
        return _listSlots(_asId(query?['stationId']));
      case 'POST parking/reserve':
        return _reserveSlot(payload);

      case 'GET bookings':
        return _myBookings();
      case 'GET bookings/active':
        return _activeBooking();
      case 'POST bookings':
        return _createBooking(payload);

      case 'POST payments':
        return _pay(payload);

      case 'GET wallet':
        return _wallet();
      case 'POST wallet/recharge':
        return _recharge(payload);
      case 'GET wallet/transactions':
        return _myTransactions();

      case 'GET dashboard':
        return _dashboard();
    }

    // Routes with an id in the middle.
    if (segments.length >= 2) {
      final id = int.tryParse(segments[1]);
      if (id != null) {
        if (segments[0] == 'vehicles' && segments.length == 2) {
          if (method == 'GET') return _vehicleById(id);
          if (method == 'PUT') return _updateVehicle(id, payload);
          if (method == 'DELETE') return _deleteVehicle(id);
        }
        if (segments[0] == 'stations') {
          if (method == 'GET' && segments.length == 2) return _stationById(id);
          if (method == 'GET' && segments.length == 3 && segments[2] == 'chargers') {
            return _chargersOf(id);
          }
        }
        if (segments[0] == 'parking' &&
            method == 'POST' &&
            segments.length == 3 &&
            segments[2] == 'release') {
          return _releaseSlot(id);
        }
        if (segments[0] == 'bookings') {
          if (method == 'GET' && segments.length == 2) return _bookingById(id);
          if (method == 'PUT' && segments.length == 3 && segments[2] == 'cancel') {
            return _cancelBooking(id);
          }
        }
        if (segments[0] == 'payments' && method == 'GET' && segments.length == 2) {
          return _paymentOf(id);
        }
      }
    }

    throw ApiException(404, 'Mock backend has no route for $method /$path');
  }

  // -------------------------------------------------------------------- auth

  Map<String, dynamic> _login(Map<String, dynamic> body) {
    final email = (body['email'] as String? ?? '').trim().toLowerCase();
    final password = body['password'] as String? ?? '';

    final user = _users.cast<Map<String, dynamic>?>().firstWhere(
          (u) => (u!['email'] as String).toLowerCase() == email,
          orElse: () => null,
        );
    if (user == null || user['password'] != password) {
      throw ApiException(401, 'Invalid email or password');
    }

    _currentUserId = user['id'] as int;
    return _authResponse(user);
  }

  Map<String, dynamic> _register(Map<String, dynamic> body) {
    final email = (body['email'] as String? ?? '').trim();
    if (_users.any(
        (u) => (u['email'] as String).toLowerCase() == email.toLowerCase())) {
      throw ApiException(409, 'That email is already registered');
    }

    final user = {
      'id': _nextId,
      'name': (body['name'] as String? ?? '').trim(),
      'email': email,
      'phone': (body['phone'] as String? ?? '').trim(),
      'role': 'DRIVER',
      'active': true,
      'password': body['password'] as String? ?? '',
    };
    _users.add(user);

    // Matches the backend's signup bonus.
    _wallets[user['id'] as int] = 500;
    _transactions.add(_transaction(
      user['id'] as int,
      'CREDIT',
      500,
      'Welcome bonus (demo credit)',
    ));

    _currentUserId = user['id'] as int;
    return _authResponse(user);
  }

  Map<String, dynamic> _authResponse(Map<String, dynamic> user) => {
        'token': 'mock-jwt-${user['id']}',
        'tokenType': 'Bearer',
        'userId': user['id'],
        'name': user['name'],
        'email': user['email'],
        'phone': user['phone'],
        'role': user['role'],
      };

  Map<String, dynamic> _publicUser(Map<String, dynamic> user) => {
        'id': user['id'],
        'name': user['name'],
        'email': user['email'],
        'phone': user['phone'],
        'role': user['role'],
        'active': user['active'],
      };

  Map<String, dynamic> _requireCurrentUser() {
    for (final user in _users) {
      if (user['id'] == _currentUserId) return user;
    }
    throw ApiException(401, 'Session expired. Please sign in again.');
  }

  /// The store survives a page reload but this in-memory backend does not, so
  /// a restored token tells us which seeded user to act as.
  void _syncSession() {
    final token = AuthStore.instance.token;
    if (token == null || !token.startsWith('mock-jwt-')) return;
    final id = int.tryParse(token.substring('mock-jwt-'.length));
    if (id != null) _currentUserId = id;
  }

  // ---------------------------------------------------------------- vehicles

  List<Map<String, dynamic>> _myVehicles() =>
      _vehicles.where((v) => v['ownerId'] == _currentUserId).toList();

  Map<String, dynamic> _vehicleById(int id) {
    for (final v in _myVehicles()) {
      if (v['id'] == id) return v;
    }
    throw ApiException(404, 'Vehicle not found');
  }

  Map<String, dynamic> _createVehicle(Map<String, dynamic> body) {
    final user = _requireCurrentUser();
    final number = (body['vehicleNumber'] as String? ?? '').trim().toUpperCase();
    if (number.isEmpty) throw ApiException(400, 'Vehicle number is required');
    if (_vehicles.any((v) => v['vehicleNumber'] == number)) {
      throw ApiException(409, '$number is already registered');
    }

    final vehicle = <String, dynamic>{
      'id': _nextId,
      'vehicleNumber': number,
      'vehicleType': body['vehicleType'] ?? 'CAR',
      'driverName': _blankTo(body['driverName'], user['name'] as String),
      'driverContact': _blankTo(body['driverContact'], user['phone'] as String),
      'batteryCapacity': body['batteryCapacity'],
      'currentRange': body['currentRange'],
      'status': body['status'] ?? 'ACTIVE',
      'ownerId': user['id'],
      'ownerName': user['name'],
    };
    _vehicles.add(vehicle);
    return vehicle;
  }

  Map<String, dynamic> _updateVehicle(int id, Map<String, dynamic> body) {
    final vehicle = _vehicleById(id);
    final number = (body['vehicleNumber'] as String? ?? '').trim().toUpperCase();
    if (number.isNotEmpty) vehicle['vehicleNumber'] = number;
    if (body['vehicleType'] != null) vehicle['vehicleType'] = body['vehicleType'];
    if (body['status'] != null) vehicle['status'] = body['status'];
    vehicle['driverName'] = _blankTo(body['driverName'], vehicle['driverName'] as String);
    vehicle['driverContact'] =
        _blankTo(body['driverContact'], vehicle['driverContact'] as String);
    vehicle['batteryCapacity'] = body['batteryCapacity'];
    vehicle['currentRange'] = body['currentRange'];
    return vehicle;
  }

  Map<String, dynamic> _deleteVehicle(int id) {
    final vehicle = _vehicleById(id);
    _vehicles.remove(vehicle);
    return {'message': '${vehicle['vehicleNumber']} removed'};
  }

  static String _blankTo(Object? value, String fallback) {
    final text = (value as String? ?? '').trim();
    return text.isEmpty ? fallback : text;
  }

  // ---------------------------------------------------------------- stations

  List<Map<String, dynamic>> _listStations(String? search) {
    final term = (search ?? '').trim().toLowerCase();
    final matches = _stations.where((s) {
      if (term.isEmpty) return true;
      return (s['name'] as String).toLowerCase().contains(term) ||
          (s['address'] as String).toLowerCase().contains(term);
    }).toList()
      ..sort((a, b) =>
          (a['distance'] as double).compareTo(b['distance'] as double));
    return matches.map(_stationResponse).toList();
  }

  Map<String, dynamic> _stationById(int id) {
    for (final s in _stations) {
      if (s['id'] == id) return _stationResponse(s);
    }
    throw ApiException(404, 'Station not found');
  }

  List<Map<String, dynamic>> _chargersOf(int stationId) =>
      _chargers.where((c) => c['stationId'] == stationId).toList();

  /// Mirrors the backend's cached availability rule.
  Map<String, dynamic> _stationResponse(Map<String, dynamic> station) {
    final chargers = _chargersOf(station['id'] as int);
    final slots = _slots.where((s) => s['stationId'] == station['id']).toList();

    final freeChargers =
        chargers.where((c) => c['status'] == 'AVAILABLE').length;
    final freeSlots = slots.where((s) => s['status'] == 'AVAILABLE').length;

    final String status;
    if (freeChargers == 0) {
      status = 'FULL';
    } else if (freeChargers * 2 <= chargers.length) {
      status = 'LIMITED';
    } else {
      status = 'AVAILABLE';
    }

    return {
      ...station,
      'status': status,
      'totalChargers': chargers.length,
      'availableChargers': freeChargers,
      'totalParkingSlots': slots.length,
      'availableParkingSlots': freeSlots,
      'chargers': chargers,
    };
  }

  Map<String, dynamic> _chargerById(int id) {
    for (final c in _chargers) {
      if (c['id'] == id) return c;
    }
    throw ApiException(404, 'Charger not found');
  }

  // ----------------------------------------------------------------- parking

  List<Map<String, dynamic>> _listSlots(int? stationId) => _slots
      .where((s) => stationId == null || s['stationId'] == stationId)
      .toList();

  Map<String, dynamic> _reserveSlot(Map<String, dynamic> body) {
    final stationId = _asId(body['stationId']);
    if (stationId == null) throw ApiException(400, 'Station id is required');

    final slotId = _asId(body['slotId']);
    if (slotId != null) {
      final slot = _slotById(slotId);
      if (slot['status'] != 'AVAILABLE') {
        throw ApiException(409, 'Slot ${slot['slotNumber']} is already taken');
      }
      slot['status'] = 'RESERVED';
      return slot;
    }

    for (final slot in _listSlots(stationId)) {
      if (slot['status'] == 'AVAILABLE') {
        slot['status'] = 'RESERVED';
        return slot;
      }
    }
    throw ApiException(409, 'No free parking slot at this station');
  }

  Map<String, dynamic> _releaseSlot(int slotId) {
    final slot = _slotById(slotId);
    slot['status'] = 'AVAILABLE';
    return slot;
  }

  Map<String, dynamic> _slotById(int id) {
    for (final s in _slots) {
      if (s['id'] == id) return s;
    }
    throw ApiException(404, 'Parking slot not found');
  }

  // ---------------------------------------------------------------- bookings

  List<Map<String, dynamic>> _myBookings() {
    final mine =
        _bookings.where((b) => b['userId'] == _currentUserId).toList()
          ..sort((a, b) =>
              (b['createdAt'] as String).compareTo(a['createdAt'] as String));
    return mine;
  }

  Map<String, dynamic> _bookingById(int id) {
    for (final b in _myBookings()) {
      if (b['id'] == id) return b;
    }
    throw ApiException(404, 'Booking not found');
  }

  /// The soonest booking that is still live, matching the dashboard's rule.
  Map<String, dynamic>? _activeBooking() {
    final live = _myBookings()
        .where((b) => _liveStatuses.contains(b['status']))
        .toList()
      ..sort((a, b) {
        final byDate =
            (a['bookingDate'] as String).compareTo(b['bookingDate'] as String);
        return byDate != 0
            ? byDate
            : (a['startTime'] as String).compareTo(b['startTime'] as String);
      });
    return live.isEmpty ? null : live.first;
  }

  Map<String, dynamic> _createBooking(Map<String, dynamic> body) {
    final user = _requireCurrentUser();
    final vehicle = _vehicleById(_asId(body['vehicleId']) ?? -1);
    final station = _rawStation(_asId(body['stationId']) ?? -1);
    final charger = _chargerById(_asId(body['chargerId']) ?? -1);

    if (charger['stationId'] != station['id']) {
      throw ApiException(400, 'That charger belongs to a different station');
    }
    if (charger['status'] == 'OUT_OF_SERVICE') {
      throw ApiException(409, 'Charger ${charger['code']} is out of service');
    }

    final date = body['bookingDate'] as String? ?? '';
    final start = body['startTime'] as String? ?? '';
    final end = body['endTime'] as String? ?? '';
    if (_minutes(end) <= _minutes(start)) {
      throw ApiException(400, 'End time must be after start time');
    }

    // The rule the whole booking flow exists to enforce.
    for (final existing in _bookings) {
      if (!_liveStatuses.contains(existing['status'])) continue;
      if (existing['bookingDate'] != date) continue;
      final overlaps = _minutes(start) < _minutes(existing['endTime'] as String) &&
          _minutes(end) > _minutes(existing['startTime'] as String);
      if (!overlaps) continue;

      if (existing['chargerId'] == charger['id']) {
        throw ApiException(
          409,
          'Charger ${charger['code']} is already booked between '
          '${existing['startTime']} and ${existing['endTime']}',
        );
      }
    }

    // Parking: an explicit slot, or the first free one.
    Map<String, dynamic>? slot;
    final requestedSlot = _asId(body['parkingSlotId']);
    if (requestedSlot != null) {
      slot = _slotById(requestedSlot);
      if (slot['status'] != 'AVAILABLE') {
        throw ApiException(409, 'Slot ${slot['slotNumber']} is already taken');
      }
    } else if (body['autoAssignParking'] == true) {
      for (final candidate in _listSlots(station['id'] as int)) {
        if (candidate['status'] == 'AVAILABLE') {
          slot = candidate;
          break;
        }
      }
      if (slot == null) {
        throw ApiException(409, 'No free parking slot at this station');
      }
    }
    if (slot != null) slot['status'] = 'RESERVED';

    final amount = estimate(
      pricePerKwh: (charger['pricePerKwh'] as num).toDouble(),
      power: (charger['power'] as num).toDouble(),
      startTime: start,
      endTime: end,
      batteryCapacity: (vehicle['batteryCapacity'] as num?)?.toDouble(),
      withParking: slot != null,
    );

    final reference = 'FLX-${_reference()}';
    final booking = <String, dynamic>{
      'id': _nextId,
      'reference': reference,
      'userId': user['id'],
      'userName': user['name'],
      'vehicleId': vehicle['id'],
      'vehicleNumber': vehicle['vehicleNumber'],
      'stationId': station['id'],
      'stationName': station['name'],
      'stationAddress': station['address'],
      'chargerId': charger['id'],
      'chargerCode': charger['code'],
      'chargerType': charger['type'],
      'chargerPower': charger['power'],
      'parkingSlotId': slot?['id'],
      'parkingSlotNumber': slot?['slotNumber'],
      'bookingDate': date,
      'startTime': start,
      'endTime': end,
      'amount': amount,
      'status': 'PENDING',
      'createdAt': DateTime.now().toIso8601String(),
      'qrData': reference,
      'paymentStatus': null,
      'transactionRef': null,
    };
    _bookings.add(booking);
    return booking;
  }

  Map<String, dynamic> _cancelBooking(int id) {
    final booking = _bookingById(id);
    if (booking['status'] == 'CANCELLED') {
      throw ApiException(409, 'That booking is already cancelled');
    }
    if (booking['status'] == 'COMPLETED') {
      throw ApiException(409, 'A completed booking cannot be cancelled');
    }

    booking['status'] = 'CANCELLED';

    final slotId = _asId(booking['parkingSlotId']);
    if (slotId != null) _slotById(slotId)['status'] = 'AVAILABLE';

    // Refund a successful payment back to the wallet.
    if (booking['paymentStatus'] == 'SUCCESS') {
      final amount = (booking['amount'] as num).toDouble();
      _wallets[_currentUserId] = _balance() + amount;
      _transactions.add(_transaction(
        _currentUserId,
        'CREDIT',
        amount,
        'Refund for ${booking['reference']}',
      ));
    }
    return booking;
  }

  /// Same formula the booking screen previews with, so the confirmed amount
  /// always matches the estimate the driver saw.
  static double estimate({
    required double pricePerKwh,
    required double power,
    required String startTime,
    required String endTime,
    double? batteryCapacity,
    required bool withParking,
  }) =>
      estimateAmount(
        pricePerKwh: pricePerKwh,
        power: power,
        startTime: startTime,
        endTime: endTime,
        batteryCapacity: batteryCapacity,
        withParking: withParking,
      );

  // ---------------------------------------------------------------- payments

  Map<String, dynamic> _pay(Map<String, dynamic> body) {
    final booking = _bookingById(_asId(body['bookingId']) ?? -1);
    final method = body['method'] as String? ?? 'WALLET';

    if (booking['status'] == 'CANCELLED') {
      throw ApiException(409, 'That booking was cancelled');
    }
    if (booking['paymentStatus'] == 'SUCCESS') {
      throw ApiException(409, 'This booking is already paid');
    }

    final amount = (booking['amount'] as num).toDouble();
    if (method == 'WALLET' && _balance() < amount) {
      throw ApiException(
        409,
        'Insufficient wallet balance. Recharge and try again.',
      );
    }

    if (method == 'WALLET') {
      _wallets[_currentUserId] = _balance() - amount;
      _transactions.add(_transaction(
        _currentUserId,
        'DEBIT',
        amount,
        'Charging booking ${booking['reference']}',
      ));
    }

    final transactionRef = 'TXN-${_reference(10)}';
    booking['status'] = 'CONFIRMED';
    booking['paymentStatus'] = 'SUCCESS';
    booking['transactionRef'] = transactionRef;

    return {
      'id': _nextId,
      'bookingId': booking['id'],
      'bookingReference': booking['reference'],
      'amount': amount,
      'method': method,
      'status': 'SUCCESS',
      'transactionRef': transactionRef,
      'paidAt': DateTime.now().toIso8601String(),
      'message': 'Payment Successful',
    };
  }

  Map<String, dynamic> _paymentOf(int bookingId) {
    final booking = _bookingById(bookingId);
    if (booking['paymentStatus'] != 'SUCCESS') {
      throw ApiException(404, 'No payment recorded for that booking');
    }
    return {
      'id': booking['id'],
      'bookingId': booking['id'],
      'bookingReference': booking['reference'],
      'amount': booking['amount'],
      'method': 'WALLET',
      'status': 'SUCCESS',
      'transactionRef': booking['transactionRef'],
      'paidAt': booking['createdAt'],
      'message': 'Payment Successful',
    };
  }

  // ------------------------------------------------------------------ wallet

  double _balance() => _wallets[_currentUserId] ?? 0;

  Map<String, dynamic> _wallet() => {
        'id': _currentUserId,
        'userId': _currentUserId,
        'balance': _balance(),
      };

  Map<String, dynamic> _recharge(Map<String, dynamic> body) {
    final amount = (body['amount'] as num?)?.toDouble() ?? 0;
    if (amount < 1) throw ApiException(400, 'Minimum recharge is 1');

    _wallets[_currentUserId] = _balance() + amount;
    _transactions.add(
      _transaction(_currentUserId, 'CREDIT', amount, 'Wallet recharge'),
    );
    return _wallet();
  }

  List<Map<String, dynamic>> _myTransactions() {
    final mine = _transactions
        .where((t) => t['userId'] == _currentUserId)
        .toList()
      ..sort((a, b) =>
          (b['createdAt'] as String).compareTo(a['createdAt'] as String));
    return mine;
  }

  Map<String, dynamic> _transaction(
    int userId,
    String type,
    double amount,
    String description,
  ) =>
      {
        'id': _nextId,
        'userId': userId,
        'type': type,
        'amount': amount,
        'description': description,
        'createdAt': DateTime.now().toIso8601String(),
      };

  // --------------------------------------------------------------- dashboard

  Map<String, dynamic> _dashboard() {
    final user = _requireCurrentUser();
    final vehicles = _myVehicles();
    final stations = _listStations(null);

    return {
      'userName': user['name'],
      'walletBalance': _balance(),
      'primaryVehicle': vehicles.isEmpty ? null : vehicles.first,
      'myVehicleCount': vehicles.length,
      'nearbyStations': stations.take(3).toList(),
      'availableChargers':
          _chargers.where((c) => c['status'] == 'AVAILABLE').length,
      'availableParkingSlots':
          _slots.where((s) => s['status'] == 'AVAILABLE').length,
      'activeBooking': _activeBooking(),
    };
  }

  // ------------------------------------------------------------------ helpers

  Map<String, dynamic> _rawStation(int id) {
    for (final s in _stations) {
      if (s['id'] == id) return s;
    }
    throw ApiException(404, 'Station not found');
  }

  static int? _asId(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static int _minutes(String wireTime) {
    final parts = wireTime.split(':');
    if (parts.length < 2) return 0;
    return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
  }

  /// Deterministic pseudo-reference - unique enough for a demo, no dart:math.
  String _reference([int length = 8]) {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ0123456789';
    var seed = DateTime.now().microsecondsSinceEpoch + _nextId * 7919;
    final buffer = StringBuffer();
    for (var i = 0; i < length; i++) {
      seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF;
      buffer.write(alphabet[seed % alphabet.length]);
    }
    return buffer.toString();
  }

  // -------------------------------------------------------------------- seed

  /// Same demo dataset the backend's DataSeeder writes, so both modes match.
  void _seed() {
    final ravi = _seedUser('Ravi Kumar', 'ravi@fleetx.com', '9876543210', 'driver123', 'DRIVER');
    final priya = _seedUser('Priya Sharma', 'priya@fleetx.com', '9812345678', 'driver123', 'DRIVER');
    final admin = _seedUser('FleetX Admin', 'admin@fleetx.com', '9800000000', 'admin123', 'ADMIN');

    _wallets[ravi] = 2500;
    _wallets[priya] = 1200;
    _wallets[admin] = 0;
    _transactions
      ..add(_transaction(ravi, 'CREDIT', 2500, 'Opening balance (demo credit)'))
      ..add(_transaction(priya, 'CREDIT', 1200, 'Opening balance (demo credit)'));

    final nexon = _seedVehicle(ravi, 'KA01AB1234', 'CAR', 40.5, 312, 'ACTIVE');
    final raviSuv = _seedVehicle(ravi, 'KA02CD5678', 'SUV', 60, 420, 'IDLE');
    _seedVehicle(ravi, 'KA03EF9012', 'BIKE', 3.2, 95, 'CHARGING');
    final tiago = _seedVehicle(priya, 'KA04GH3456', 'CAR', 30.2, 250, 'ACTIVE');
    _seedVehicle(priya, 'KA05IJ7890', 'TRUCK', 120, 180, 'MAINTENANCE');

    final koramangala = _seedStation('FleetX Hub Koramangala',
        '80 Feet Road, 4th Block, Koramangala, Bengaluru',
        12.9352, 77.6245, 1.2, 4.6, '24 x 7');
    _seedCharger(koramangala, 'C1', 'CCS2', 60, 18.50, 'AVAILABLE');
    _seedCharger(koramangala, 'C2', 'TYPE2', 22, 12.00, 'AVAILABLE');
    _seedCharger(koramangala, 'C3', 'AC_SLOW', 7.4, 9.50, 'AVAILABLE');
    _seedSlots(koramangala, 4, 0);

    final indiranagar = _seedStation('GreenCharge Indiranagar',
        '100 Feet Road, Indiranagar, Bengaluru',
        12.9784, 77.6408, 2.8, 4.3, '06:00 - 23:00');
    _seedCharger(indiranagar, 'C1', 'CCS2', 50, 17.00, 'AVAILABLE');
    _seedCharger(indiranagar, 'C2', 'CHADEMO', 50, 17.50, 'OCCUPIED');
    _seedCharger(indiranagar, 'C3', 'TYPE2', 22, 12.50, 'OCCUPIED');
    _seedSlots(indiranagar, 4, 1);

    final whitefield = _seedStation('VoltPark Whitefield',
        'ITPL Main Road, Whitefield, Bengaluru',
        12.9698, 77.7500, 5.4, 4.1, '24 x 7');
    _seedCharger(whitefield, 'C1', 'CCS2', 60, 19.00, 'OCCUPIED');
    _seedCharger(whitefield, 'C2', 'BHARAT_DC', 15, 11.00, 'OCCUPIED');
    _seedCharger(whitefield, 'C3', 'AC_SLOW', 7.4, 9.00, 'OUT_OF_SERVICE');
    _seedSlots(whitefield, 4, 3);

    final electronicCity = _seedStation('EcoCharge Electronic City',
        'Hosur Road, Phase 1, Electronic City, Bengaluru',
        12.8452, 77.6602, 8.9, 4.7, '05:00 - 00:00');
    _seedCharger(electronicCity, 'C1', 'CCS2', 120, 22.00, 'AVAILABLE');
    _seedCharger(electronicCity, 'C2', 'CCS2', 60, 18.00, 'AVAILABLE');
    _seedCharger(electronicCity, 'C3', 'TYPE2', 22, 12.00, 'OCCUPIED');
    _seedSlots(electronicCity, 4, 1);

    final mgRoad = _seedStation('PowerGrid MG Road',
        'MG Road, Near Trinity Metro, Bengaluru',
        12.9756, 77.6068, 3.6, 3.9, '24 x 7');
    _seedCharger(mgRoad, 'C1', 'TYPE2', 22, 13.00, 'AVAILABLE');
    _seedCharger(mgRoad, 'C2', 'CHADEMO', 50, 17.50, 'OCCUPIED');
    _seedCharger(mgRoad, 'C3', 'AC_SLOW', 7.4, 10.00, 'OUT_OF_SERVICE');
    _seedSlots(mgRoad, 4, 2);

    final today = DateTime.now();
    final todayIso = _isoDate(today);

    // Confirmed + paid: the dashboard's active booking.
    _seedBooking(ravi, nexon, koramangala, 'C1', 'P1', todayIso, '18:00:00',
        '19:30:00', 'CONFIRMED', paid: true);
    // Awaiting payment.
    _seedBooking(ravi, raviSuv, indiranagar,
        'C1', null, _isoDate(today.add(const Duration(days: 1))), '09:00:00',
        '10:00:00', 'PENDING');
    // Upcoming, already paid.
    _seedBooking(ravi, nexon, electronicCity, 'C1', 'P2',
        _isoDate(today.add(const Duration(days: 2))), '20:00:00', '21:00:00',
        'CONFIRMED', paid: true);
    // Finished.
    _seedBooking(priya, tiago, mgRoad, 'C1', null,
        _isoDate(today.subtract(const Duration(days: 1))), '14:00:00',
        '15:00:00', 'COMPLETED', paid: true);
    // Cancelled.
    _seedBooking(priya, tiago, whitefield, 'C1', null,
        _isoDate(today.subtract(const Duration(days: 3))), '11:00:00',
        '12:00:00', 'CANCELLED');
  }

  int _seedUser(String name, String email, String phone, String password, String role) {
    final id = _nextId;
    _users.add({
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'active': true,
      'password': password,
    });
    return id;
  }

  int _seedVehicle(int ownerId, String number, String type, double battery,
      double range, String status) {
    final owner = _users.firstWhere((u) => u['id'] == ownerId);
    final id = _nextId;
    _vehicles.add({
      'id': id,
      'vehicleNumber': number,
      'vehicleType': type,
      'driverName': owner['name'],
      'driverContact': owner['phone'],
      'batteryCapacity': battery,
      'currentRange': range,
      'status': status,
      'ownerId': ownerId,
      'ownerName': owner['name'],
    });
    return id;
  }

  int _seedStation(String name, String address, double lat, double lng,
      double distance, double rating, String hours) {
    final id = _nextId;
    _stations.add({
      'id': id,
      'name': name,
      'address': address,
      'latitude': lat,
      'longitude': lng,
      'distance': distance,
      'rating': rating,
      'operatingHours': hours,
    });
    return id;
  }

  void _seedCharger(int stationId, String code, String type, double power,
      double price, String status) {
    _chargers.add({
      'id': _nextId,
      'code': code,
      'type': type,
      'power': power,
      'pricePerKwh': price,
      'status': status,
      'stationId': stationId,
    });
  }

  void _seedSlots(int stationId, int count, int occupied) {
    final station = _rawStation(stationId);
    for (var i = 1; i <= count; i++) {
      _slots.add({
        'id': _nextId,
        'slotNumber': 'P$i',
        'status': i <= occupied ? 'OCCUPIED' : 'AVAILABLE',
        'stationId': stationId,
        'stationName': station['name'],
      });
    }
  }

  void _seedBooking(
    int userId,
    int vehicleId,
    int stationId,
    String chargerCode,
    String? slotNumber,
    String date,
    String start,
    String end,
    String status, {
    bool paid = false,
  }) {
    final user = _users.firstWhere((u) => u['id'] == userId);
    final station = _rawStation(stationId);
    final charger = _chargers.firstWhere(
      (c) => c['stationId'] == stationId && c['code'] == chargerCode,
    );
    final vehicle = _vehicles.firstWhere((v) => v['id'] == vehicleId);

    Map<String, dynamic>? slot;
    if (slotNumber != null) {
      for (final candidate in _listSlots(stationId)) {
        if (candidate['slotNumber'] == slotNumber) {
          slot = candidate;
          break;
        }
      }
      if (slot != null && status != 'CANCELLED') slot['status'] = 'RESERVED';
    }

    final amount = estimate(
      pricePerKwh: (charger['pricePerKwh'] as num).toDouble(),
      power: (charger['power'] as num).toDouble(),
      startTime: start,
      endTime: end,
      batteryCapacity: (vehicle['batteryCapacity'] as num?)?.toDouble(),
      withParking: slot != null,
    );

    final reference = 'FLX-${_reference()}';
    _bookings.add({
      'id': _nextId,
      'reference': reference,
      'userId': userId,
      'userName': user['name'],
      'vehicleId': vehicle['id'],
      'vehicleNumber': vehicle['vehicleNumber'],
      'stationId': stationId,
      'stationName': station['name'],
      'stationAddress': station['address'],
      'chargerId': charger['id'],
      'chargerCode': charger['code'],
      'chargerType': charger['type'],
      'chargerPower': charger['power'],
      'parkingSlotId': slot?['id'],
      'parkingSlotNumber': slot?['slotNumber'],
      'bookingDate': date,
      'startTime': start,
      'endTime': end,
      'amount': amount,
      'status': status,
      'createdAt': DateTime.now().toIso8601String(),
      'qrData': reference,
      'paymentStatus': paid ? 'SUCCESS' : null,
      'transactionRef': paid ? 'TXN-${_reference(10)}' : null,
    });

    if (paid) {
      _wallets[userId] = (_wallets[userId] ?? 0) - amount;
      _transactions.add(
        _transaction(userId, 'DEBIT', amount, 'Charging booking $reference'),
      );
    }
  }

  static String _isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
