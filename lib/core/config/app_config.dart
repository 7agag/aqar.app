class AppConfig {
  // الروابط الأساسية كـ Constants لضمان الأداء الأفضل
  static const String _serverUrl = 'https://aqar.dpdns.org';
  static const String _vercelUrl = 'https://aqar-tan.vercel.app';

  /// الرابط الأساسي للسيرفر (API)
  static String get baseUrl => _serverUrl;

  /// الرابط الخاص بصفحات الويب (للتحويلات)
  static String get webUrl => _serverUrl;

  /// رابط استقبال الدفع (Payment Callback)
  static String get paymentCallbackUrl {
    // نستخدم _vercelUrl دائماً للـ Callback لضمان الاتساق
    return '$_vercelUrl/payment-callback';
  }

  /// رابط الدفع للفاتورة (Invoice)
  static String invoiceCallbackUrl(String invoiceId) =>
      '$paymentCallbackUrl?type=invoice&invoice_id=$invoiceId';

  /// رابط الدفع للرعاية (Sponsorship)
  static String sponsorshipCallbackUrl(int propertyId) =>
      '$paymentCallbackUrl?type=sponsor&propertyId=$propertyId';

  /// رابط الدفع للاشتراكات (Subscription)
  static String subscriptionCallbackUrl(
          int propertyId, String subscriptionId) =>
      '$paymentCallbackUrl?type=subscription&propertyId=$propertyId&subscriptionId=$subscriptionId';

  /// رابط الصور (يدعم متغيرات البيئة للـ Production/Staging)
  static String get imageBaseUrl {
    const env = String.fromEnvironment('IMAGE_BASE_URL');
    return env.isNotEmpty ? env : _serverUrl;
  }

  /// رابط خدمة الذكاء الاصطناعي (AI Assistant)
  static String get aiBaseUrl {
    const env = String.fromEnvironment('AI_API_URL');
    return env.isNotEmpty ? env : 'https://web-production-c0669.up.railway.app/api/v1';
  }
}
