import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart' as enc;

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
    // Use .audio extension for decrypted files (stored securely in app-private storage)
    return '$path/$fileKey.audio';
  }

  Future<bool> isBookDownloaded(String fileKey) async {
    final filePath = await getLocalBookPath(fileKey);
    final file = File(filePath);
    if (await file.exists()) {
      // Verify file is not empty/corrupted
      final size = await file.length();
      if (size > 0) {
        return true;
      }
    }

    // Clean up old .enc files (legacy format) - they need to be re-downloaded
    final basePath = await _getLocalPath();
    final oldEncPath = '$basePath/$fileKey.enc';
    final oldEncFile = File(oldEncPath);
    if (await oldEncFile.exists()) {
      print('[DownloadService] Found legacy .enc file, will be re-downloaded: $oldEncPath');
      await oldEncFile.delete();
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

      // Get auth token for the encrypted endpoint
      final authService = AuthService();
      final token = await authService.getAccessToken();
      if (token == null) {
        throw Exception('No auth token available for encrypted download');
      }

      // Get encryption key for decryption
      final encryptionKey = await authService.getEncryptionKey();
      if (encryptionKey == null) {
        throw Exception('No encryption key available. Please re-login.');
      }

      // Download to a temporary file first
      final tempPath = '$filePath.tmp';
      print('[DownloadService] Downloading to temp: $tempPath');

      // Download with auth header
      await _dio.download(
        encryptedUrl,
        tempPath,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final progress = (received / total * 100).toStringAsFixed(1);
            print('[DownloadService] Download progress: $progress%');
          }
        },
      );

      // Verify encrypted download
      final tempFile = File(tempPath);
      if (!await tempFile.exists()) {
        throw Exception('Download failed - temp file not created');
      }

      final encryptedBytes = await tempFile.readAsBytes();
      print('[DownloadService] Downloaded encrypted size: ${encryptedBytes.length} bytes');

      if (encryptedBytes.length <= 16) {
        await tempFile.delete();
        throw Exception('Downloaded file is too small (corrupted)');
      }

      // Decrypt the file
      print('[DownloadService] Decrypting...');
      final decryptedBytes = _decryptAudio(encryptedBytes, encryptionKey);
      print('[DownloadService] Decrypted size: ${decryptedBytes.length} bytes');

      // Write decrypted audio to final path
      final outputFile = File(filePath);
      await outputFile.writeAsBytes(decryptedBytes);
      print('[DownloadService] Saved decrypted audio to: $filePath');

      // Clean up temp file
      await tempFile.delete();

      // Verify final file
      final finalSize = await outputFile.length();
      print('[DownloadService] Download complete. Final file size: $finalSize bytes');

      if (finalSize == 0) {
        await outputFile.delete();
        throw Exception('Decryption failed - output file is empty');
      }
    } catch (e) {
      print('[DownloadService] Download failed: $e');
      // Clean up partial downloads
      try {
        final filePath = await getLocalBookPath(fileKey);
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
        final tempFile = File('$filePath.tmp');
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (_) {}
      throw Exception('Failed to download book: $e');
    }
  }

  /// Decrypt AES-CBC encrypted audio bytes
  /// Format: [16-byte IV] + [AES-CBC encrypted data with PKCS7 padding]
  List<int> _decryptAudio(Uint8List encryptedBytes, String keyString) {
    // Extract IV (first 16 bytes) and ciphertext
    final iv = enc.IV(Uint8List.fromList(encryptedBytes.sublist(0, 16)));
    final ciphertext = enc.Encrypted(Uint8List.fromList(encryptedBytes.sublist(16)));

    // Create key from base64 string
    final key = enc.Key.fromBase64(keyString);

    // Decrypt using AES-CBC
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    return encrypter.decryptBytes(ciphertext, iv: iv);
  }

  Future<void> deleteBook(String fileKey) async {
    try {
      final basePath = await _getLocalPath();

      // Delete current .audio file
      final filePath = await getLocalBookPath(fileKey);
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }

      // Also try to delete old .enc files (legacy encrypted)
      final encPath = '$basePath/$fileKey.enc';
      final encFile = File(encPath);
      if (await encFile.exists()) {
        await encFile.delete();
      }

      // Also try to delete old .mp3 files (legacy)
      final legacyPath = '$basePath/$fileKey.mp3';
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
