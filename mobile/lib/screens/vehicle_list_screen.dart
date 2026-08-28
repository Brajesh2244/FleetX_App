import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/vehicle.dart';
import '../services/vehicle_service.dart';
import '../widgets/cards.dart';
import '../widgets/common.dart';
import 'add_vehicle_screen.dart';

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  final GlobalKey<AsyncViewState<List<Vehicle>>> _viewKey = GlobalKey();

  Future<void> _openForm({Vehicle? vehicle}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AddVehicleScreen(vehicle: vehicle)),
    );
    if (saved == true) await _viewKey.currentState?.reload();
  }

  Future<void> _confirmDelete(Vehicle vehicle) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove vehicle?'),
        content: Text(
          '${vehicle.vehicleNumber} will be removed from your account. '
          'Bookings already made for it are kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.full,
              minimumSize: const Size(96, 42),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final removed =
        await guardVoid(context, () => VehicleService.delete(vehicle.id));
    if (!mounted) return;
    if (removed) showSnack(context, '${vehicle.vehicleNumber} removed');
    await _viewKey.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My vehicles')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add vehicle'),
      ),
      body: AsyncView<List<Vehicle>>(
        key: _viewKey,
        load: VehicleService.list,
        builder: (context, vehicles, reload) {
          if (vehicles.isEmpty) {
            return ListView(
              children: [
                EmptyState(
                  icon: Icons.electric_car_rounded,
                  title: 'No vehicles yet',
                  message: 'Add an EV to start booking charging slots.',
                  actionLabel: 'Add vehicle',
                  onAction: () => _openForm(),
                ),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: vehicles.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final vehicle = vehicles[i];
              return VehicleCard(
                vehicle: vehicle,
                onTap: () => _openForm(vehicle: vehicle),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StatusChip(label: vehicle.status),
                    PopupMenuButton<String>(
                      tooltip: 'Vehicle actions',
                      icon: const Icon(Icons.more_vert_rounded,
                          size: 20, color: AppTheme.neutral),
                      onSelected: (value) {
                        if (value == 'edit') _openForm(vehicle: vehicle);
                        if (value == 'delete') _confirmDelete(vehicle);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Remove')),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
