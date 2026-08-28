import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/format.dart';
import '../models/vehicle.dart';
import '../services/vehicle_service.dart';
import '../widgets/common.dart';

/// Add / edit form. Pass [vehicle] to edit an existing one.
/// Pops with `true` when something was saved.
class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key, this.vehicle});

  final Vehicle? vehicle;

  bool get isEdit => vehicle != null;

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _number;
  late final TextEditingController _driverName;
  late final TextEditingController _driverContact;
  late final TextEditingController _battery;
  late final TextEditingController _range;

  late String _type;
  late String _status;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    _number = TextEditingController(text: v?.vehicleNumber ?? '');
    _driverName = TextEditingController(text: v?.driverName ?? '');
    _driverContact = TextEditingController(text: v?.driverContact ?? '');
    _battery = TextEditingController(
      text: v?.batteryCapacity == null ? '' : '${v!.batteryCapacity}',
    );
    _range = TextEditingController(
      text: v?.currentRange == null ? '' : '${v!.currentRange}',
    );
    _type = v?.vehicleType ?? 'CAR';
    _status = v?.status ?? 'ACTIVE';
  }

  @override
  void dispose() {
    _number.dispose();
    _driverName.dispose();
    _driverContact.dispose();
    _battery.dispose();
    _range.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);

    final body = VehicleService.body(
      vehicleNumber: _number.text,
      vehicleType: _type,
      driverName: _driverName.text,
      driverContact: _driverContact.text,
      batteryCapacity: double.tryParse(_battery.text.trim()),
      currentRange: double.tryParse(_range.text.trim()),
      status: _status,
    );

    final saved = await guard(
      context,
      () => widget.isEdit
          ? VehicleService.update(widget.vehicle!.id, body)
          : VehicleService.create(body),
    );

    if (!mounted) return;
    setState(() => _busy = false);
    if (saved == null) return;

    showSnack(
      context,
      widget.isEdit
          ? '${saved.vehicleNumber} updated'
          : '${saved.vehicleNumber} added',
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit vehicle' : 'Add vehicle'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _number,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Vehicle number *',
                  hintText: 'KA01AB1234',
                  prefixIcon: Icon(Icons.confirmation_number_outlined),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Vehicle number is required';
                  }
                  return v.trim().length < 4 ? 'That looks too short' : null;
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Vehicle type *',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: Vehicle.types
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Row(
                            children: [
                              Icon(AppTheme.vehicleIcon(t),
                                  size: 18, color: AppTheme.neutral),
                              const SizedBox(width: 10),
                              Text(prettyEnum(t)),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _type = v ?? 'CAR'),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
                items: Vehicle.statuses
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Row(
                            children: [
                              Container(
                                height: 8,
                                width: 8,
                                decoration: BoxDecoration(
                                  color: AppTheme.statusColor(s),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(prettyEnum(s)),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _status = v ?? 'ACTIVE'),
              ),
              const SizedBox(height: 22),
              const Text(
                'Battery & range',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const SizedBox(height: 4),
              const Text(
                'Battery capacity caps the energy a booking can charge, so it '
                'also caps the price.',
                style: TextStyle(fontSize: 12.5, color: AppTheme.neutral, height: 1.35),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _battery,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Battery (kWh)',
                        hintText: '40.5',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final parsed = double.tryParse(v.trim());
                        if (parsed == null) return 'Numbers only';
                        return parsed <= 0 ? 'Must be positive' : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _range,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Range (km)',
                        hintText: '312',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        return double.tryParse(v.trim()) == null
                            ? 'Numbers only'
                            : null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const Text(
                'Driver details',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const SizedBox(height: 4),
              const Text(
                'Leave blank to use your own name and phone number.',
                style: TextStyle(fontSize: 12.5, color: AppTheme.neutral),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _driverName,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Driver name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _driverContact,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Driver contact',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: _busy
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : Text(widget.isEdit ? 'Save changes' : 'Add vehicle'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
