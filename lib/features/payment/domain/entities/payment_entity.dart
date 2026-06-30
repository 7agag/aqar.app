import 'package:equatable/equatable.dart';
import 'package:aqar/core/utils/parse_utils.dart';

class TransactionEntity extends Equatable {
  final String? paymentId;
  final int? propertyId;
  final String? paymentType;
  final double value;
  final String? paymentMethod;
  final String? status;
  final String? transferId;
  final DateTime createdAt;

  const TransactionEntity({
    this.paymentId,
    this.propertyId,
    this.paymentType,
    this.value = 0.0,
    this.paymentMethod,
    this.status,
    this.transferId,
    required this.createdAt,
  });

  factory TransactionEntity.fromJson(Map<String, dynamic> json) {
    return TransactionEntity(
      paymentId: json['payment_id'] as String?,
      propertyId: json['property_id'] as int?,
      paymentType: json['payment_type'] as String?,
      value: parseDouble(json['value']),
      paymentMethod: json['payment_method'] as String?,
      status: json['status'] as String?,
      transferId: json['transfer_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  bool get isDeposit =>
      value >= 0 &&
      (paymentType == 'deposit' ||
          paymentType == 'rent' ||
          paymentType == 'rent_monthly' ||
          paymentType == 'refund');

  bool get isWithdrawal => value < 0 || paymentType == 'withdrawal';

  @override
  List<Object?> get props => [
    paymentId,
    propertyId,
    paymentType,
    value,
    paymentMethod,
    status,
    transferId,
    createdAt,
  ];
}

class PaymentLinkEntity extends Equatable {
  final String url;

  const PaymentLinkEntity({required this.url});

  factory PaymentLinkEntity.fromJson(Map<String, dynamic> json) {
    return PaymentLinkEntity(
      url: json['url'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [url];
}

class TransferStatusEntity extends Equatable {
  final Map<String, dynamic> data;

  const TransferStatusEntity({required this.data});

  factory TransferStatusEntity.fromJson(Map<String, dynamic> json) {
    return TransferStatusEntity(
      data: json['data'] as Map<String, dynamic>? ?? json,
    );
  }

  @override
  List<Object?> get props => [data];
}
