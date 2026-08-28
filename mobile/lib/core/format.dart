import 'package:intl/intl.dart';

// ---------------------------------------------------------------- JSON safety
// The backend omits null fields (Jackson non_null inclusion), so every read
// has to tolerate a missing key.

double? asDouble(Object? value) => value is num ? value.toDouble() : null;

int asInt(Object? value, [int fallback = 0]) =>
    value is num ? value.toInt() : fallback;

String asText(Object? value, [String fallback = '']) =>
    value == null ? fallback : value.toString();

DateTime? asDateTime(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

// ------------------------------------------------------------------ formatting

final NumberFormat _money = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 2,
);

final NumberFormat _compactMoney = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);

/// `1234.5` -> `₹1,234.50`
String money(num? value) => _money.format(value ?? 0);

/// `1234.5` -> `₹1,235` (for stat tiles where decimals are noise)
String moneyShort(num? value) => _compactMoney.format(value ?? 0);

/// `2026-08-25` -> `25 Aug 2026`
String dateLabel(String? isoDate) {
  final date = asDateTime(isoDate);
  return date == null ? '-' : DateFormat('d MMM yyyy').format(date);
}

/// `2026-08-25` -> `Tue, 25 Aug`
String dayLabel(DateTime date) => DateFormat('EEE, d MMM').format(date);

/// `2026-08-25` in API wire format.
String isoDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

/// `18:00:00` -> `06:00 PM`
String timeLabel(String? wireTime) {
  if (wireTime == null || wireTime.length < 4) return '-';
  final parts = wireTime.split(':');
  final hour = int.tryParse(parts[0]) ?? 0;
  final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  return DateFormat('hh:mm a').format(DateTime(2000, 1, 1, hour, minute));
}

/// `TimeOfDay`-ish pair -> `18:00` in API wire format.
String isoTime(int hour, int minute) =>
    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

/// `2026-08-25T19:49:32` -> `25 Aug 2026, 07:49 PM`
String dateTimeLabel(DateTime? value) =>
    value == null ? '-' : DateFormat('d MMM yyyy, hh:mm a').format(value);

/// `OUT_OF_SERVICE` -> `Out of service`
String prettyEnum(String? value) {
  if (value == null || value.isEmpty) return '-';
  final words = value.toLowerCase().replaceAll('_', ' ');
  return words[0].toUpperCase() + words.substring(1);
}

/// Duration between two wire times, e.g. `1h 30m`.
String durationLabel(String? start, String? end) {
  final minutes = minutesBetween(start, end);
  if (minutes <= 0) return '-';
  final hours = minutes ~/ 60;
  final mins = minutes % 60;
  if (hours == 0) return '${mins}m';
  return mins == 0 ? '${hours}h' : '${hours}h ${mins}m';
}

int minutesBetween(String? start, String? end) {
  final s = _toMinutes(start);
  final e = _toMinutes(end);
  if (s == null || e == null) return 0;
  return e - s;
}

int? _toMinutes(String? wireTime) {
  if (wireTime == null) return null;
  final parts = wireTime.split(':');
  if (parts.length < 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  return hour * 60 + minute;
}
