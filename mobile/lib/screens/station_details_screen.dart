import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/format.dart';
import '../models/parking_slot.dart';
import '../models/station.dart';
import '../services/station_service.dart';
import '../widgets/common.dart';
import '../widgets/map_preview.dart';
import 'charger_selection_screen.dart';
import 'parking_screen.dart';

/// Station overview: chargers, parking, hours, and the entry to booking.
class StationDetailsScreen extends StatefulWidget {
  const StationDetailsScreen({super.key, required this.stationId});

  final int stationId;

  @override
  State<StationDetailsScreen> createState() => _StationDetailsScreenState();
}

class _StationDetailsScreenState extends State<StationDetailsScreen> {
  final GlobalKey<AsyncViewState<(Station, List<ParkingSlot>)>> _viewKey =
      GlobalKey();

  Future<(Station, List<ParkingSlot>)> _load() async {
    final results = await Future.wait([
      StationService.get(widget.stationId),
      ParkingService.list(stationId: widget.stationId),
    ]);
    return (results[0] as Station, results[1] as List<ParkingSlot>);
  }

  Future<void> _startBooking(Station station) async {
    final booked = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ChargerSelectionScreen(station: station)),
    );
    if (booked == true && mounted) {
      await _viewKey.currentState?.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Station details')),
      body: AsyncView<(Station, List<ParkingSlot>)>(
        key: _viewKey,
        load: _load,
        builder: (context, data, reload) {
          final (station, slots) = data;
          final bookable = station.chargers.where((c) => c.isBookable).length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _StationHeader(station: station),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: StatTile(
                      icon: Icons.bolt_rounded,
                      label: 'Chargers free',
                      value:
                          '${station.availableChargers}/${station.totalChargers}',
                      color: AppTheme.statusColor(
                        station.availableChargers == 0 ? 'FULL' : 'AVAILABLE',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatTile(
                      icon: Icons.local_parking_rounded,
                      label: 'Parking free',
                      value:
                          '${station.availableParkingSlots}/${station.totalParkingSlots}',
                      color: AppTheme.statusColor(
                        station.availableParkingSlots == 0 ? 'FULL' : 'AVAILABLE',
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ParkingScreen(station: station),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              const SectionHeader(title: 'Chargers'),
              if (station.chargers.isEmpty)
                const Card(
                  child: EmptyState(
                    icon: Icons.bolt_rounded,
                    title: 'No chargers listed',
                    message: 'This station has no chargers configured yet.',
                  ),
                )
              else
                ...station.chargers.map(
                  (charger) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ChargerTile(charger: charger),
                  ),
                ),
              const SizedBox(height: 22),

              SectionHeader(
                title: 'Parking slots',
                actionLabel: 'View all',
                onAction: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ParkingScreen(station: station),
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: slots.isEmpty
                      ? const Text(
                          'No parking slots at this station.',
                          style: TextStyle(color: AppTheme.neutral),
                        )
                      : Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: slots.map((s) => SlotChip(slot: s)).toList(),
                        ),
                ),
              ),
              const SizedBox(height: 22),

              if (station.latitude != null) ...[
                const SectionHeader(title: 'Location'),
                MapPreview(
                  stations: [station],
                  selectedId: station.id,
                  height: 180,
                ),
                const SizedBox(height: 8),
                Text(
                  'Lat ${station.latitude!.toStringAsFixed(4)}, '
                  'Lng ${station.longitude!.toStringAsFixed(4)}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.neutral),
                ),
                const SizedBox(height: 22),
              ],

              FilledButton.icon(
                onPressed: bookable == 0 ? null : () => _startBooking(station),
                icon: const Icon(Icons.event_available_rounded),
                label: Text(
                  bookable == 0 ? 'No chargers in service' : 'Book a charger',
                ),
              ),
              if (station.availableChargers == 0 && bookable > 0) ...[
                const SizedBox(height: 10),
                const Text(
                  'All chargers are busy right now - you can still reserve a '
                  'free time slot.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: AppTheme.neutral),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _StationHeader extends StatelessWidget {
  const _StationHeader({required this.station});

  final Station station;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    station.name,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                StatusChip(label: prettyEnum(station.status).toUpperCase()),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.place_outlined, size: 16, color: AppTheme.neutral),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    station.address,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.neutral,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            Row(
              children: [
                Expanded(
                  child: _HeaderStat(
                    icon: Icons.near_me_rounded,
                    label: 'Distance',
                    value: station.distanceLabel,
                  ),
                ),
                Expanded(
                  child: _HeaderStat(
                    icon: Icons.star_rounded,
                    label: 'Rating',
                    value: station.rating?.toStringAsFixed(1) ?? '-',
                    color: const Color(0xFFF59E0B),
                  ),
                ),
                Expanded(
                  child: _HeaderStat(
                    icon: Icons.access_time_rounded,
                    label: 'Open',
                    value: station.operatingHours ?? '24 x 7',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color ?? AppTheme.neutral),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11.5, color: AppTheme.neutral),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

/// Read-only charger row. The booking flow uses a selectable variant.
class ChargerTile extends StatelessWidget {
  const ChargerTile({
    super.key,
    required this.charger,
    this.selected = false,
    this.onTap,
  });

  final Charger charger;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tint = AppTheme.statusColor(charger.status);

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? AppTheme.primary : const Color(0xFFE2E8F0),
          width: selected ? 1.8 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.bolt_rounded, color: tint, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${charger.code} · ${charger.type.replaceAll('_', ' ')}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${charger.power.toStringAsFixed(charger.power % 1 == 0 ? 0 : 1)} kW · '
                      '${money(charger.pricePerKwh)}/kWh',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.neutral,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusChip(label: prettyEnum(charger.status).toUpperCase()),
                  if (selected) ...[
                    const SizedBox(height: 6),
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small parking slot pill, colour-coded by status.
class SlotChip extends StatelessWidget {
  const SlotChip({super.key, required this.slot, this.selected = false, this.onTap});

  final ParkingSlot slot;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tint = AppTheme.statusColor(slot.status);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? tint : tint.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? tint : tint.withValues(alpha: 0.35),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_parking_rounded,
              size: 15,
              color: selected ? Colors.white : tint,
            ),
            const SizedBox(width: 6),
            Text(
              slot.slotNumber,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : tint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
