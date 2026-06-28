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
      propertyId: (json['propertyId'] as num).toInt(),
      subscriptionId: json['subscriptionId'] as String,
      propertyName: json['propertyName'] as String? ?? '',
      planMonths: (json['planMonths'] as num).toInt(),
      amount: (json['amount'] as num).toDouble(),
      paymentState: ListingSubscriptionPaymentState.fromValue(json['paymentState'] as String),
      createdAt: DateTime.fromMillisecondsSinceEpoch((json['createdAt'] as num).toInt()),
      updatedAt: DateTime.fromMillisecondsSinceEpoch((json['updatedAt'] as num).toInt()),
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
