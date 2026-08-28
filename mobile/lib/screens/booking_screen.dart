import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/format.dart';
import '../core/pricing.dart';
import '../models/booking.dart';
import '../models/parking_slot.dart';
import '../models/station.dart';
import '../models/vehicle.dart';
import '../services/booking_service.dart';
import '../services/station_service.dart';
import '../services/vehicle_service.dart';
import '../widgets/common.dart';
import 'add_vehicle_screen.dart';
import 'payment_screen.dart';
import 'station_details_screen.dart';

/// Step 2 of the booking flow: vehicle, day, time slot and optional parking.
///
/// Pops `true` once the booking has been created and paid for, so every screen
/// behind it knows to refresh.
class BookingScreen extends StatefulWidget {
  const BookingScreen({
    super.key,
    required this.station,
    required this.charger,
  });

  final Station station;
  final Charger charger;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  /// Preset session lengths, in minutes.
  static const List<int> _durations = [30, 60, 90, 120, 180];

  final GlobalKey<AsyncViewState<(List<Vehicle>, List<ParkingSlot>)>> _viewKey =
      GlobalKey();

  late DateTime _date = DateTime.now();
  TimeOfDay _start = _nextHalfHour();
  int _minutes = 60;

  Vehicle? _vehicle;
  bool _wantParking = false;
  ParkingSlot? _slot;
  bool _submitting = false;

  Future<(List<Vehicle>, List<ParkingSlot>)> _load() async {
    final results = await Future.wait([
      VehicleService.list(),
      ParkingService.list(stationId: widget.station.id),
    ]);
    final vehicles = results[0] as List<Vehicle>;
    final slots = results[1] as List<ParkingSlot>;

    // Keep the current pick if it still exists, otherwise fall back.
    final keep = vehicles.where((v) => v.id == _vehicle?.id).toList();
    _vehicle = keep.isNotEmpty
        ? keep.first
        : (vehicles.isEmpty ? null : vehicles.first);

    if (_slot != null && !slots.any((s) => s.id == _slot!.id && s.isFree)) {
      _slot = null;
    }
    return (vehicles, slots);
  }

  String get _startWire => isoTime(_start.hour, _start.minute);

  String get _endWire {
    final total = _start.hour * 60 + _start.minute + _minutes;
    // Clamp to 23:59 so a late-evening slot never rolls into the next day.
    final capped = total > 23 * 60 + 59 ? 23 * 60 + 59 : total;
    return isoTime(capped ~/ 60, capped % 60);
  }

  double get _energy => estimateEnergy(
        power: widget.charger.power,
        startTime: _startWire,
        endTime: _endWire,
        batteryCapacity: _vehicle?.batteryCapacity,
      );

  double get _total => estimateAmount(
        pricePerKwh: widget.charger.pricePerKwh,
        power: widget.charger.power,
        startTime: _startWire,
        endTime: _endWire,
        batteryCapacity: _vehicle?.batteryCapacity,
        withParking: _wantParking,
      );

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _start);
    if (picked != null) setState(() => _start = picked);
  }

  Future<void> _addVehicle() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddVehicleScreen()),
    );
    if (created == true) await _viewKey.currentState?.reload();
  }

  Future<void> _confirm() async {
    final vehicle = _vehicle;
    if (vehicle == null || _submitting) return;

    setState(() => _submitting = true);
    final booking = await guard(
      context,
      () => BookingService.create(
        vehicleId: vehicle.id,
        stationId: widget.station.id,
        chargerId: widget.charger.id,
        parkingSlotId: _wantParking ? _slot?.id : null,
        autoAssignParking: _wantParking && _slot == null,
        bookingDate: isoDate(_date),
        startTime: _startWire,
        endTime: _endWire,
      ),
    );

    if (!mounted) return;
    setState(() => _submitting = false);
    if (booking == null) {
      // The conflict / validation message is already on screen; slots may have
      // changed underneath us, so refresh them.
      await _viewKey.currentState?.reload();
      return;
    }

    await _goToPayment(booking);
  }

  Future<void> _goToPayment(Booking booking) async {
    final paid = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => PaymentScreen(booking: booking)),
    );
    if (!mounted) return;
    // Either way the booking exists now, so unwind the flow.
    Navigator.of(context).pop(paid ?? true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book a slot')),
      body: AsyncView<(List<Vehicle>, List<ParkingSlot>)>(
        key: _viewKey,
        load: _load,
        pullToRefresh: false,
        builder: (context, data, reload) {
          final (vehicles, slots) = data;

          if (vehicles.isEmpty) {
            return EmptyState(
              icon: Icons.electric_car_rounded,
              title: 'Add a vehicle first',
              message: 'A booking needs a vehicle. Add your EV to continue.',
              actionLabel: 'Add vehicle',
              onAction: _addVehicle,
            );
          }

          final freeSlots = slots.where((s) => s.isFree).toList();

          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    children: [
                      _ChargerSummary(
                        station: widget.station,
                        charger: widget.charger,
                      ),
                      const SizedBox(height: 22),

                      const SectionHeader(title: 'Vehicle'),
                      _VehiclePicker(
                        vehicles: vehicles,
                        selected: _vehicle,
                        onChanged: (v) => setState(() => _vehicle = v),
                        onAdd: _addVehicle,
                      ),
                      const SizedBox(height: 22),

                      const SectionHeader(title: 'Date'),
                      _DayStrip(
                        selected: _date,
                        onSelect: (d) => setState(() => _date = d),
                      ),
                      const SizedBox(height: 22),

                      const SectionHeader(title: 'Time slot'),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Starts at',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: AppTheme.neutral,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          timeLabel(_startWire),
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: _pickTime,
                                    icon: const Icon(
                                      Icons.schedule_rounded,
                                      size: 18,
                                    ),
                                    label: const Text('Change'),
                                  ),
                                ],
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                child: Divider(height: 1),
                              ),
                              const Text(
                                'Duration',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: AppTheme.neutral,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _durations
                                    .map(
                                      (m) => _Choice(
                                        label: durationLabel(
                                          '00:00',
                                          isoTime(m ~/ 60, m % 60),
                                        ),
                                        selected: _minutes == m,
                                        onTap: () =>
                                            setState(() => _minutes = m),
                                      ),
                                    )
                                    .toList(),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 15,
                                    color: AppTheme.neutral,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Ends at ${timeLabel(_endWire)}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.neutral,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),

                      // ------------------------------------------- parking
                      const SectionHeader(title: 'Parking'),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                          child: Column(
                            children: [
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                value: _wantParking,
                                onChanged: freeSlots.isEmpty
                                    ? null
                                    : (on) => setState(() {
                                          _wantParking = on;
                                          if (!on) _slot = null;
                                        }),
                                title: const Text(
                                  'Reserve a parking slot',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  freeSlots.isEmpty
                                      ? 'No free slots at this station'
                                      : '${freeSlots.length} free · '
                                          '${money(parkingFee)} extra',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppTheme.neutral,
                                  ),
                                ),
                              ),
                              if (_wantParking && freeSlots.isNotEmpty) ...[
                                const Divider(height: 1),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _slot == null
                                            ? 'A free slot will be assigned '
                                                'automatically.'
                                            : 'Slot ${_slot!.slotNumber} '
                                                'selected.',
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          color: AppTheme.neutral,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 10,
                                        runSpacing: 10,
                                        children: freeSlots
                                            .map(
                                              (slot) => SlotChip(
                                                slot: slot,
                                                selected: _slot?.id == slot.id,
                                                onTap: () => setState(
                                                  () => _slot =
                                                      _slot?.id == slot.id
                                                          ? null
                                                          : slot,
                                                ),
                                              ),
                                            )
                                            .toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),

                      const SectionHeader(title: 'Price estimate'),
                      _PriceCard(
                        energy: _energy,
                        pricePerKwh: widget.charger.pricePerKwh,
                        withParking: _wantParking,
                        total: _total,
                        duration: durationLabel(_startWire, _endWire),
                      ),
                    ],
                  ),
                ),
                _ConfirmBar(
                  total: _total,
                  busy: _submitting,
                  onConfirm: _vehicle == null ? null : _confirm,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Rounds up to the next :00 or :30 so the default slot is always in future.
  static TimeOfDay _nextHalfHour() {
    final now = DateTime.now();
    final minutes = now.minute < 30 ? 30 : 60;
    final next = DateTime(now.year, now.month, now.day, now.hour)
        .add(Duration(minutes: minutes));
    return TimeOfDay(hour: next.hour, minute: next.minute);
  }
}

class _ChargerSummary extends StatelessWidget {
  const _ChargerSummary({required this.station, required this.charger});

  final Station station;
  final Charger charger;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.bolt_rounded, color: AppTheme.primaryDark),
            ),
            const SizedBox(width: 14),
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
                  const SizedBox(height: 3),
                  Text(
                    '${charger.code} · ${prettyEnum(charger.type)} · '
                    '${money(charger.pricePerKwh)}/kWh',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppTheme.neutral,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehiclePicker extends StatelessWidget {
  const _VehiclePicker({
    required this.vehicles,
    required this.selected,
    required this.onChanged,
    required this.onAdd,
  });

  final List<Vehicle> vehicles;
  final Vehicle? selected;
  final ValueChanged<Vehicle> onChanged;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            ...vehicles.map(
              (vehicle) => _VehicleOption(
                vehicle: vehicle,
                selected: selected?.id == vehicle.id,
                onTap: () => onChanged(vehicle),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add another vehicle'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleOption extends StatelessWidget {
  const _VehicleOption({
    required this.vehicle,
    required this.selected,
    required this.onTap,
  });

  final Vehicle vehicle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final battery = vehicle.batteryCapacity;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Icon(
              AppTheme.vehicleIcon(vehicle.vehicleType),
              color: selected ? AppTheme.primaryDark : AppTheme.neutral,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.vehicleNumber,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${prettyEnum(vehicle.vehicleType)}'
                    '${battery == null ? '' : ' · ${battery.toStringAsFixed(1)} kWh'}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppTheme.neutral,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 20,
              color: selected ? AppTheme.primary : AppTheme.neutral,
            ),
          ],
        ),
      ),
    );
  }
}

/// Seven-day horizontal date picker - lighter than a full calendar dialog.
class _DayStrip extends StatelessWidget {
  const _DayStrip({required this.selected, required this.onSelect});

  final DateTime selected;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = List.generate(
      7,
      (i) => DateTime(today.year, today.month, today.day + i),
    );

    return SizedBox(
      height: 74,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = isoDate(day) == isoDate(selected);

          return InkWell(
            onTap: () => onSelect(day),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 66,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppTheme.primary : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    index == 0 ? 'Today' : dayLabel(day).split(',').first,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppTheme.neutral,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : null,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.surfaceMuted,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppTheme.neutral,
          ),
        ),
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({
    required this.energy,
    required this.pricePerKwh,
    required this.withParking,
    required this.total,
    required this.duration,
  });

  final double energy;
  final double pricePerKwh;
  final bool withParking;
  final double total;
  final String duration;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        child: Column(
          children: [
            InfoRow(label: 'Session length', value: duration),
            InfoRow(
              label: 'Estimated units',
              value: '${energy.toStringAsFixed(2)} kWh',
            ),
            InfoRow(label: 'Rate', value: '${money(pricePerKwh)} / kWh'),
            if (withParking)
              InfoRow(label: 'Parking', value: money(parkingFee)),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1),
            ),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Total payable',
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  money(total),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Charged on the actual units drawn. This is an estimate for the '
              'slot you picked.',
              style: TextStyle(fontSize: 11.5, color: AppTheme.neutral, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmBar extends StatelessWidget {
  const _ConfirmBar({
    required this.total,
    required this.busy,
    required this.onConfirm,
  });

  final double total;
  final bool busy;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontSize: 12, color: AppTheme.neutral),
              ),
              Text(
                money(total),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FilledButton.icon(
              onPressed: busy ? null : onConfirm,
              icon: busy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.lock_outline_rounded),
              label: Text(busy ? 'Booking...' : 'Confirm booking'),
            ),
          ),
        ],
      ),
    );
  }
}
