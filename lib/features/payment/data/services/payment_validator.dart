class PaymentValidator {
  static String? validate({required String url}) {
    if (url.isEmpty) return 'Payment link is empty';
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.isAbsolute) return 'Invalid payment link';
    return null;
  }
}