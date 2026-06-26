class PaymentResultEntity {
  final bool success;
  final String? transactionId;
  final String? message;

  const PaymentResultEntity({
    required this.success,
    this.transactionId,
    this.message,
  });
}
