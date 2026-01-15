import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DownloadService {
  final Dio _dio = Dio();

  Future<String> _getLocalPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<String> getLocalBookPath(String fileKey) async {
    final path = await _getLocalPath();
    // Assuming mp3 for now, matching the URLs
    return '$path/$fileKey.mp3';
  }

  Future<bool> isBookDownloaded(String fileKey) async {
    final filePath = await getLocalBookPath(fileKey);
    return File(filePath).exists();
  }

  Future<void> downloadBook(String fileKey, String url) async {
    try {
      final filePath = await getLocalBookPath(fileKey);
      await _dio.download(url, filePath);
    } catch (e) {
      print('Download failed: $e');
      throw Exception('Failed to download book');
    }
  }

  Future<void> deleteBook(String fileKey) async {
    try {
      final filePath = await getLocalBookPath(fileKey);
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Delete failed: $e');
    }
  }

  // --- Playlist Metadata Management ---

  Future<void> savePlaylistJson(
    String bookId,
    Map<String, dynamic> data,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('offline_playlist_json_$bookId', json.encode(data));
  }

  Future<Map<String, dynamic>?> getPlaylistJson(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('offline_playlist_json_$bookId');
    if (data != null) {
      return json.decode(data);
    }
    return null;
  }

  Future<bool> isPlaylistDownloaded(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('offline_playlist_json_$bookId');
  }

  // --- Quiz Metadata Management ---

  Future<void> saveQuizJson(
    String bookId,
    List<dynamic> data, {
    int? playlistItemId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = playlistItemId != null
        ? 'offline_quiz_json_${bookId}_$playlistItemId'
        : 'offline_quiz_json_$bookId';
    await prefs.setString(key, json.encode(data));
  }

  Future<List<dynamic>?> getQuizJson(
    String bookId, {
    int? playlistItemId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = playlistItemId != null
        ? 'offline_quiz_json_${bookId}_$playlistItemId'
        : 'offline_quiz_json_$bookId';

    final String? data = prefs.getString(key);
    if (data != null) {
      return json.decode(data);
    }
    return null;
  }

  // --- Generic File Download ---

  Future<void> downloadFile(String url, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);

      // Skip if exists
      if (await file.exists()) return;

      await _dio.download(url, filePath);
    } catch (e) {
      print('Failed to download file $fileName: $e');
    }
  }

  Future<String> getLocalFilePath(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$fileName';
  }
}
