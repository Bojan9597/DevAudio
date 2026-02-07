import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../main.dart'; // For navigatorKey
import '../screens/login_screen.dart';
import '../utils/api_constants.dart';
import '../l10n/generated/app_localizations.dart';

class ApiClient {
  // Singleton pattern
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final AuthService _authService = AuthService();

  // Helper to handle response
  Future<http.Response> _handleResponse(http.Response response) async {
    if (response.statusCode == 401) {
      // Token Expired / Unauthorized
      print('[ApiClient] 401 Unauthorized detected. Logging out...');

      await _authService.logout();

      final context = navigatorKey.currentContext;
      if (context != null) {
        // Show dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.sessionExpired),
            content: Text(AppLocalizations.of(context)!.sessionExpiredMessage),
            actions: [
              TextButton(
                onPressed: () {
                  // Close dialog
                  Navigator.of(context).pop();
                  // Navigate to Login
                  // Clear stack to prevent back button
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                },
                child: Text(AppLocalizations.of(context)!.ok),
              ),
            ],
          ),
        );
      }
    }
    return response;
  }

  // Helper to inject security headers
  Map<String, String> _addSecurityHeaders(Map<String, String>? headers) {
    final newHeaders = headers ?? {};
    newHeaders[ApiConstants.appSourceHeader] = ApiConstants.appSourceValue;
    return newHeaders;
  }

  // Helper to perform request with retry on 401
  Future<http.Response> _performRequest(
    String method,
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    // 1. Prepare initial request
    final finalHeaders = _addSecurityHeaders(headers);

    // Helper to execute the actual HTTP call
    Future<http.Response> send() async {
      switch (method) {
        case 'GET':
          return await http.get(url, headers: finalHeaders);
        case 'POST':
          return await http.post(url, headers: finalHeaders, body: body);
        case 'PUT':
          return await http.put(url, headers: finalHeaders, body: body);
        case 'DELETE':
          return await http.delete(url, headers: finalHeaders, body: body);
        default:
          throw Exception('Method not supported');
      }
    }

    var response = await send();

    // 2. Check for 401
    if (response.statusCode == 401) {
      print('[ApiClient] 401 Unauthorized. Attempting refresh...');
      final refreshSuccess = await _authService.refreshAccessToken();

      if (refreshSuccess) {
        print('[ApiClient] Refresh successful. Retrying request...');
        // Update Authorization header with new token
        final newToken = await _authService.getAccessToken();
        if (newToken != null) {
          finalHeaders['Authorization'] = 'Bearer $newToken';
        }

        // Retry
        response = await send();
      } else {
        print('[ApiClient] Refresh failed.');
      }
    }

    // 3. Handle final response (logs out if still 401)
    return _handleResponse(response);
  }

  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    return _performRequest('GET', url, headers: headers);
  }

  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return _performRequest('POST', url, headers: headers, body: body);
  }

  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return _performRequest('PUT', url, headers: headers, body: body);
  }

  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return _performRequest('DELETE', url, headers: headers, body: body);
  }
}
