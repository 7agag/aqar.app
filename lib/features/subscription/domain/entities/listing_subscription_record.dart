import 'package:aqar/core/utils/parse_utils.dart';

enum ListingSubscriptionPaymentState {
  unpaid('UNPAID'),
  pending('PENDING'),
  paid('PAID');

  final String value;
  const ListingSubscriptionPaymentState(this.value);

  static ListingSubscriptionPaymentState fromValue(String v) =>
      values.firstWhere((e) => e.value == v, orElse: () => unpaid);
}

class ListingSubscriptionRecord {
  final int propertyId;
  final String subscriptionId;
  final String propertyName;
  final int planMonths;
  final double amount;
  final ListingSubscriptionPaymentState paymentState;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ListingSubscriptionRecord({
    required this.propertyId,
    required this.subscriptionId,
    required this.propertyName,
    required this.planMonths,
    required this.amount,
    required this.paymentState,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ListingSubscriptionRecord.fromJson(Map<String, dynamic> json) {
    return ListingSubscriptionRecord(
      propertyId: parseInt(json['propertyId']),
      subscriptionId: json['subscriptionId']?.toString() ?? '',
      propertyName: json['propertyName'] as String? ?? '',
      planMonths: parseInt(json['planMonths']),
      amount: parseDouble(json['amount']),
      paymentState: ListingSubscriptionPaymentState.fromValue(json['paymentState']?.toString() ?? ''),
      createdAt: DateTime.fromMillisecondsSinceEpoch(parseInt(json['createdAt'], 0)),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(parseInt(json['updatedAt'], 0)),
    );
  }

  Map<String, dynamic> toJson() => {
    'propertyId': propertyId,
    'subscriptionId': subscriptionId,
    'propertyName': propertyName,
    'planMonths': planMonths,
    'amount': amount,
    'paymentState': paymentState.value,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
  };

  ListingSubscriptionRecord copyWith({
    String? propertyName,
    ListingSubscriptionPaymentState? paymentState,
    DateTime? updatedAt,
  }) {
    return ListingSubscriptionRecord(
      propertyId: propertyId,
      subscriptionId: subscriptionId,
      propertyName: propertyName ?? this.propertyName,
      planMonths: planMonths,
      amount: amount,
      paymentState: paymentState ?? this.paymentState,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
