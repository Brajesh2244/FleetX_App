import '../core/format.dart';

class Wallet {
  Wallet({required this.id, required this.userId, required this.balance});

  final int id;
  final int userId;
  final double balance;

  factory Wallet.fromJson(Map<String, dynamic> json) => Wallet(
        id: asInt(json['id']),
        userId: asInt(json['userId']),
        balance: asDouble(json['balance']) ?? 0,
      );
}

class WalletTransaction {
  WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    this.description,
    this.createdAt,
  });

  final int id;
  final String type;
  final double amount;
  final String? description;
  final DateTime? createdAt;

  bool get isCredit => type.toUpperCase() == 'CREDIT';

  factory WalletTransaction.fromJson(Map<String, dynamic> json) =>
      WalletTransaction(
        id: asInt(json['id']),
        type: asText(json['type'], 'CREDIT'),
        amount: asDouble(json['amount']) ?? 0,
        description: json['description'] as String?,
        createdAt: asDateTime(json['createdAt']),
      );
}
