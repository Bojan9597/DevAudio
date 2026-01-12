import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/badge.dart';
import '../models/book.dart';
import '../models/category.dart'; // Import Category
import '../utils/api_constants.dart';

import 'package:shared_preferences/shared_preferences.dart';

class BookRepository {
  Future<List<Book>> getBooks() async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}/books?limit=1000',
        ), // Fetch all for legacy/offline
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        // Cache data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_books', response.body);
        return data.map((json) => Book.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load books');
      }
    } catch (e) {
      print('Error fetching books: $e. Trying cache...');
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('cached_books');
      if (cachedData != null) {
        final List<dynamic> data = json.decode(cachedData);
        return data.map((json) => Book.fromJson(json)).toList();
      }
      return []; // Return empty list only if both network and cache fail
    }
  }

  Future<List<Book>> getDiscoverBooks({
    int page = 1,
    int limit = 5,
    String query = '',
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/books').replace(
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
          if (query.isNotEmpty) 'q': query,
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Book.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load discover books');
      }
    } catch (e) {
      print('Error fetching discover books: $e');
      return [];
    }
  }

  /// Returns all books whose [categoryId] or any [subcategoryIds] match [clickedCategoryId]
  /// or match any [allCategoryIds] which represents the clicked category and its descendants.
  List<Book> filterBooks(
    String clickedCategoryId,
    List<Book> allBooks, {
    List<Category> allCategories = const [],
  }) {
    if (clickedCategoryId.isEmpty) return allBooks;

    // 1. Gather all IDs that represent this category (including itself and descendants)
    final Set<String> targetIds = {clickedCategoryId};

    if (allCategories.isNotEmpty) {
      // Find the clicked category object
      // Note: This only finds top-level. If clicked is nested, we need recursive search.
      // But typically filtering is only enabled for categories visible in sidebar.
      // Better: Recursively collecting descendants.
      final descendants = _getDescendantIds(clickedCategoryId, allCategories);
      targetIds.addAll(descendants);
    }

    return allBooks.where((book) {
      final matchesCategory = targetIds.contains(book.categoryId);
      final matchesSub = book.subcategoryIds.any(
        (id) => targetIds.contains(id),
      );
      return matchesCategory || matchesSub;
    }).toList();
  }

  /// Recursively finds all descendant category IDs for a given [parentId].
  List<String> _getDescendantIds(String parentId, List<Category> categories) {
    List<String> descendants = [];

    for (var cat in categories) {
      if (cat.id == parentId) {
        // Found (top level), collect all children recursively
        if (cat.children != null) {
          descendants.addAll(_getAllIds(cat.children!));
        }
      } else {
        // Not found at this level, recurse down
        if (cat.children != null) {
          descendants.addAll(_getDescendantIds(parentId, cat.children!));
        }
      }
    }
    return descendants;
  }

  List<String> _getAllIds(List<Category> categories) {
    List<String> ids = [];
    for (var cat in categories) {
      ids.add(cat.id);
      if (cat.children != null) {
        ids.addAll(_getAllIds(cat.children!));
      }
    }
    return ids;
  }

  Future<List<String>> getPurchasedBookIds(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/user-books/$userId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        // Cache data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_user_books_$userId', response.body);
        return data.map((e) => e.toString()).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching purchased books: $e. Trying cache...');
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('cached_user_books_$userId');
      if (cachedData != null) {
        final List<dynamic> data = json.decode(cachedData);
        return data.map((e) => e.toString()).toList();
      }
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
    // ... existing ...
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/user-stats/$userId'),
      );

      if (response.statusCode == 200) {
        // Cache data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_stats_$userId', response.body);
        return json.decode(response.body);
      }
      return {'total_listening_time_seconds': 0, 'books_completed': 0};
    } catch (e) {
      print('Error fetching stats: $e. Trying cache...');
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('cached_stats_$userId');
      if (cachedData != null) {
        return json.decode(cachedData);
      }
      return {'total_listening_time_seconds': 0, 'books_completed': 0};
    }
  }

  Future<List<int>> getFavoriteBookIds(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/favorites/$userId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => e as int).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching favorites: $e');
      return [];
    }
  }

  Future<bool> toggleFavorite(
    int userId,
    String bookId,
    bool isFavorite,
  ) async {
    // if currently isFavorite, we want to remove it (delete)
    // if currently!isFavorite, we want to add it (post)
    // WAIT: logic usually is 'setFavorite(bool)'.
    // If I pass 'isFavorite' as 'the desired state' -> No, usually toggle takes current state
    // Let's assume argument `isFavorite` means "Is it currently favorite?".

    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/favorites');
      final body = json.encode({
        'user_id': userId,
        'book_id': int.parse(bookId),
      });

      http.Response response;
      if (isFavorite) {
        // Remove
        response = await http.delete(
          url,
          headers: {'Content-Type': 'application/json'},
          body: body,
        );
      } else {
        // Add
        response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: body,
        );
      }

      return response.statusCode == 200;
    } catch (e) {
      print('Error toggling favorite: $e');
      return false;
    }
  }

  Future<void> uploadBook({
    required String title,
    required String author,
    required String categoryId,
    required String userId,
    required String audioPath,
    String? coverPath,
    String description = '',
    double price = 0.0,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/upload_book');
    final request = http.MultipartRequest('POST', uri);

    request.fields['title'] = title;
    request.fields['author'] = author;
    request.fields['category_id'] = categoryId;
    request.fields['user_id'] = userId;
    request.fields['description'] = description;
    request.fields['price'] = price.toString();

    request.files.add(await http.MultipartFile.fromPath('audio', audioPath));

    if (coverPath != null && coverPath.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath('cover', coverPath));
    }

    final response = await request.send();

    if (response.statusCode != 200 && response.statusCode != 201) {
      final respStr = await response.stream.bytesToString();
      throw Exception('Failed to upload book: $respStr');
    }
  }

  Future<List<Book>> getMyUploadedBooks(String userId) async {
    try {
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}/my_uploads?user_id=$userId',
      );
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Book.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load my uploads');
      }
    } catch (e) {
      print('Error fetching my uploads: $e');
      return [];
    }
  }
}
