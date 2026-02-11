import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_constants.dart';
import '../services/auth_service.dart';
import '../models/user_stats.dart';

class StatsService {
  final AuthService _authService = AuthService();

  Future<UserStats?> getUserStats() async {
    final user = await _authService.getUser();
    if (user == null) return null;

    final userId = user['id'];
    final url = Uri.parse('${ApiConstants.baseUrl}/user/stats?user_id=$userId');

    // We need the token for @jwt_required
    final token = await _authService.getAccessToken();

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          ...ApiConstants.imageHeaders, // Contains X-App-Source
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UserStats.fromJson(data);
      } else {
        print('Failed to load stats: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching stats: $e');
      return null;
    }
  }
}
