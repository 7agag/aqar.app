import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  static String get baseUrl {
    const env = String.fromEnvironment('API_BASE_URL');
    if (env.isNotEmpty) return env;
    return 'https://unburned-helmet-photo.ngrok-free.dev';
  }

  static String get paymentCallbackUrl {
    if (kIsWeb) return '$baseUrl/payment-callback';
    return 'aqar.jovek://payment-callback';
  }

  static String sponsorshipCallbackUrl(int propertyId) =>
      '$paymentCallbackUrl?type=sponsor&propertyId=$propertyId';

  static String subscriptionCallbackUrl(int propertyId, String subscriptionId) =>
      '$paymentCallbackUrl?type=subscription&propertyId=$propertyId&subscriptionId=$subscriptionId';

  static String get imageBaseUrl {
    const env = String.fromEnvironment('IMAGE_BASE_URL');
    if (env.isNotEmpty) return env;
    return baseUrl;
  }

  static String get webUrl {
    const env = String.fromEnvironment('WEB_BASE_URL');
    if (env.isNotEmpty) return env;
    return 'https://aqar.dpdns.org';
  }
}
