import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/format.dart';
import '../models/wallet.dart';
import '../services/wallet_service.dart';
import '../widgets/common.dart';

/// Wallet tab: balance, quick recharge, and the transaction ledger.
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  static const List<double> _presets = [200, 500, 1000, 2000];

  final GlobalKey<AsyncViewState<(Wallet, List<WalletTransaction>)>> _viewKey =
      GlobalKey();

  bool _busy = false;

  Future<(Wallet, List<WalletTransaction>)> _load() async {
    final results = await Future.wait([
      WalletService.get(),
      WalletService.transactions(),
    ]);
    return (results[0] as Wallet, results[1] as List<WalletTransaction>);
  }

  Future<void> _recharge(double amount) async {
    if (_busy) return;
    setState(() => _busy = true);

    final wallet = await guard(context, () => WalletService.recharge(amount));

    if (!mounted) return;
    setState(() => _busy = false);
    if (wallet != null) {
      showSnack(context, '${money(amount)} added · balance ${money(wallet.balance)}');
    }
    await _viewKey.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: AsyncView<(Wallet, List<WalletTransaction>)>(
        key: _viewKey,
        load: _load,
        builder: (context, data, reload) {
          final (wallet, transactions) = data;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _BalanceCard(balance: wallet.balance),
              const SizedBox(height: 22),

              const SectionHeader(title: 'Add money'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _presets
                            .map(
                              (amount) => OutlinedButton(
                                onPressed:
                                    _busy ? null : () => _recharge(amount),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 44),
                                ),
                                child: Text('+ ${moneyShort(amount)}'),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Recharges are simulated for this prototype - no '
                        'payment gateway is contacted.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.neutral,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),

              const SectionHeader(title: 'Transactions'),
              if (transactions.isEmpty)
                const Card(
                  child: EmptyState(
                    icon: Icons.receipt_rounded,
                    title: 'No transactions',
                    message: 'Recharges and booking payments appear here.',
                  ),
                )
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    child: Column(
                      children: List.generate(transactions.length, (index) {
                        return Column(
                          children: [
                            if (index > 0) const Divider(height: 1),
                            _TransactionRow(transaction: transactions[index]),
                          ],
                        );
                      }),
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

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});

  final double balance;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primary, AppTheme.primaryDark],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white.withValues(alpha: 0.9),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'FleetX Wallet',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            money(balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Available balance',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction});

  final WalletTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final credit = transaction.isCredit;
    final tint = credit ? AppTheme.available : AppTheme.full;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              credit ? Icons.south_west_rounded : Icons.north_east_rounded,
              size: 18,
              color: tint,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description ?? prettyEnum(transaction.type),
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateTimeLabel(transaction.createdAt),
                  style: const TextStyle(fontSize: 11.5, color: AppTheme.neutral),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${credit ? '+' : '-'}${money(transaction.amount)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: tint,
            ),
          ),
        ],
      ),
    );
  }
}
