import 'package:flutter/material.dart';

/// FleetX visual language: EV green primary, with a fixed traffic-light
/// palette for availability that the whole app shares.
class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFF00A06B);
  static const Color primaryDark = Color(0xFF00754E);
  static const Color accent = Color(0xFF0B7FD4);

  static const Color available = Color(0xFF16A34A);
  static const Color limited = Color(0xFFD97706);
  static const Color full = Color(0xFFDC2626);
  static const Color neutral = Color(0xFF64748B);

  static const Color surfaceMuted = Color(0xFFF1F5F9);

  /// Green / yellow / red for any AVAILABLE - LIMITED - FULL style status.
  static Color statusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'AVAILABLE':
      case 'CONFIRMED':
      case 'SUCCESS':
      case 'ACTIVE':
        return available;
      case 'LIMITED':
      case 'PENDING':
      case 'RESERVED':
      case 'CHARGING':
        return limited;
      case 'FULL':
      case 'OCCUPIED':
      case 'OUT_OF_SERVICE':
      case 'CANCELLED':
      case 'FAILED':
      case 'MAINTENANCE':
        return full;
      case 'COMPLETED':
        return accent;
      default:
        return neutral;
    }
  }

  static IconData vehicleIcon(String? type) {
    switch (type?.toUpperCase()) {
      case 'BIKE':
        return Icons.two_wheeler;
      case 'BUS':
        return Icons.directions_bus;
      case 'TRUCK':
        return Icons.local_shipping;
      case 'AUTO':
        return Icons.electric_rickshaw;
      case 'SUV':
        return Icons.airport_shuttle;
      default:
        return Icons.directions_car;
    }
  }

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF0F172A),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0F172A),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      chipTheme: const ChipThemeData(
        side: BorderSide.none,
        padding: EdgeInsets.symmetric(horizontal: 6),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFE2E8F0), thickness: 1),
    );
  }
}
