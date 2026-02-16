import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'connectivity_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'daily_goal_service.dart';

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

  Future<Map<String, dynamic>> getUserPreferences() async {
    final user = await getUser();
    if (user != null &&
        user.containsKey('preferences') &&
        user['preferences'] != null) {
      if (user['preferences'] is String) {
        try {
          return Map<String, dynamic>.from(json.decode(user['preferences']));
        } catch (e) {
          print("Error parsing preferences JSON: $e");
          return {};
        }
      }
      return Map<String, dynamic>.from(user['preferences']);
    }
    return {};
  }

  /// Check if user has completed onboarding preferences.
  /// If the field is missing (user logged in before this feature), default to true.
  Future<bool> hasPreferences() async {
    final user = await getUser();
    if (user != null) {
      if (!user.containsKey('has_preferences')) return true;
      return user['has_preferences'] == true;
    }
    return false;
  }

  /// Mark preferences as completed locally (after saving to server)
  Future<void> setHasPreferences(bool value) async {
    final user = await getUser();
    if (user != null) {
      user['has_preferences'] = value;
      await _saveUser(user);
    }
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
        headers: {
          'Content-Type': 'application/json',
          ApiConstants.appSourceHeader: ApiConstants.appSourceValue,
        },
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
        throw Exception(
          'Google backend login failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (error) {
      print('Google Sign In Error: $error');
      rethrow;
    }
  }

  Future<bool> deleteAccount() async {
    if (ConnectivityService().isOffline) return false;

    final token = await getAccessToken();
    if (token == null) return false;

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/delete-account'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          ApiConstants.appSourceHeader: ApiConstants.appSourceValue,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting account: $e');
      return false;
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
            ApiConstants.appSourceHeader: ApiConstants.appSourceValue,
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

  Future<void> refreshUserProfile() async {
    if (ConnectivityService().isOffline) return;

    final token = await getAccessToken();
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          ApiConstants.appSourceHeader: ApiConstants.appSourceValue,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['user'] != null) {
          await _saveUser(data['user']);
        }
      }
    } catch (e) {
      print('Error refreshing user profile: $e');
    }
  }

  Future<bool> saveUserPreferences({
    required int userId,
    List<int>? bookIds,
    List<String>? categories,
    int? dailyGoalMinutes,
    String? primaryGoal,
  }) async {
    if (ConnectivityService().isOffline) throw Exception('Offline mode');

    String? token = await getAccessToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/preferences'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          ApiConstants.appSourceHeader: ApiConstants.appSourceValue,
        },
        body: json.encode({
          'user_id': userId,
          if (bookIds != null) 'book_ids': bookIds,
          if (categories != null) 'categories': categories,
          if (dailyGoalMinutes != null) 'daily_goal_minutes': dailyGoalMinutes,
          if (primaryGoal != null) 'primary_goal': primaryGoal,
        }),
      );

      if (response.statusCode == 200) {
        await refreshUserProfile();
        if (dailyGoalMinutes != null) {
          DailyGoalService().updateTarget(dailyGoalMinutes);
        }
        return true;
      } else if (response.statusCode == 401) {
        // Try refresh
        print("401 saving preferences, attempting refresh...");
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          token = await getAccessToken();
          if (token == null) return false;

          // Retry
          final response2 = await http.post(
            Uri.parse('$baseUrl/user/preferences'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
              ApiConstants.appSourceHeader: ApiConstants.appSourceValue,
            },
            body: json.encode({
              'user_id': userId,
              if (bookIds != null) 'book_ids': bookIds,
              if (categories != null) 'categories': categories,
              if (dailyGoalMinutes != null)
                'daily_goal_minutes': dailyGoalMinutes,
              if (primaryGoal != null) 'primary_goal': primaryGoal,
            }),
          );

          if (response2.statusCode == 200) {
            await refreshUserProfile();
            if (dailyGoalMinutes != null) {
              DailyGoalService().updateTarget(dailyGoalMinutes);
            }
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      print('Error saving user preferences: $e');
      return false;
    }
  }

  Future<String> uploadProfilePicture(File imageFile, int userId) async {
    if (ConnectivityService().isOffline) throw Exception('Offline mode');

    final token = await getAccessToken();
    final uri = Uri.parse('$baseUrl/upload-profile-picture');
    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer $token';
    request.headers[ApiConstants.appSourceHeader] = ApiConstants.appSourceValue;
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

  /// Public method to save user data from combined endpoints
  Future<void> saveUserData(Map<String, dynamic> user) async {
    await _saveUser(Map<String, dynamic>.from(user));
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

  // Subscription cache (in-memory with TTL)
  static bool? _cachedSubscriptionStatus;
  static DateTime? _subscriptionCacheTime;
  static const Duration _subscriptionCacheTTL = Duration(minutes: 5);

  static const String _subscriptionStatusKey =
      'subscription_status_persistence';

  /// Set subscription status from external source (e.g., /discover endpoint)
  /// This avoids needing a separate API call
  Future<void> setSubscriptionStatus(bool isSubscribed) async {
    _cachedSubscriptionStatus = isSubscribed;
    _subscriptionCacheTime = DateTime.now();

    // Persist to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_subscriptionStatusKey, isSubscribed);
  }

  /// Get persisted subscription status immediately
  Future<bool> getPersistentSubscriptionStatus() async {
    // Check memory cache first
    if (_isSubscriptionCacheValid()) {
      return _cachedSubscriptionStatus!;
    }

    // Check SharedPreferences persistence
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(_subscriptionStatusKey)) {
      return prefs.getBool(_subscriptionStatusKey) ?? false;
    }
    return false;
  }

  /// Check if subscription cache is still valid
  bool _isSubscriptionCacheValid() {
    if (_cachedSubscriptionStatus == null || _subscriptionCacheTime == null) {
      return false;
    }
    return DateTime.now().difference(_subscriptionCacheTime!) <
        _subscriptionCacheTTL;
  }

  Future<bool> isSubscribed() async {
    // Return cached value if still valid
    if (_isSubscriptionCacheValid()) {
      return _cachedSubscriptionStatus!;
    }

    try {
      if (ConnectivityService().isOffline)
        return await getPersistentSubscriptionStatus();

      final userId = await getCurrentUserId();
      if (userId == null) return false;

      final token = await getAccessToken();
      if (token == null) return false;

      final response = await http.get(
        Uri.parse('$baseUrl/subscription/status?user_id=$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          ApiConstants.appSourceHeader: ApiConstants.appSourceValue,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final isActive = data['is_active'] == true;

        // Cache the result
        await setSubscriptionStatus(isActive);

        return isActive;
      }
      return false;
    } catch (e) {
      print('Error checking subscription: $e');
      // If error (e.g. network issue), return persisted status if available
      return await getPersistentSubscriptionStatus();
    }
  }

  /// Clear subscription cache (call on logout)
  Future<void> clearSubscriptionCache() async {
    _cachedSubscriptionStatus = null;
    _subscriptionCacheTime = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_subscriptionStatusKey);
  }

  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
  }

  Future<bool> refreshAccessToken() async {
    try {
      if (ConnectivityService().isOffline) return false;

      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString(_refreshTokenKey);

      if (refreshToken == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/refresh-token'),
        headers: {
          'Content-Type': 'application/json',
          ApiConstants.appSourceHeader: ApiConstants.appSourceValue,
        },
        body: json.encode({'refresh_token': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newAccessToken = data['access_token'];
        if (newAccessToken != null) {
          await prefs.setString(_accessTokenKey, newAccessToken);
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error refreshing token: $e');
      return false;
    }
  }
}
