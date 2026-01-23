import 'dart:io';

class ApiConstants {
  // 1. Uncomment the Ngrok URL below when using Ngrok.
  // 2. Run: ngrok http 5000
  // 3. Paste your URL here:
  static const String baseUrl = 'http://10.135.54.89:5000';

  // Local Development URLs
  static String get localBaseUrl {
    // If you have a specific Ngrok URL set above, you can return it directly:
    // return 'https://your-url.ngrok-free.app';

    if (Platform.isAndroid) {
      // Android Emulator uses 10.0.2.2 usually, but for Physical Device use your LAN IP.
      return 'http://10.135.54.89:5000';
    }
    return 'http://127.0.0.1:5000';
  }
}
