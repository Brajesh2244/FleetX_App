import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/format.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';
import '../widgets/common.dart';
import 'booking_success_screen.dart';
import 'payment_screen.dart';

/// One booking, with its QR pass and the actions still available on it.
class BookingDetailScreen extends StatefulWidget {
  const BookingDetailScreen({super.key, required this.bookingId});

  final int bookingId;

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final GlobalKey<AsyncViewState<Booking>> _viewKey = GlobalKey();

  bool _busy = false;

  Future<void> _pay(Booking booking) async {
    final paid = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => PaymentScreen(booking: booking)),
    );
    if (paid == true && mounted) await _viewKey.currentState?.reload();
  }

  Future<void> _cancel(Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this booking?'),
        content: Text(
          booking.isPaid
              ? 'The charger and any parking slot are released, and '
                  '${money(booking.amount)} goes back to your FleetX wallet.'
              : 'The charger and any parking slot are released. This cannot be '
                  'undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.full),
            child: const Text('Cancel booking'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    final ok = await guardVoid(
      context,
      () => BookingService.cancel(booking.id),
    );

    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) showSnack(context, 'Booking ${booking.reference} cancelled');
    await _viewKey.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking')),
      body: AsyncView<Booking>(
        key: _viewKey,
        load: () => BookingService.get(widget.bookingId),
        builder: (context, booking, reload) => SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  children: [
                    BookingQrPanel(booking: booking),
                    const SizedBox(height: 22),
                    const SectionHeader(title: 'Details'),
                    BookingDetailsCard(booking: booking),
                  ],
                ),
              ),
              if (booking.needsPayment || booking.isCancellable)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: Row(
                    children: [
                      if (booking.isCancellable)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _busy ? null : () => _cancel(booking),
                            icon: const Icon(Icons.close_rounded, size: 18),
                            label: const Text('Cancel'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.full,
                              minimumSize: const Size(0, 52),
                              side: const BorderSide(color: AppTheme.full),
                            ),
                          ),
                        ),
                      if (booking.needsPayment) ...[
                        if (booking.isCancellable) const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton.icon(
                            onPressed: _busy ? null : () => _pay(booking),
                            icon: const Icon(Icons.lock_outline_rounded),
                            label: Text('Pay ${money(booking.amount)}'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
