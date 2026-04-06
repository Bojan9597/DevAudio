import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'connectivity_service.dart';
import 'auth_service.dart';
import 'api_client.dart';
import '../utils/api_constants.dart';
import '../models/subscription.dart';

class SubscriptionService {
  final AuthService _authService = AuthService();

  // Permanent local subscription record.
  // Written when user subscribes or server confirms active.
  // ONLY cleared by explicit successful cancellation.
  static const String _confirmedSubKey = 'confirmed_subscription';

  // ── Local record helpers ──────────────────────────────────────────────────

  Future<Subscription?> _getLocalSubscription(
    SharedPreferences prefs,
    int userId,
  ) async {
    final raw = prefs.getString('${_confirmedSubKey}_$userId');
    if (raw == null) return null;
    try {
      final sub = Subscription.fromJson(json.decode(raw));
      if (sub.planType == 'lifetime') return sub; // never expires
      if (sub.endDate == null) return sub;
      final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return sub.endDate! > nowSeconds ? sub : null; // expired
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveLocalSubscription(
    SharedPreferences prefs,
    int userId,
    Subscription sub,
  ) async {
    await prefs.setString('${_confirmedSubKey}_$userId', json.encode(sub.toJson()));
    print('[SubscriptionService] Local subscription saved (plan=${sub.planType}, endDate=${sub.endDate})');
  }

  Future<void> _clearLocalSubscription(
    SharedPreferences prefs,
    int userId,
  ) async {
    await prefs.remove('${_confirmedSubKey}_$userId');
    print('[SubscriptionService] Local subscription cleared');
  }

  // ── Headers ───────────────────────────────────────────────────────────────

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── Main status check ─────────────────────────────────────────────────────

  /// Returns the subscription status.
  ///
  /// Priority:
  ///   1. Local confirmed record — if valid (end date not passed) → return immediately, no server call.
  ///   2. Server — only reached if local is missing or expired.
  ///      On success: update local record.
  ///      On failure: return none (local was already expired/missing).
  ///
  /// Pass [forceRefresh] = true to bypass local and always hit the server
  /// (use only after subscribing or cancelling).
  Future<Subscription?> getSubscriptionStatus({
    bool forceRefresh = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = await _authService.getCurrentUserId();
    if (userId == null) {
      print('[SubscriptionService] No user ID');
      return null;
    }

    // ── Step 1: Local is the source of truth ─────────────────────────────
    if (!forceRefresh) {
      final local = await _getLocalSubscription(prefs, userId);
      if (local != null) {
        print('[SubscriptionService] Local subscription valid — skipping server (plan=${local.planType})');
        return local;
      }
      print('[SubscriptionService] No valid local subscription — checking server');
    }

    // ── Step 2: Server (only when local is missing/expired or forceRefresh) ─
    if (ConnectivityService().isOffline) {
      print('[SubscriptionService] Offline and no valid local subscription');
      return Subscription.none(userId);
    }

    try {
      final headers = await _getHeaders();
      final response = await ApiClient().get(
        Uri.parse('${ApiConstants.baseUrl}/subscription/status?user_id=$userId'),
        headers: headers,
      );

      print('[SubscriptionService] Server response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final subscription = Subscription.fromJson(data);

        if (subscription.isActive) {
          // Save to local so future checks never need the server
          await _saveLocalSubscription(prefs, userId, subscription);
        } else {
          // Server confirms not active — clear any stale local record
          await _clearLocalSubscription(prefs, userId);
        }

        print('[SubscriptionService] Server: isActive=${subscription.isActive}');
        return subscription;
      } else {
        print('[SubscriptionService] Server error ${response.statusCode}');
      }
    } catch (e) {
      print('[SubscriptionService] Network error: $e');
    }

    return Subscription.none(userId);
  }

  /// Returns true if the user has an active subscription.
  /// Local record is checked first — no server call if local is valid.
  Future<bool> isSubscribed({bool forceRefresh = false}) async {
    final sub = await getSubscriptionStatus(forceRefresh: forceRefresh);
    final result = sub?.isActive ?? false;
    print('[SubscriptionService] isSubscribed=$result (forceRefresh=$forceRefresh)');
    return result;
  }

  // ── Subscribe ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> subscribe(String planType) async {
    final userId = await _authService.getCurrentUserId();
    if (userId == null) return {'success': false, 'error': 'User not logged in'};

    if (ConnectivityService().isOffline) {
      return {'success': false, 'error': 'Cannot subscribe while offline'};
    }

    try {
      final headers = await _getHeaders();
      final response = await ApiClient().post(
        Uri.parse('${ApiConstants.baseUrl}/subscription/subscribe'),
        headers: headers,
        body: json.encode({'user_id': userId, 'plan_type': planType}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        // Save the local record immediately from the subscribe response —
        // no second server call. A second call risks a race condition where
        // the status endpoint hasn't updated yet and returns is_active=false,
        // which would wipe the local record and cause instant paywall after subscribing.
        int? parseEndDate(dynamic val) {
          if (val == null) return null;
          if (val is int) return val;
          if (val is String) return int.tryParse(val);
          return null;
        }

        final prefs = await SharedPreferences.getInstance();
        final confirmedSub = Subscription(
          userId: userId,
          planType: data['plan_type'] ?? planType,
          status: 'active',
          isActive: true,
          endDate: parseEndDate(data['end_date']),
        );
        await _saveLocalSubscription(prefs, userId, confirmedSub);

        return {
          'success': true,
          'message': data['message'],
          'plan_type': data['plan_type'],
          'end_date': data['end_date'],
        };
      } else {
        final error = json.decode(response.body);
        return {'success': false, 'error': error['error'] ?? 'Subscription failed'};
      }
    } catch (e) {
      print('[SubscriptionService] Subscribe error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ── Cancel ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> cancelSubscription() async {
    final userId = await _authService.getCurrentUserId();
    if (userId == null) return {'success': false, 'error': 'User not logged in'};

    if (ConnectivityService().isOffline) {
      return {'success': false, 'error': 'Cannot cancel while offline'};
    }

    try {
      final headers = await _getHeaders();
      final response = await ApiClient().post(
        Uri.parse('${ApiConstants.baseUrl}/subscription/cancel'),
        headers: headers,
        body: json.encode({'user_id': userId}),
      );

      if (response.statusCode == 200) {
        // Only clear local record after server confirms cancellation
        final prefs = await SharedPreferences.getInstance();
        await _clearLocalSubscription(prefs, userId);
        return {'success': true, 'message': 'Subscription cancelled'};
      } else {
        final error = json.decode(response.body);
        return {'success': false, 'error': error['error'] ?? 'Cancellation failed'};
      }
    } catch (e) {
      print('[SubscriptionService] Cancel error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ── Cache clear (logout) ──────────────────────────────────────────────────

  /// Clears only in-memory/temp state on logout.
  /// Does NOT clear the local subscription record — it survives logout
  /// so the user isn't locked out on next login before a server check.
  Future<void> clearCache() async {
    // Nothing to clear — the local record is intentionally permanent.
    // It will be validated against endDate on next access.
  }
}
