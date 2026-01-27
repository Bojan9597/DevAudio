class ApiConstants {
  // Production Server
  static const String baseUrl = 'https://velorus.ba/devaudioserver2';

  // Local Development URLs (Ignored when using production URL above in main.dart or api_client.dart)
  // But let's make sure everything points to production for now.
  static String get localBaseUrl {
    return baseUrl;
  }
}
