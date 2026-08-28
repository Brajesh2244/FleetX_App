import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/format.dart';
import '../models/booking.dart';
import '../models/station.dart';
import '../models/vehicle.dart';
import 'common.dart';

/// Station row used on the dashboard, the stations tab and the admin list.
class StationCard extends StatelessWidget {
  const StationCard({super.key, required this.station, this.onTap, this.compact = false});

  final Station station;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AppTheme.statusColor(station.status).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      Icons.ev_station_rounded,
                      color: AppTheme.statusColor(station.status),
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          station.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          station.address,
                          maxLines: compact ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppTheme.neutral,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusChip(label: prettyEnum(station.status).toUpperCase()),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 14,
                runSpacing: 6,
                children: [
                  _Meta(
                    icon: Icons.near_me_rounded,
                    text: station.distanceLabel,
                  ),
                  _Meta(
                    icon: Icons.star_rounded,
                    text: station.rating?.toStringAsFixed(1) ?? '-',
                    color: const Color(0xFFF59E0B),
                  ),
                  _Meta(
                    icon: Icons.bolt_rounded,
                    text: '${station.availableChargers}/${station.totalChargers} chargers',
                    color: AppTheme.statusColor(
                      station.availableChargers == 0 ? 'FULL' : 'AVAILABLE',
                    ),
                  ),
                  _Meta(
                    icon: Icons.local_parking_rounded,
                    text:
                        '${station.availableParkingSlots}/${station.totalParkingSlots} parking',
                    color: AppTheme.statusColor(
                      station.availableParkingSlots == 0 ? 'FULL' : 'AVAILABLE',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color ?? AppTheme.neutral),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: color ?? AppTheme.neutral,
          ),
        ),
      ],
    );
  }
}

/// Booking row used in history, the dashboard active card and admin lists.
class BookingCard extends StatelessWidget {
  const BookingCard({
    super.key,
    required this.booking,
    this.onTap,
    this.showDriver = false,
  });

  final Booking booking;
  final VoidCallback? onTap;
  final bool showDriver;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      booking.stationName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusChip(label: booking.status),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                booking.reference,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.neutral,
                  letterSpacing: 0.4,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 11),
                child: Divider(height: 1),
              ),
              Row(
                children: [
                  Expanded(
                    child: _Cell(
                      icon: Icons.calendar_today_rounded,
                      label: dateLabel(booking.bookingDate),
                    ),
                  ),
                  Expanded(
                    child: _Cell(
                      icon: Icons.schedule_rounded,
                      label: booking.slotLabel,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _Cell(
                      icon: Icons.electric_car_rounded,
                      label: showDriver && booking.userName != null
                          ? '${booking.vehicleNumber} · ${booking.userName}'
                          : booking.vehicleNumber,
                    ),
                  ),
                  Text(
                    money(booking.amount),
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                ],
              ),
              if (booking.needsPayment) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppTheme.limited.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 14, color: AppTheme.limited),
                      SizedBox(width: 6),
                      Text(
                        'Payment pending - tap to pay',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.limited,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.neutral),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12.8, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

/// Vehicle row used on the vehicles tab, the dashboard and the admin list.
class VehicleCard extends StatelessWidget {
  const VehicleCard({
    super.key,
    required this.vehicle,
    this.onTap,
    this.trailing,
    this.showOwner = false,
  });

  final Vehicle vehicle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showOwner;

  @override
  Widget build(BuildContext context) {
    final specs = <String>[
      if (vehicle.batteryCapacity != null)
        '${vehicle.batteryCapacity!.toStringAsFixed(1)} kWh',
      if (vehicle.currentRange != null)
        '${vehicle.currentRange!.toStringAsFixed(0)} km range',
    ];

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  AppTheme.vehicleIcon(vehicle.vehicleType),
                  color: AppTheme.primaryDark,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.vehicleNumber,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        prettyEnum(vehicle.vehicleType),
                        ...specs,
                        if (showOwner && vehicle.ownerName != null) vehicle.ownerName!,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, color: AppTheme.neutral),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing ?? StatusChip(label: vehicle.status),
            ],
          ),
        ),
      ),
    );
  }
}
