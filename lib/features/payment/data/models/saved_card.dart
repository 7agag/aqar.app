class SavedCard {
  final String id;
  final String cardHolder;
  final String last4;
  final int expiryMonth;
  final int expiryYear;
  final String? nickname;

  const SavedCard({
    required this.id,
    required this.cardHolder,
    required this.last4,
    required this.expiryMonth,
    required this.expiryYear,
    this.nickname,
  });

  String get maskedNumber => '•••• $last4';
  String get formattedExpiry =>
      '${expiryMonth.toString().padLeft(2, '0')}/${expiryYear.toString().padLeft(2, '0')}';
}
