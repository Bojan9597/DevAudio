import 'dart:convert';

import 'package:http/http.dart' as http;
import '../models/category.dart';
import '../utils/api_constants.dart';

import 'package:shared_preferences/shared_preferences.dart';

class CategoryRepository {
  Future<List<Category>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/categories'),
        headers: {ApiConstants.appSourceHeader: ApiConstants.appSourceValue},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        // Cache data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_categories', response.body);
        return data.map((json) => Category.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      print('Error fetching categories: $e. Trying cache...');
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('cached_categories');
      if (cachedData != null) {
        final List<dynamic> data = json.decode(cachedData);
        return data.map((json) => Category.fromJson(json)).toList();
      }
      // Re-throw if no cache available so UI can handle it (or return empty)
      // For consistency with BookRepository, let's return empty or rethrow.
      // Returning empty might show empty screen, rethrow shows error.
      // SideMenu expects a list, let's return default empty list to avoid crashes,
      // but usually we want to show some "Retry" UI.
      // However, BookRepository returns empty list. Let's do same here or stick to rethrow?
      // SideMenu calls it in FutureBuilder.
      // Let's stick to existing behavior if cache misses: rethrow.
      throw e;
    }
  }
}
