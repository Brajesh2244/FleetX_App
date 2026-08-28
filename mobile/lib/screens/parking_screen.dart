import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/parking_slot.dart';
import '../models/station.dart';
import '../services/station_service.dart';
import '../widgets/common.dart';
import 'station_details_screen.dart';

/// Parking availability for one station, with direct reserve / release.
class ParkingScreen extends StatefulWidget {
  const ParkingScreen({super.key, required this.station});

  final Station station;

  @override
  State<ParkingScreen> createState() => _ParkingScreenState();
}

class _ParkingScreenState extends State<ParkingScreen> {
  final GlobalKey<AsyncViewState<List<ParkingSlot>>> _viewKey = GlobalKey();

  bool _busy = false;

  Future<void> _act(ParkingSlot slot) async {
    if (_busy) return;
    setState(() => _busy = true);

    final released = slot.status.toUpperCase() != 'AVAILABLE';
    final ok = await guardVoid(
      context,
      () => released
          ? ParkingService.release(slot.id)
          : ParkingService.reserve(stationId: widget.station.id, slotId: slot.id),
    );

    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      showSnack(
        context,
        released
            ? 'Slot ${slot.slotNumber} released'
            : 'Slot ${slot.slotNumber} reserved',
      );
    }
    await _viewKey.currentState?.reload();
  }

  Future<void> _reserveAny() async {
    if (_busy) return;
    setState(() => _busy = true);

    final slot = await guard(
      context,
      () => ParkingService.reserve(stationId: widget.station.id),
    );

    if (!mounted) return;
    setState(() => _busy = false);
    if (slot != null) showSnack(context, 'Slot ${slot.slotNumber} reserved for you');
    await _viewKey.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Parking')),
      body: AsyncView<List<ParkingSlot>>(
        key: _viewKey,
        load: () => ParkingService.list(stationId: widget.station.id),
        builder: (context, slots, reload) {
          if (slots.isEmpty) {
            return ListView(
              children: const [
                EmptyState(
                  icon: Icons.local_parking_rounded,
                  title: 'No parking here',
                  message: 'This station has no parking slots configured.',
                ),
              ],
            );
          }

          final free = slots.where((s) => s.isFree).length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.station.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '$free of ${slots.length} slots free',
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          StatusChip(
                            label: free == 0
                                ? 'FULL'
                                : (free * 2 <= slots.length ? 'LIMITED' : 'AVAILABLE'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: slots.isEmpty ? 0 : free / slots.length,
                          minHeight: 8,
                          backgroundColor: AppTheme.surfaceMuted,
                          valueColor: AlwaysStoppedAnimation(
                            AppTheme.statusColor(free == 0 ? 'FULL' : 'AVAILABLE'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const SectionHeader(title: 'Slots'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: slots
                        .map((slot) => SlotChip(
                              slot: slot,
                              onTap: _busy ? null : () => _act(slot),
                            ))
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Tap a slot to reserve it, or tap a reserved slot to release it. '
                'Booking a charger can also auto-assign a slot for you.',
                style: TextStyle(fontSize: 12.5, color: AppTheme.neutral, height: 1.4),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: (_busy || free == 0) ? null : _reserveAny,
                icon: const Icon(Icons.local_parking_rounded),
                label: Text(free == 0 ? 'Parking full' : 'Reserve any free slot'),
              ),
            ],
          );
        },
      ),
    );
  }
}
