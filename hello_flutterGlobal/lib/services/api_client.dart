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

  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    final response = await http.get(url, headers: _addSecurityHeaders(headers));
    return _handleResponse(response);
  }

  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final response = await http.post(
      url,
      headers: _addSecurityHeaders(headers),
      body: body,
    );
    return _handleResponse(response);
  }

  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final response = await http.put(
      url,
      headers: _addSecurityHeaders(headers),
      body: body,
    );
    return _handleResponse(response);
  }

  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final response = await http.delete(
      url,
      headers: _addSecurityHeaders(headers),
      body: body,
    );
    return _handleResponse(response);
  }
}
