class ApiConstants {
  // Production Server
  static const String baseUrl = 'https://echo.velorus.ba';

  // Local Development URLs (Ignored when using production URL above in main.dart or api_client.dart)
  // But let's make sure everything points to production for now.
  static String get localBaseUrl {
    return baseUrl;
  }

  // Security
  static const String appSourceHeader = 'X-App-Source';
  static const String appSourceValue =
      'Echo_Secured_9xQ2zP5mL8kR4wN1vJ7'; // Stronger secret

  // Headers for image/media requests (WAF requires mobile User-Agent)
  static const Map<String, String> imageHeaders = {
    appSourceHeader: appSourceValue,
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
  };
}
