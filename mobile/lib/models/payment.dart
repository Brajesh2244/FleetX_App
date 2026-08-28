import '../core/format.dart';

class Payment {
  Payment({
    required this.id,
    required this.bookingId,
    this.bookingReference,
    required this.amount,
    required this.method,
    required this.status,
    this.transactionRef,
    this.paidAt,
    required this.message,
  });

  final int id;
  final int bookingId;
  final String? bookingReference;
  final double amount;
  final String method;
  final String status;
  final String? transactionRef;
  final DateTime? paidAt;
  final String message;

  bool get isSuccess => status.toUpperCase() == 'SUCCESS';

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: asInt(json['id']),
        bookingId: asInt(json['bookingId']),
        bookingReference: json['bookingReference'] as String?,
        amount: asDouble(json['amount']) ?? 0,
        method: asText(json['method'], 'WALLET'),
        status: asText(json['status'], 'SUCCESS'),
        transactionRef: json['transactionRef'] as String?,
        paidAt: asDateTime(json['paidAt']),
        message: asText(json['message'], 'Payment Successful'),
      );

  /// Simulated methods offered on the payment screen.
  static const List<String> methods = ['WALLET', 'UPI', 'CARD', 'NETBANKING'];
}
