import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/format.dart';
import '../models/booking.dart';
import '../models/payment.dart';
import '../models/wallet.dart';
import '../services/booking_service.dart';
import '../services/wallet_service.dart';
import '../widgets/common.dart';
import 'booking_success_screen.dart';

/// Step 3: simulated payment for a pending booking.
///
/// Pops `true` once the payment succeeds. Wallet is the only method that moves
/// real (demo) money; the others just record a reference.
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, required this.booking});

  final Booking booking;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  static const List<_Method> _methods = [
    _Method(
      code: 'WALLET',
      title: 'FleetX Wallet',
      subtitle: 'Instant, no gateway',
      icon: Icons.account_balance_wallet_rounded,
    ),
    _Method(
      code: 'UPI',
      title: 'UPI',
      subtitle: 'GPay, PhonePe, Paytm',
      icon: Icons.qr_code_rounded,
    ),
    _Method(
      code: 'CARD',
      title: 'Card',
      subtitle: 'Debit or credit',
      icon: Icons.credit_card_rounded,
    ),
    _Method(
      code: 'NETBANKING',
      title: 'Net banking',
      subtitle: 'All major banks',
      icon: Icons.account_balance_rounded,
    ),
  ];

  String _method = 'WALLET';
  bool _paying = false;

  Future<Wallet> _loadWallet() => WalletService.get();

  Future<void> _pay(Wallet wallet) async {
    if (_paying) return;

    // Checked here as well as server-side so the driver gets an instant answer.
    if (_method == 'WALLET' && wallet.balance < widget.booking.amount) {
      showSnack(
        context,
        'Wallet has ${money(wallet.balance)} - '
        '${money(widget.booking.amount - wallet.balance)} short. '
        'Recharge or pick another method.',
        error: true,
      );
      return;
    }

    setState(() => _paying = true);
    final payment = await guard(
      context,
      () => PaymentService.pay(
        bookingId: widget.booking.id,
        method: _method,
      ),
    );

    if (!mounted) return;
    setState(() => _paying = false);
    if (payment == null) return;

    await _showSuccess(payment);
  }

  Future<void> _showSuccess(Payment payment) async {
    // Re-read the booking so the QR screen shows the confirmed status.
    Booking booking;
    try {
      booking = await BookingService.get(widget.booking.id);
    } catch (_) {
      booking = widget.booking;
    }

    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => BookingSuccessScreen(
          booking: booking,
          payment: payment,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;

    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: AsyncView<Wallet>(
        load: _loadWallet,
        pullToRefresh: false,
        builder: (context, wallet, reload) {
          final short = _method == 'WALLET' && wallet.balance < booking.amount;

          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    children: [
                      _AmountCard(amount: booking.amount),
                      const SizedBox(height: 22),

                      const SectionHeader(title: 'Booking'),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                          child: Column(
                            children: [
                              InfoRow(
                                label: 'Reference',
                                value: booking.reference,
                              ),
                              InfoRow(
                                label: 'Station',
                                value: booking.stationName,
                              ),
                              InfoRow(
                                label: 'Charger',
                                value: '${booking.chargerCode} · '
                                    '${prettyEnum(booking.chargerType)}',
                              ),
                              InfoRow(
                                label: 'When',
                                value: '${dateLabel(booking.bookingDate)}, '
                                    '${booking.slotLabel}',
                              ),
                              InfoRow(
                                label: 'Vehicle',
                                value: booking.vehicleNumber,
                              ),
                              if (booking.hasParking)
                                InfoRow(
                                  label: 'Parking slot',
                                  value: booking.parkingSlotNumber ?? '-',
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),

                      const SectionHeader(title: 'Pay using'),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          child: Column(
                            children: _methods.map((method) {
                              final isWallet = method.code == 'WALLET';

                              return _MethodOption(
                                icon: method.icon,
                                title: method.title,
                                subtitle: isWallet
                                    ? 'Balance ${money(wallet.balance)}'
                                    : method.subtitle,
                                selected: _method == method.code,
                                warn: isWallet &&
                                    wallet.balance < booking.amount,
                                onTap: () =>
                                    setState(() => _method = method.code),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      if (short)
                        _Notice(
                          color: AppTheme.full,
                          icon: Icons.error_outline_rounded,
                          message:
                              'Wallet is ${money(booking.amount - wallet.balance)} '
                              'short. Recharge from the Wallet tab or choose '
                              'UPI, card or net banking.',
                        )
                      else
                        const _Notice(
                          color: AppTheme.accent,
                          icon: Icons.info_outline_rounded,
                          message:
                              'Payments are simulated for this prototype - no '
                              'real gateway is contacted and no card details '
                              'are collected.',
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
                    onPressed: _paying ? null : () => _pay(wallet),
                    icon: _paying
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.lock_outline_rounded),
                    label: Text(
                      _paying ? 'Processing...' : 'Pay ${money(booking.amount)}',
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// One row in the "Pay using" list.
class _Method {
  const _Method({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String code;
  final String title;
  final String subtitle;
  final IconData icon;
}

class _AmountCard extends StatelessWidget {  const _AmountCard({required this.amount});

  final double amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primary, AppTheme.primaryDark],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'Amount to pay',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            money(amount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodOption extends StatelessWidget {
  const _MethodOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.warn = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final bool warn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, color: selected ? AppTheme.primaryDark : AppTheme.neutral),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: warn ? AppTheme.full : AppTheme.neutral,
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

class _Notice extends StatelessWidget {
  const _Notice({
    required this.color,
    required this.icon,
    required this.message,
  });

  final Color color;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12.5, height: 1.4, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
