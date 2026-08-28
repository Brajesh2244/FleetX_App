import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';
import '../widgets/cards.dart';
import '../widgets/common.dart';
import 'booking_detail_screen.dart';
import 'home_shell.dart';

/// Bookings tab: everything the driver has booked, newest first.
class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  static const List<_Filter> _filters = [
    _Filter(label: 'All'),
    _Filter(label: 'Upcoming', statuses: {'PENDING', 'CONFIRMED'}),
    _Filter(label: 'Completed', statuses: {'COMPLETED'}),
    _Filter(label: 'Cancelled', statuses: {'CANCELLED'}),
  ];

  final GlobalKey<AsyncViewState<List<Booking>>> _viewKey = GlobalKey();

  int _filter = 0;

  Future<void> _open(Booking booking) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BookingDetailScreen(bookingId: booking.id)),
    );
    await _viewKey.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    final shell = HomeShellScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My bookings'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: List.generate(_filters.length, (index) {
                return Padding(
                  padding: EdgeInsets.only(
                    right: index == _filters.length - 1 ? 0 : 8,
                  ),
                  child: _FilterChip(
                    label: _filters[index].label,
                    selected: _filter == index,
                    onTap: () => setState(() => _filter = index),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
      body: AsyncView<List<Booking>>(
        key: _viewKey,
        load: BookingService.list,
        builder: (context, bookings, reload) {
          final active = _filters[_filter];
          final visible = bookings.where(active.matches).toList();

          if (visible.isEmpty) {
            return ListView(
              children: [
                EmptyState(
                  icon: Icons.receipt_long_rounded,
                  title: bookings.isEmpty
                      ? 'No bookings yet'
                      : 'Nothing in ${active.label.toLowerCase()}',
                  message: bookings.isEmpty
                      ? 'Reserve a charger and it will show up here with a QR '
                          'pass.'
                      : 'Try a different filter.',
                  actionLabel: bookings.isEmpty ? 'Find a station' : 'Show all',
                  onAction: bookings.isEmpty
                      ? () => shell?.goToTab(HomeShell.tabStations)
                      : () => setState(() => _filter = 0),
                ),
              ],
            );
          }

          final pending = visible.where((b) => b.needsPayment).length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  '${visible.length} booking${visible.length == 1 ? '' : 's'}'
                  '${pending == 0 ? '' : ' · $pending awaiting payment'}',
                  style: const TextStyle(fontSize: 12.5, color: AppTheme.neutral),
                ),
              ),
              ...visible.map(
                (booking) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: BookingCard(
                    booking: booking,
                    onTap: () => _open(booking),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Filter {
  const _Filter({required this.label, this.statuses});

  final String label;

  /// Null means "match everything".
  final Set<String>? statuses;

  bool matches(Booking booking) =>
      statuses == null || statuses!.contains(booking.status.toUpperCase());
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.surfaceMuted,
          borderRadius: BorderRadius.circular(20),
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
