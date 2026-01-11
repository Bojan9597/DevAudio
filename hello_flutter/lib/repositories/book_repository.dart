import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/badge.dart';
import '../models/book.dart';
import '../utils/api_constants.dart';

class BookRepository {
  Future<List<Book>> getBooks() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/books'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Book.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load books');
      }
    } catch (e) {
      print('Error fetching books: $e');
      return []; // Return empty list on error
    }
  }

  /// Returns all books whose [categoryId] or any [subcategoryIds] match [clickedCategoryId].
  List<Book> filterBooks(String clickedCategoryId, List<Book> allBooks) {
    if (clickedCategoryId.isEmpty) return allBooks;

    return allBooks.where((book) {
      if (book.categoryId == clickedCategoryId) return true;
      if (book.subcategoryIds.contains(clickedCategoryId)) return true;
      return false;
    }).toList();
  }

  Future<List<String>> getPurchasedBookIds(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/user-books/$userId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => e.toString()).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching purchased books: $e');
      return [];
    }
  }

  Future<List<Badge>> buyBook(int userId, String bookId) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/buy-book'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'user_id': userId, 'book_id': int.parse(bookId)}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      if (data['new_badges'] != null) {
        return (data['new_badges'] as List).map((e) {
          e['isEarned'] = true;
          return Badge.fromJson(e);
        }).toList();
      }
      return [];
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to buy book');
    }
  }

  Future<List<Badge>> getBadges(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/badges/$userId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Badge.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load badges');
      }
    } catch (e) {
      print('Error fetching badges: $e');
      return [];
    }
  }

  Future<List<Badge>> updateProgress(
    int userId,
    String bookId,
    int positionSeconds,
    int? duration,
  ) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/update-progress'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': userId,
        'book_id': int.parse(bookId),
        'position_seconds': positionSeconds,
        'duration': duration,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['new_badges'] != null) {
        return (data['new_badges'] as List).map((e) {
          e['isEarned'] = true;
          return Badge.fromJson(e);
        }).toList();
      }
    } else {
      print('Failed to update progress: ${response.body}');
    }
    return [];
  }

  Future<int> getBookStatus(int userId, String bookId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/book-status/$userId/$bookId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['position_seconds'] ?? 0;
      }
      return 0;
    } catch (e) {
      print('Error fetching book status: $e');
      return 0;
    }
  }

  Future<List<Book>> getListenHistory(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/listen-history/$userId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Book.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching history: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getUserStats(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/user-stats/$userId'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'total_listening_time_seconds': 0, 'books_completed': 0};
    } catch (e) {
      print('Error fetching stats: $e');
      return {'total_listening_time_seconds': 0, 'books_completed': 0};
    }
  }
}
