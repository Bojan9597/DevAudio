import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class DownloadService {
  final Dio _dio = Dio();

  // Track ongoing downloads to prevent duplicate requests
  static final Map<String, Future<void>> _activeDownloads = {};

  Future<String> _getLocalPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<String> getLocalBookPath(String fileKey) async {
    final path = await _getLocalPath();
    // Use .enc extension for encrypted files
    return '$path/$fileKey.enc';
  }

  Future<bool> isBookDownloaded(String fileKey) async {
    final filePath = await getLocalBookPath(fileKey);
    final file = File(filePath);
    if (await file.exists()) {
      // Also verify file is not empty/corrupted (at least has IV + some data)
      final size = await file.length();
      return size > 16; // IV is 16 bytes, so valid encrypted file must be larger
    }
    return false;
  }

  /// Check if a download is currently in progress for this file
  bool isDownloadInProgress(String fileKey) {
    return _activeDownloads.containsKey(fileKey);
  }

  /// Download book from encrypted endpoint and store encrypted on device
  Future<void> downloadBook(String fileKey, String url) async {
    // If download already in progress, wait for it
    if (_activeDownloads.containsKey(fileKey)) {
      print('[DownloadService] Download already in progress for $fileKey, waiting...');
      await _activeDownloads[fileKey];
      return;
    }

    // Start new download
    final downloadFuture = _performDownload(fileKey, url);
    _activeDownloads[fileKey] = downloadFuture;

    try {
      await downloadFuture;
    } finally {
      _activeDownloads.remove(fileKey);
    }
  }

  Future<void> _performDownload(String fileKey, String url) async {
    try {
      final filePath = await getLocalBookPath(fileKey);

      // Convert URL to encrypted endpoint
      // http://host/static/AudioBooks/xxx/file.wav -> http://host/encrypted-audio/AudioBooks/xxx/file.wav
      final encryptedUrl = url.replaceFirst('/static/', '/encrypted-audio/');

      print('[DownloadService] Downloading encrypted from: $encryptedUrl');
      print('[DownloadService] Saving to: $filePath');

      // Get auth token for the encrypted endpoint
      final token = await AuthService().getAccessToken();
      if (token == null) {
        throw Exception('No auth token available for encrypted download');
      }

      // Download with auth header
      await _dio.download(
        encryptedUrl,
        filePath,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final progress = (received / total * 100).toStringAsFixed(1);
            print('[DownloadService] Progress: $progress%');
          }
        },
      );

      // Verify download
      final file = File(filePath);
      if (await file.exists()) {
        final size = await file.length();
        print('[DownloadService] Download complete. File size: $size bytes');
        if (size <= 16) {
          await file.delete();
          throw Exception('Downloaded file is too small (corrupted)');
        }
      } else {
        throw Exception('Download failed - file not created');
      }
    } catch (e) {
      print('[DownloadService] Download failed: $e');
      // Clean up partial download
      try {
        final filePath = await getLocalBookPath(fileKey);
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
      throw Exception('Failed to download book: $e');
    }
  }

  Future<void> deleteBook(String fileKey) async {
    try {
      final filePath = await getLocalBookPath(fileKey);
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
      // Also try to delete old .mp3 files (legacy)
      final legacyPath = (await _getLocalPath()) + '/$fileKey.mp3';
      final legacyFile = File(legacyPath);
      if (await legacyFile.exists()) {
        await legacyFile.delete();
      }
    } catch (e) {
      print('Delete failed: $e');
    }
  }

  /// Get the encryption key for decrypting local files
  Future<String?> getEncryptionKey() async {
    return await AuthService().getEncryptionKey();
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
