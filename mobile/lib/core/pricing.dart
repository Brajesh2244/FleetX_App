import 'format.dart';

/// Flat fee added when a booking also reserves a parking slot.
const double parkingFee = 20.0;

/// Estimated cost of a charging session.
///
/// Energy is `power (kW) x hours`, capped at the vehicle's battery capacity so
/// a long slot on a fast charger cannot bill more than the battery can hold.
/// The booking screen calls this to preview the price and the backend applies
/// the same formula when the booking is created, so the two always agree.
double estimateAmount({
  required double pricePerKwh,
  required double power,
  required String startTime,
  required String endTime,
  double? batteryCapacity,
  bool withParking = false,
}) {
  final minutes = minutesBetween(startTime, endTime);
  if (minutes <= 0) return 0;

  final energyKwh = estimateEnergy(
    power: power,
    startTime: startTime,
    endTime: endTime,
    batteryCapacity: batteryCapacity,
  );

  final amount = pricePerKwh * energyKwh + (withParking ? parkingFee : 0);
  return double.parse(amount.toStringAsFixed(2));
}

/// Units the session is expected to draw, shown on the price breakdown.
double estimateEnergy({
  required double power,
  required String startTime,
  required String endTime,
  double? batteryCapacity,
}) {
  final minutes = minutesBetween(startTime, endTime);
  if (minutes <= 0) return 0;

  final raw = power * (minutes / 60.0);
  if (batteryCapacity != null && batteryCapacity > 0 && raw > batteryCapacity) {
    return batteryCapacity;
  }
  return raw;
}
