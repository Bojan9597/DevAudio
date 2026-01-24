import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/badge.dart';
import '../models/book.dart';
import '../models/category.dart';
import '../utils/api_constants.dart';
import '../services/connectivity_service.dart';
import '../services/auth_service.dart'; // Import AuthService

import 'package:shared_preferences/shared_preferences.dart';

class BookRepository {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<Book>> getBooks() async {
    try {
      if (ConnectivityService().isOffline) {
        throw Exception('Offline mode');
      }
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/books?limit=1000'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
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
      return [];
    }
  }

  Future<List<Book>> getDiscoverBooks({
    int page = 1,
    int limit = 5,
    String query = '',
    String? sort,
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/books').replace(
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
          if (query.isNotEmpty) 'q': query,
          if (sort != null) 'sort': sort,
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

  List<Book> filterBooks(
    String clickedCategoryId,
    List<Book> allBooks, {
    List<Category> allCategories = const [],
  }) {
    if (clickedCategoryId.isEmpty) return allBooks;

    final Set<String> targetIds = {clickedCategoryId};

    if (allCategories.isNotEmpty) {
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

  List<String> _getDescendantIds(String parentId, List<Category> categories) {
    List<String> descendants = [];
    for (var cat in categories) {
      if (cat.id == parentId) {
        if (cat.children != null) {
          descendants.addAll(_getAllIds(cat.children!));
        }
      } else {
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
      if (ConnectivityService().isOffline) {
        throw Exception('Offline mode');
      }

      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/user-books/$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
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
    if (ConnectivityService().isOffline) {
      throw Exception('Cannot purchase books while offline.');
    }

    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/buy-book'),
      headers: headers,
      body: json.encode({'user_id': userId, 'book_id': int.parse(bookId)}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final prefs = await SharedPreferences.getInstance();
      var cachedData = prefs.getString('cached_user_books_$userId');
      List<dynamic> currentBooks = [];
      if (cachedData != null) {
        currentBooks = json.decode(cachedData);
      }

      final intId = int.parse(bookId);
      if (!currentBooks.contains(intId)) {
        currentBooks.add(intId);
        await prefs.setString(
          'cached_user_books_$userId',
          json.encode(currentBooks),
        );
      }

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
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/badges/$userId'),
        headers: headers,
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
    int? duration, {
    String? playlistItemId,
  }) async {
    if (ConnectivityService().isOffline) return [];

    final Map<String, dynamic> requestBody = {
      'user_id': userId,
      'book_id': int.parse(bookId),
      'position_seconds': positionSeconds,
      'duration': duration,
    };

    if (playlistItemId != null) {
      requestBody['playlist_item_id'] = int.parse(playlistItemId);
    }

    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/update-progress'),
      headers: headers,
      body: json.encode(requestBody),
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

  Future<List<Badge>> completeTrack(int userId, String trackId) async {
    if (ConnectivityService().isOffline) return [];

    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/complete-track'),
      headers: headers,
      body: json.encode({'user_id': userId, 'track_id': trackId}),
    );

    if (response.statusCode == 200) {
      print("Track completed: $trackId");
      final data = json.decode(response.body);
      if (data['new_badges'] != null) {
        return (data['new_badges'] as List).map((e) {
          e['isEarned'] = true;
          return Badge.fromJson(e);
        }).toList();
      }
    } else {
      print('Failed to complete track: ${response.body}');
    }
    return [];
  }

  Future<int> getBookStatus(
    int userId,
    String bookId, {
    String? trackId,
  }) async {
    try {
      String url = '${ApiConstants.baseUrl}/book-status/$userId/$bookId';
      if (trackId != null) {
        url += '?playlist_item_id=$trackId';
      }

      final headers = await _getHeaders();
      final response = await http.get(Uri.parse(url), headers: headers);

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
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/listen-history/$userId'),
        headers: headers,
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
      if (ConnectivityService().isOffline) {
        throw Exception('Offline mode');
      }

      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/user-stats/$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
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
      if (ConnectivityService().isOffline) throw Exception('Offline mode');

      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/favorites/$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_favorites_$userId', response.body);
        return data.map((e) => e as int).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching favorites (or offline): $e. Trying cache...');
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('cached_favorites_$userId');
      if (cachedData != null) {
        final List<dynamic> data = json.decode(cachedData);
        return data.map((e) => e as int).toList();
      }
      return [];
    }
  }

  Future<bool> toggleFavorite(
    int userId,
    String bookId,
    bool isFavorite,
  ) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/favorites');
      final body = json.encode({
        'user_id': userId,
        'book_id': int.parse(bookId),
      });

      final headers = await _getHeaders();
      http.Response response;
      if (isFavorite) {
        response = await http.delete(url, headers: headers, body: body);
      } else {
        response = await http.post(url, headers: headers, body: body);
      }

      if (response.statusCode == 200) {
        // Invalidate cache so next fetch gets updated list
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('cached_favorites_$userId');
        return true;
      }
      return false;
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
    required List<String> audioPaths,
    String? coverPath,
    String description = '',
    double price = 0.0,
    required int duration,
    bool isEncrypted = false,
  }) async {
    if (ConnectivityService().isOffline) {
      throw Exception("Cannot upload while offline.");
    }

    final token = await _authService.getAccessToken();
    final uri = Uri.parse('${ApiConstants.baseUrl}/upload_book');
    final request = http.MultipartRequest('POST', uri);

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields['title'] = title;
    request.fields['author'] = author;
    request.fields['category_id'] = categoryId;
    request.fields['user_id'] = userId;
    request.fields['description'] = description;
    request.fields['price'] = price.toString();
    request.fields['duration'] = duration.toString();
    request.fields['is_encrypted'] = isEncrypted.toString();

    for (var path in audioPaths) {
      if (path.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('audio', path));
      }
    }

    if (coverPath != null && coverPath.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath('cover', coverPath));
    }

    final response = await request.send();

    if (response.statusCode == 200 || response.statusCode == 201) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_books');
      await prefs.remove('cached_categories');
      await prefs.remove('cached_my_uploads_$userId');
      await prefs.remove('cached_user_books_$userId');
    } else {
      final respStr = await response.stream.bytesToString();
      throw Exception('Failed to upload book: $respStr');
    }
  }

  Future<List<Book>> getMyUploadedBooks(String userId) async {
    try {
      if (ConnectivityService().isOffline) throw Exception('Offline mode');

      final uri = Uri.parse(
        '${ApiConstants.baseUrl}/my_uploads?user_id=$userId',
      );
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_my_uploads_$userId', response.body);
        return data.map((json) => Book.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load my uploads');
      }
    } catch (e) {
      print('Error fetching my uploads (or offline): $e. Trying cache...');
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('cached_my_uploads_$userId');
      if (cachedData != null) {
        final List<dynamic> data = json.decode(cachedData);
        return data.map((json) => Book.fromJson(json)).toList();
      }
      return [];
    }
  }

  /// Returns null on success, or an error message string on failure
  Future<String?> rateBook(int userId, String bookId, int stars) async {
    try {
      if (ConnectivityService().isOffline) {
        return 'Cannot rate while offline';
      }

      final headers = await _getHeaders();
      final body = json.encode({'user_id': userId, 'stars': stars});

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/books/$bookId/rate'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        return null; // Success
      } else {
        final data = json.decode(response.body);
        return data['message'] ?? data['error'] ?? 'Failed to submit rating';
      }
    } catch (e) {
      print('Error rating book: $e');
      return 'Error: $e';
    }
  }
}
