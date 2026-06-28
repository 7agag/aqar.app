import 'package:equatable/equatable.dart';

class SponsorEntity extends Equatable {
  final int propertyId;
  final int duration;
  final double amount;
  final String? checkoutUrl;
  final String status;

  const SponsorEntity({
    required this.propertyId,
    required this.duration,
    required this.amount,
    this.checkoutUrl,
    required this.status,
  });

  factory SponsorEntity.fromJson(Map<String, dynamic> json) {
    return SponsorEntity(
      propertyId: (json['property_id'] as num?)?.toInt() ?? 0,
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      checkoutUrl: json['url'] as String?,
      status: json['status'] as String? ?? 'PENDING',
    );
  }

  bool get isActive => status == 'ACTIVE';

  @override
  List<Object?> get props => [
    propertyId, duration, amount, checkoutUrl, status,
  ];
}
