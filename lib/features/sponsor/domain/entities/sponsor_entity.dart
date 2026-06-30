import 'package:equatable/equatable.dart';
import 'package:aqar/core/utils/parse_utils.dart';

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
      propertyId: parseInt(json['property_id']),
      duration: parseInt(json['duration']),
      amount: parseDouble(json['amount']),
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
