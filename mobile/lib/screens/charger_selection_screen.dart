import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/station.dart';
import '../widgets/common.dart';
import 'booking_screen.dart';
import 'station_details_screen.dart';

/// Step 1 of the booking flow: pick which charger to use.
class ChargerSelectionScreen extends StatefulWidget {
  const ChargerSelectionScreen({super.key, required this.station});

  final Station station;

  @override
  State<ChargerSelectionScreen> createState() => _ChargerSelectionScreenState();
}

class _ChargerSelectionScreenState extends State<ChargerSelectionScreen> {
  Charger? _selected;

  @override
  void initState() {
    super.initState();
    // Pre-select the first genuinely free charger so the happy path is one tap.
    final chargers = widget.station.chargers;
    final free =
        chargers.where((c) => c.status.toUpperCase() == 'AVAILABLE').toList();
    final serviceable = chargers.where((c) => c.isBookable).toList();
    if (free.isNotEmpty) {
      _selected = free.first;
    } else if (serviceable.isNotEmpty) {
      _selected = serviceable.first;
    }
  }

  Future<void> _continue() async {
    final charger = _selected;
    if (charger == null) return;

    final booked = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BookingScreen(station: widget.station, charger: charger),
      ),
    );
    if (booked == true && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final chargers = widget.station.chargers;
    final bookable = chargers.where((c) => c.isBookable).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Select charger')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                children: [
                  Text(
                    widget.station.name,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.station.address,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppTheme.neutral,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const SectionHeader(title: 'Available chargers'),
                  if (bookable.isEmpty)
                    const Card(
                      child: EmptyState(
                        icon: Icons.power_off_rounded,
                        title: 'No charger in service',
                        message: 'Every charger here is out of service right now.',
                      ),
                    )
                  else
                    ...chargers.map(
                      (charger) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Opacity(
                          opacity: charger.isBookable ? 1 : 0.5,
                          child: ChargerTile(
                            charger: charger,
                            selected: _selected?.id == charger.id,
                            onTap: charger.isBookable
                                ? () => setState(() => _selected = charger)
                                : null,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 17, color: AppTheme.accent),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'An occupied charger can still be reserved for a later '
                            'time slot. FleetX blocks overlapping bookings.',
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.4,
                              color: AppTheme.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: FilledButton.icon(
                onPressed: _selected == null ? null : _continue,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(
                  _selected == null
                      ? 'Select a charger'
                      : 'Continue with ${_selected!.code}',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
