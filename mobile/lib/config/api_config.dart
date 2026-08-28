import 'package:flutter/foundation.dart';

/// Single place to point the app at a backend.
///
/// Change [hostOverride] to a LAN IP (e.g. `192.168.1.7`) when running on a
/// physical phone, and everything else follows automatically.
class ApiConfig {
  ApiConfig._();

  /// While true the app answers every request from [MockBackend] - it runs with
  /// no server, no database and no network. Flip to false to hit the real
  /// Spring Boot API at [baseUrl] instead; nothing else has to change.
  static const bool useMockData = true;

  /// Set this to your machine's LAN IP to test from a real device.
  static const String? hostOverride = null;

  static const int port = 8080;

  static String get baseUrl => '${_host()}:$port/api';

  static String _host() {
    if (hostOverride != null) return 'http://$hostOverride';

    // The Android emulator reaches the host machine through 10.0.2.2,
    // never through localhost.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2';
    }
    return 'http://localhost';
  }
}
