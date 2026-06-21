import 'package:equatable/equatable.dart';

class SubscriptionEntity extends Equatable {
  final String subscriptionId;
  final int propertyId;
  final String ownerId;
  final int planMonths;
  final double amount;
  final String status;
  final DateTime? createdAt;

  const SubscriptionEntity({
    required this.subscriptionId,
    required this.propertyId,
    required this.ownerId,
    required this.planMonths,
    required this.amount,
    required this.status,
    this.createdAt,
  });

  factory SubscriptionEntity.fromJson(Map<String, dynamic> json) {
    return SubscriptionEntity(
      subscriptionId: json['subscription_id'] as String? ?? '',
      propertyId: (json['property_id'] as num?)?.toInt() ?? 0,
      ownerId: (json['owner_id'] as String?) ?? '',
      planMonths: (json['plan_months'] as num?)?.toInt() ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'UNPAID',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  bool get isActive => status == 'PAID';
  bool get isUnpaid => status == 'UNPAID';

  @override
  List<Object?> get props => [
    subscriptionId, propertyId, ownerId, planMonths, amount, status, createdAt,
  ];
}
