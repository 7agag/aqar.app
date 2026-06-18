class AppConfig {
  static String get baseUrl {
    const env = String.fromEnvironment('API_BASE_URL');
    if (env.isNotEmpty) return env;
    return 'http://localhost:8000';
  }

  static String get imageBaseUrl {
    const env = String.fromEnvironment('IMAGE_BASE_URL');
    if (env.isNotEmpty) return env;
    return baseUrl;
  }

  static String get webUrl {
    const env = String.fromEnvironment('WEB_BASE_URL');
    if (env.isNotEmpty) return env;
    return 'https://aqar.app';
  }
}
