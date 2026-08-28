import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/format.dart';
import '../models/dashboard.dart';
import '../services/dashboard_service.dart';
import '../widgets/cards.dart';
import '../widgets/common.dart';
import 'add_vehicle_screen.dart';
import 'booking_detail_screen.dart';
import 'home_shell.dart';
import 'station_details_screen.dart';
import 'vehicle_list_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AsyncView<DashboardData>(
        load: DashboardService.load,
        builder: (context, data, reload) => _DashboardBody(data: data, reload: reload),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.data, required this.reload});

  final DashboardData data;
  final Future<void> Function() reload;

  @override
  Widget build(BuildContext context) {
    final shell = HomeShellScope.of(context);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _Header(data: data),
        Transform.translate(
          offset: const Offset(0, -34),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _WalletCard(
                  balance: data.walletBalance,
                  onTap: () => shell?.goToTab(HomeShell.tabWallet),
                ),
                const SizedBox(height: 14),

                // Live network snapshot.
                Row(
                  children: [
                    Expanded(
                      child: StatTile(
                        icon: Icons.bolt_rounded,
                        label: 'Available chargers',
                        value: '${data.availableChargers}',
                        color: AppTheme.available,
                        onTap: () => shell?.goToTab(HomeShell.tabStations),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatTile(
                        icon: Icons.local_parking_rounded,
                        label: 'Free parking slots',
                        value: '${data.availableParkingSlots}',
                        color: AppTheme.accent,
                        onTap: () => shell?.goToTab(HomeShell.tabStations),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // ------------------------------------------- active booking
                SectionHeader(
                  title: 'Active booking',
                  actionLabel: 'History',
                  onAction: () => shell?.goToTab(HomeShell.tabBookings),
                ),
                if (data.activeBooking != null)
                  BookingCard(
                    booking: data.activeBooking!,
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              BookingDetailScreen(bookingId: data.activeBooking!.id),
                        ),
                      );
                      await reload();
                    },
                  )
                else
                  Card(
                    child: EmptyState(
                      icon: Icons.event_available_rounded,
                      title: 'No active booking',
                      message: 'Pick a station to reserve a charger and a parking slot.',
                      actionLabel: 'Find a station',
                      onAction: () => shell?.goToTab(HomeShell.tabStations),
                    ),
                  ),
                const SizedBox(height: 22),

                // ------------------------------------------------ my vehicle
                SectionHeader(
                  title: 'My vehicle',
                  actionLabel: data.myVehicleCount > 1
                      ? 'All ${data.myVehicleCount}'
                      : 'Manage',
                  onAction: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const VehicleListScreen()),
                    );
                    await reload();
                  },
                ),
                if (data.primaryVehicle != null)
                  VehicleCard(
                    vehicle: data.primaryVehicle!,
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const VehicleListScreen()),
                      );
                      await reload();
                    },
                  )
                else
                  Card(
                    child: EmptyState(
                      icon: Icons.electric_car_rounded,
                      title: 'No vehicle added',
                      message: 'Add your EV so you can book a charging slot.',
                      actionLabel: 'Add vehicle',
                      onAction: () async {
                        final created = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(builder: (_) => const AddVehicleScreen()),
                        );
                        if (created == true) await reload();
                      },
                    ),
                  ),
                const SizedBox(height: 22),

                // -------------------------------------------- nearby stations
                SectionHeader(
                  title: 'Nearby stations',
                  actionLabel: 'View all',
                  onAction: () => shell?.goToTab(HomeShell.tabStations),
                ),
                if (data.nearbyStations.isEmpty)
                  const Card(
                    child: EmptyState(
                      icon: Icons.ev_station_rounded,
                      title: 'No stations yet',
                      message: 'Stations added by the admin will appear here.',
                    ),
                  )
                else
                  ...data.nearbyStations.map(
                    (station) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: StationCard(
                        station: station,
                        compact: true,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  StationDetailsScreen(stationId: station.id),
                            ),
                          );
                          await reload();
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final vehicleLabel = data.primaryVehicle?.vehicleNumber ?? 'No vehicle yet';

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        left: 20,
        right: 20,
        bottom: 52,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primary, AppTheme.primaryDark],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello,',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.electric_car_rounded,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      vehicleLabel,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                data.userName.isEmpty ? '?' : data.userName[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletCard extends StatelessWidget {
  const _WalletCard({required this.balance, this.onTap});

  final double balance;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: AppTheme.primaryDark,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Wallet balance',
                      style: TextStyle(fontSize: 12.5, color: AppTheme.neutral),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      money(balance),
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppTheme.neutral),
            ],
          ),
        ),
      ),
    );
  }
}