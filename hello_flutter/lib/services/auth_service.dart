import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'connectivity_service.dart';

import '../utils/api_constants.dart';

class AuthService {
  static const String _userKey = 'user_data';

  // Google Sign In instance
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Optional clientId
    // clientId: 'YOUR_CLIENT_ID.apps.googleusercontent.com',
    scopes: ['email'],
  );

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
    return prefs.containsKey(_userKey);
  }

  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userStr = prefs.getString(_userKey);
    if (userStr != null) {
      return json.decode(userStr);
    }
    return null;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    if (ConnectivityService().isOffline) throw Exception('Offline mode');

    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      await _saveUser(data['user']);
      return data;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['error'] ?? 'Login failed');
    }
  }

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
    String confirmPassword,
  ) async {
    if (ConnectivityService().isOffline) throw Exception('Offline mode');

    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': name,
        'email': email,
        'password': password,
        'confirm_password': confirmPassword,
      }),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else if (response.statusCode == 202) {
      // Verification required
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['error'] ?? 'Registration failed');
    }
  }

  Future<Map<String, dynamic>> verifyEmail(String email, String code) async {
    if (ConnectivityService().isOffline) throw Exception('Offline mode');

    final response = await http.post(
      Uri.parse('$baseUrl/verify-email'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'code': code}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      await _saveUser(data['user']);
      return data;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['error'] ?? 'Verification failed');
    }
  }

  Future<bool> loginWithGoogle() async {
    try {
      if (ConnectivityService().isOffline) throw Exception('Offline mode');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User canceled the sign-in
        return false;
      }

      // Obtain the auth details from the request
      // final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Send to backend to create user or login
      final response = await http.post(
        Uri.parse('$baseUrl/google-login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': googleUser.email,
          'name': googleUser.displayName,
          // 'google_id': googleUser.id,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        await _saveUser(data['user']);
        return true;
      } else {
        throw Exception('Google backend login failed');
      }
    } catch (error) {
      print('Google Sign In Error: $error');
      rethrow;
    }
  }

  Future<void> changePassword(
    int userId,
    String currentPassword,
    String newPassword,
  ) async {
    if (ConnectivityService().isOffline) throw Exception('Offline mode');

    final response = await http.post(
      Uri.parse('$baseUrl/change-password'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': userId,
        'current_password': currentPassword,
        'new_password': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      final error = json.decode(response.body);
      throw Exception(error['error'] ?? 'Password change failed');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await _googleSignIn.signOut();
  }

  Future<String> uploadProfilePicture(File imageFile, int userId) async {
    if (ConnectivityService().isOffline) throw Exception('Offline mode');

    final uri = Uri.parse('$baseUrl/upload-profile-picture');
    final request = http.MultipartRequest('POST', uri);

    request.fields['user_id'] = userId.toString();

    // Determine mime type (default to jpeg if unknown)
    final mimeType = 'image/jpeg';
    // You could use mime package to look it up from extension,
    // but simplified for now as backend checks extension.

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
      // Update local user data with new URL
      final user = await getUser();
      if (user != null) {
        // Use relative path ('path') if available to allow dynamic base URL (e.g. if Ngrok changes)
        // Fallback to 'url' only if 'path' is missing.
        user['profile_picture_url'] = data['path'] ?? data['url'];
        await _saveUser(user);
      }
      // Return the full URL for immediate display
      return data['url'] ?? data['path'];
    } else {
      final error = json.decode(response.body);
      throw Exception(error['error'] ?? 'Upload failed');
    }
  }

  Future<void> _saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(user));
  }
}
