import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/app_theme.dart';
import '../core/format.dart';
import '../models/booking.dart';
import '../models/payment.dart';
import '../widgets/common.dart';

/// Step 4: confirmation with the QR code the driver shows at the station.
class BookingSuccessScreen extends StatelessWidget {
  const BookingSuccessScreen({
    super.key,
    required this.booking,
    this.payment,
  });

  final Booking booking;
  final Payment? payment;

  @override
  Widget build(BuildContext context) {
    // Back must not return to the payment screen, which is already spent.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _finish(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Booking confirmed'),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => _finish(context),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  children: [
                    const _SuccessBadge(),
                    const SizedBox(height: 20),
                    BookingQrPanel(booking: booking),
                    const SizedBox(height: 22),
                    const SectionHeader(title: 'Details'),
                    BookingDetailsCard(booking: booking, payment: payment),
                    const SizedBox(height: 14),
                    const _ArrivalNote(),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Column(
                  children: [
                    FilledButton.icon(
                      onPressed: () => _finish(context),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Done'),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You can reopen this pass any time from the Bookings tab.',
                      style: TextStyle(fontSize: 12, color: AppTheme.neutral),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Unwinds the whole booking flow back to whatever launched it.
  void _finish(BuildContext context) => Navigator.of(context).pop(true);
}

class _SuccessBadge extends StatelessWidget {
  const _SuccessBadge();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 76,
          width: 76,
          decoration: BoxDecoration(
            color: AppTheme.available.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            size: 46,
            color: AppTheme.available,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Payment successful',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        const Text(
          'Your charging slot is reserved.',
          style: TextStyle(fontSize: 13.5, color: AppTheme.neutral),
        ),
      ],
    );
  }
}

/// The scannable pass. Shared with the booking detail screen.
class BookingQrPanel extends StatelessWidget {
  const BookingQrPanel({super.key, required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final cancelled = booking.status.toUpperCase() == 'CANCELLED';

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
        child: Column(
          children: [
            Opacity(
              opacity: cancelled ? 0.25 : 1,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: QrImageView(
                  data: booking.qrData,
                  size: 172,
                  version: QrVersions.auto,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF0F172A),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              booking.reference,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              cancelled
                  ? 'This booking was cancelled - the code is no longer valid.'
                  : 'Show this code at the station to unlock the charger.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: cancelled ? AppTheme.full : AppTheme.neutral,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full booking breakdown. Shared with the booking detail screen.
class BookingDetailsCard extends StatelessWidget {
  const BookingDetailsCard({super.key, required this.booking, this.payment});

  final Booking booking;
  final Payment? payment;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Status',
                    style: TextStyle(color: AppTheme.neutral),
                  ),
                ),
                StatusChip(label: prettyEnum(booking.status).toUpperCase()),
              ],
            ),
            const SizedBox(height: 4),
            InfoRow(label: 'Station', value: booking.stationName),
            if (booking.stationAddress != null)
              InfoRow(label: 'Address', value: booking.stationAddress!),
            InfoRow(
              label: 'Charger',
              value: '${booking.chargerCode} · '
                  '${prettyEnum(booking.chargerType)}'
                  '${booking.chargerPower == null ? '' : ' · '
                      '${booking.chargerPower!.toStringAsFixed(0)} kW'}',
            ),
            InfoRow(label: 'Date', value: dateLabel(booking.bookingDate)),
            InfoRow(label: 'Time', value: booking.slotLabel),
            InfoRow(
              label: 'Duration',
              value: durationLabel(booking.startTime, booking.endTime),
            ),
            InfoRow(label: 'Vehicle', value: booking.vehicleNumber),
            InfoRow(
              label: 'Parking',
              value: booking.hasParking
                  ? 'Slot ${booking.parkingSlotNumber}'
                  : 'Not reserved',
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1),
            ),
            InfoRow(
              label: 'Amount',
              value: money(booking.amount),
              bold: true,
            ),
            InfoRow(
              label: 'Payment',
              value: booking.isPaid
                  ? 'Paid${payment == null ? '' : ' · ${prettyEnum(payment!.method)}'}'
                  : 'Pending',
              valueColor: booking.isPaid ? AppTheme.available : AppTheme.limited,
            ),
            if (booking.transactionRef != null)
              InfoRow(label: 'Transaction', value: booking.transactionRef!),
            if (booking.createdAt != null)
              InfoRow(
                label: 'Booked on',
                value: dateTimeLabel(booking.createdAt),
              ),
          ],
        ),
      ),
    );
  }
}

class _ArrivalNote extends StatelessWidget {
  const _ArrivalNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 17, color: AppTheme.accent),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Arrive within 15 minutes of your slot. Cancelling before the '
              'start time refunds the amount to your FleetX wallet.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: AppTheme.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
