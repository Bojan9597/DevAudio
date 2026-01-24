import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'connectivity_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../utils/api_constants.dart';

class AuthService {
  static const String _userKey = 'user_data';
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _encryptionKeyStorageKey = 'user_encryption_key';

  final _storage = const FlutterSecureStorage();

  // Admin email for upload functionality (preparation for Google Play subscription)
  static const String adminEmail = 'bojanpejic97@gmail.com';

  // Google Sign In instance
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  /// Check if current user is admin (can upload books)
  Future<bool> isAdmin() async {
    final user = await getUser();
    if (user != null && user['email'] != null) {
      return user['email'].toString().toLowerCase() == adminEmail.toLowerCase();
    }
    return false;
  }

  String get baseUrl => ApiConstants.baseUrl;

  Future<int?> getCurrentUserId() async {
    final user = await getUser();
    if (user != null && user['id'] != null) {
      return user['id'] as int;
    }
    return null;
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_userKey) && prefs.containsKey(_accessTokenKey);
  }

  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userStr = prefs.getString(_userKey);
    if (userStr != null) {
      return json.decode(userStr);
    }
    return null;
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  Future<String?> getEncryptionKey() async {
    return await _storage.read(key: _encryptionKeyStorageKey);
  }

  Future<bool> loginWithGoogle() async {
    try {
      if (ConnectivityService().isOffline) throw Exception('Offline mode');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return false;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/google-login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': googleUser.email,
          'name': googleUser.displayName,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        await _saveUser(data['user']);
        await _saveTokens(data['access_token'], data['refresh_token']);
        return true;
      } else {
        throw Exception('Google backend login failed');
      }
    } catch (error) {
      print('Google Sign In Error: $error');
      rethrow;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_accessTokenKey);
    final refreshToken = prefs.getString(_refreshTokenKey);

    // Call backend logout to blacklist tokens
    if (token != null && !ConnectivityService().isOffline) {
      try {
        await http.post(
          Uri.parse('$baseUrl/logout'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode({'refresh_token': refreshToken}),
        );
      } catch (e) {
        print("Logout api call failed: $e");
      }
    }

    await _googleSignIn.signOut();

    // Clear shared preferences mainly, but PRESERVE offline data and user settings
    final keys = prefs.getKeys();
    for (final key in keys) {
      // Keep offline data (downloads/metadata)
      if (key.startsWith('offline_')) continue;
      // Keep user-specific theme and locale settings (per-account preferences)
      if (key.startsWith('theme_mode_')) continue;
      if (key.startsWith('locale_')) continue;

      // Remove everything else (tokens, user cache, etc.)
      await prefs.remove(key);
    }

    await _storage.delete(key: _encryptionKeyStorageKey);
  }

  Future<String> uploadProfilePicture(File imageFile, int userId) async {
    if (ConnectivityService().isOffline) throw Exception('Offline mode');

    final token = await getAccessToken();
    final uri = Uri.parse('$baseUrl/upload-profile-picture');
    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer $token';
    request.fields['user_id'] = userId.toString();

    final mimeType = 'image/jpeg';

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: MediaType.parse(mimeType),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final user = await getUser();
      if (user != null) {
        user['profile_picture_url'] = data['path'] ?? data['url'];
        await _saveUser(user);
      }
      return data['url'] ?? data['path'];
    } else {
      final error = json.decode(response.body);
      throw Exception(error['error'] ?? 'Upload failed');
    }
  }

  Future<void> _saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();

    // Extract and store AES key securely
    if (user.containsKey('aes_key')) {
      final key = user['aes_key'];
      if (key != null) {
        await _storage.write(key: _encryptionKeyStorageKey, value: key);
      }
      user.remove('aes_key'); // Don't save in shared prefs
    }

    await prefs.setString(_userKey, json.encode(user));
  }

  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
  }
}
