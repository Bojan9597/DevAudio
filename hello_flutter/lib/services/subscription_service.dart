import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'connectivity_service.dart';
import 'auth_service.dart';
import '../utils/api_constants.dart';
import '../models/subscription.dart';

class SubscriptionService {
  final AuthService _authService = AuthService();
  static const String _subscriptionCacheKey = 'subscription_status';
  static const int _cacheValidityMinutes = 5;

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Get subscription status with caching
  /// First checks local cache (with timestamp), then fetches from server if needed
  Future<Subscription?> getSubscriptionStatus({
    bool forceRefresh = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = await _authService.getCurrentUserId();

    if (userId == null) {
      print('[SubscriptionService] No user ID found');
      return null;
    }

    final cacheKey = '${_subscriptionCacheKey}_$userId';

    // Check cache first (unless force refresh)
    if (!forceRefresh) {
      final cached = prefs.getString(cacheKey);
      if (cached != null) {
        try {
          final data = json.decode(cached);
          final cachedAt = DateTime.parse(data['cached_at']);
          final subscription = Subscription.fromJson(data['subscription']);

          // Check if subscription has expired since caching
          // Note: endDate from server is in UTC, so compare with UTC time
          if (subscription.endDate != null &&
              subscription.endDate!.isBefore(DateTime.now().toUtc())) {
            // Subscription expired - clear cache and fetch fresh
            print(
              '[SubscriptionService] Cached subscription expired, fetching fresh',
            );
            await prefs.remove(cacheKey);
            // Recursive call with forceRefresh to get fresh data immediately
            return getSubscriptionStatus(forceRefresh: true);
          } else if (DateTime.now().toUtc().difference(cachedAt).inMinutes <
              _cacheValidityMinutes) {
            // Cache still valid
            print(
              '[SubscriptionService] Using cached subscription: isActive=${subscription.isActive}',
            );
            return subscription;
          } else {
            print(
              '[SubscriptionService] Cache expired (>$_cacheValidityMinutes min), fetching fresh',
            );
          }
        } catch (e) {
          print('[SubscriptionService] Error parsing cached subscription: $e');
        }
      } else {
        print('[SubscriptionService] No cached subscription found');
      }
    }

    // Fetch from server
    try {
      if (ConnectivityService().isOffline) {
        // Return cached even if expired when offline
        final cached = prefs.getString(cacheKey);
        if (cached != null) {
          final data = json.decode(cached);
          print('[SubscriptionService] Offline - using cached data');
          return Subscription.fromJson(data['subscription']);
        }
        print('[SubscriptionService] Offline - no cache, returning none');
        return Subscription.none(userId);
      }

      final headers = await _getHeaders();
      print('[SubscriptionService] Fetching from server for user $userId');
      final response = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}/subscription/status?user_id=$userId',
        ),
        headers: headers,
      );

      print('[SubscriptionService] Server response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('[SubscriptionService] Server data: $data');

        // Cache the result
        await prefs.setString(
          cacheKey,
          json.encode({
            'subscription': data,
            'cached_at': DateTime.now().toIso8601String(),
          }),
        );

        final subscription = Subscription.fromJson(data);
        print(
          '[SubscriptionService] Parsed subscription: isActive=${subscription.isActive}, status=${subscription.status}',
        );
        return subscription;
      } else {
        print('[SubscriptionService] Server error: ${response.body}');
      }
    } catch (e) {
      print('[SubscriptionService] Error fetching subscription status: $e');
    }

    print('[SubscriptionService] Returning none subscription');
    return Subscription.none(userId);
  }

  /// Quick check if user is subscribed (uses cache)
  Future<bool> isSubscribed({bool forceRefresh = false}) async {
    final sub = await getSubscriptionStatus(forceRefresh: forceRefresh);
    if (sub == null) return false;

    // If we forced a refresh, trust the server's judgment completely.
    // The server handles the time comparison and sets 'isActive'.
    // This avoids issues with local clock drift vs server time.
    if (forceRefresh) {
      print('[SubscriptionService] isSubscribed (fresh): ${sub.isActive}');
      return sub.isActive;
    }

    // If using cache, check for expiration locally
    if (sub.endDate != null && sub.endDate!.isBefore(DateTime.now().toUtc())) {
      print(
        '[SubscriptionService] Cached subscription expired locally (endDate=${sub.endDate}), checking server...',
      );

      // Force refresh to confirm with server
      final freshSub = await getSubscriptionStatus(forceRefresh: true);
      if (freshSub != null) {
        print(
          '[SubscriptionService] Server confirmed status: ${freshSub.isActive}',
        );
        // Trust the server's isActive flag for the fresh data
        return freshSub.isActive;
      }
      return false;
    }

    print('[SubscriptionService] isSubscribed (cache): ${sub.isActive}');
    return sub.isActive;
  }

  /// Subscribe user to a plan
  Future<Map<String, dynamic>> subscribe(String planType) async {
    final userId = await _authService.getCurrentUserId();
    if (userId == null) {
      return {'success': false, 'error': 'User not logged in'};
    }

    try {
      if (ConnectivityService().isOffline) {
        return {'success': false, 'error': 'Cannot subscribe while offline'};
      }

      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/subscription/subscribe'),
        headers: headers,
        body: json.encode({'user_id': userId, 'plan_type': planType}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Clear cache to force refresh
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('${_subscriptionCacheKey}_$userId');

        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'],
          'plan_type': data['plan_type'],
          'end_date': data['end_date'],
        };
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Subscription failed',
        };
      }
    } catch (e) {
      print('Error subscribing: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Cancel subscription
  Future<Map<String, dynamic>> cancelSubscription() async {
    final userId = await _authService.getCurrentUserId();
    if (userId == null) {
      return {'success': false, 'error': 'User not logged in'};
    }

    try {
      if (ConnectivityService().isOffline) {
        return {'success': false, 'error': 'Cannot cancel while offline'};
      }

      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/subscription/cancel'),
        headers: headers,
        body: json.encode({'user_id': userId}),
      );

      if (response.statusCode == 200) {
        // Clear cache
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('${_subscriptionCacheKey}_$userId');

        return {'success': true, 'message': 'Subscription cancelled'};
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Cancellation failed',
        };
      }
    } catch (e) {
      print('Error cancelling subscription: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Clear subscription cache (e.g., on logout)
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = await _authService.getCurrentUserId();
    if (userId != null) {
      await prefs.remove('${_subscriptionCacheKey}_$userId');
    }
  }
}
