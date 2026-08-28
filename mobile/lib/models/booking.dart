import '../core/format.dart';

class Booking {
  Booking({
    required this.id,
    required this.reference,
    this.userId,
    this.userName,
    required this.vehicleId,
    required this.vehicleNumber,
    required this.stationId,
    required this.stationName,
    this.stationAddress,
    required this.chargerId,
    required this.chargerCode,
    required this.chargerType,
    this.chargerPower,
    this.parkingSlotId,
    this.parkingSlotNumber,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.amount,
    required this.status,
    this.createdAt,
    required this.qrData,
    this.paymentStatus,
    this.transactionRef,
  });

  final int id;
  final String reference;
  final int? userId;
  final String? userName;
  final int vehicleId;
  final String vehicleNumber;
  final int stationId;
  final String stationName;
  final String? stationAddress;
  final int chargerId;
  final String chargerCode;
  final String chargerType;
  final double? chargerPower;
  final int? parkingSlotId;
  final String? parkingSlotNumber;
  final String bookingDate;
  final String startTime;
  final String endTime;
  final double amount;
  final String status;
  final DateTime? createdAt;
  final String qrData;
  final String? paymentStatus;
  final String? transactionRef;

  bool get isPaid => paymentStatus?.toUpperCase() == 'SUCCESS';
  bool get isCancellable =>
      status.toUpperCase() == 'PENDING' || status.toUpperCase() == 'CONFIRMED';
  bool get needsPayment => status.toUpperCase() == 'PENDING' && !isPaid;
  bool get hasParking => parkingSlotId != null;

  String get slotLabel => '${timeLabel(startTime)} - ${timeLabel(endTime)}';

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: asInt(json['id']),
        reference: asText(json['reference']),
        userId: json['userId'] == null ? null : asInt(json['userId']),
        userName: json['userName'] as String?,
        vehicleId: asInt(json['vehicleId']),
        vehicleNumber: asText(json['vehicleNumber']),
        stationId: asInt(json['stationId']),
        stationName: asText(json['stationName']),
        stationAddress: json['stationAddress'] as String?,
        chargerId: asInt(json['chargerId']),
        chargerCode: asText(json['chargerCode']),
        chargerType: asText(json['chargerType']),
        chargerPower: asDouble(json['chargerPower']),
        parkingSlotId:
            json['parkingSlotId'] == null ? null : asInt(json['parkingSlotId']),
        parkingSlotNumber: json['parkingSlotNumber'] as String?,
        bookingDate: asText(json['bookingDate']),
        startTime: asText(json['startTime']),
        endTime: asText(json['endTime']),
        amount: asDouble(json['amount']) ?? 0,
        status: asText(json['status'], 'PENDING'),
        createdAt: asDateTime(json['createdAt']),
        qrData: asText(json['qrData'], asText(json['reference'])),
        paymentStatus: json['paymentStatus'] as String?,
        transactionRef: json['transactionRef'] as String?,
      );
}
