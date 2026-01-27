import 'dart:async';
import 'dart:io';
import 'package:just_audio/just_audio.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:http/http.dart' as http;
import 'auth_service.dart';

/// Decrypts an encrypted file for playback.
/// File format: [16-byte IV] + [AES-CBC encrypted data with PKCS7 padding]
class EncryptedFileSource extends StreamAudioSource {
  final File file;
  final String uniqueId;
  final enc.Key key;

  EncryptedFileSource(this.file, this.uniqueId, String keyString)
    : key = enc.Key.fromBase64(keyString);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    // For simplicity, decrypt entire file at once
    // In production, you'd want chunked decryption

    final fileBytes = await file.readAsBytes();

    if (fileBytes.length < 16) {
      throw Exception("Invalid encrypted file: too small");
    }

    // Extract IV (first 16 bytes) and ciphertext
    final iv = enc.IV(fileBytes.sublist(0, 16));
    final ciphertext = enc.Encrypted(fileBytes.sublist(16));

    // Decrypt
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final decryptedBytes = encrypter.decryptBytes(ciphertext, iv: iv);

    // Handle range request
    start ??= 0;
    end ??= decryptedBytes.length;

    if (start < 0) start = 0;
    if (end > decryptedBytes.length) end = decryptedBytes.length;

    final resultBytes = decryptedBytes.sublist(start, end);

    return StreamAudioResponse(
      sourceLength: decryptedBytes.length,
      contentLength: resultBytes.length,
      offset: start,
      stream: Stream.value(resultBytes),
      contentType: 'audio/mpeg',
    );
  }
}

/// Downloads encrypted audio from server and decrypts for playback.
/// Server encrypts on-the-fly with user's AES key.
/// Caches the decrypted data in memory to avoid re-downloading on every request.
class EncryptedHttpSource extends StreamAudioSource {
  final String url; // The static URL (will be converted to encrypted endpoint)
  final String uniqueId;
  final String keyString;
  final String? authToken; // JWT token for authenticated requests

  // Cache decrypted data in memory to avoid re-downloading on every request()
  List<int>? _cachedDecryptedData;
  bool _isDownloading = false;
  Completer<void>? _downloadCompleter;

  EncryptedHttpSource(
    this.url,
    this.uniqueId,
    this.keyString, {
    this.authToken,
  });

  /// Convert static URL to encrypted endpoint URL
  String _getEncryptedUrl() {
    // Convert: http://host/static/AudioBooks/xxx/file.wav
    // To:      http://host/encrypted-audio/AudioBooks/xxx/file.wav
    return url.replaceFirst('/static/', '/encrypted-audio/');
  }

  /// Download, decrypt, and cache the audio data (only once per instance)
  Future<List<int>> _getDecryptedData() async {
    // Return cached data if available
    if (_cachedDecryptedData != null) {
      print("[DEBUG][EncryptedHttpSource] Using cached decrypted data");
      return _cachedDecryptedData!;
    }

    // Wait if another request is already downloading
    if (_isDownloading) {
      print("[DEBUG][EncryptedHttpSource] Waiting for ongoing download...");
      await _downloadCompleter?.future;
      if (_cachedDecryptedData != null) {
        return _cachedDecryptedData!;
      }
    }

    // Start download
    _isDownloading = true;
    _downloadCompleter = Completer<void>();

    try {
      final encryptedUrl = _getEncryptedUrl();
      print("[DEBUG][EncryptedHttpSource] Downloading from: $encryptedUrl");

      // Prepare request with auth token
      final headers = <String, String>{};
      if (authToken != null) {
        headers['Authorization'] = 'Bearer $authToken';
      } else {
        final token = await AuthService().getAccessToken();
        if (token != null) {
          headers['Authorization'] = 'Bearer $token';
        }
      }

      print("[DEBUG][EncryptedHttpSource] Downloading...");
      final response = await http.get(Uri.parse(encryptedUrl), headers: headers);

      print(
        "[DEBUG][EncryptedHttpSource] Response: ${response.statusCode}, size: ${response.bodyBytes.length}",
      );

      if (response.statusCode != 200) {
        throw Exception(
          "Failed to download encrypted audio: ${response.statusCode} - ${response.body}",
        );
      }

      final encryptedBytes = response.bodyBytes;
      if (encryptedBytes.length < 16) {
        throw Exception("Invalid encrypted file: too small");
      }

      // Decrypt the data
      print("[DEBUG][EncryptedHttpSource] Decrypting...");
      final iv = enc.IV(encryptedBytes.sublist(0, 16));
      final ciphertext = enc.Encrypted(encryptedBytes.sublist(16));
      final key = enc.Key.fromBase64(keyString);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      _cachedDecryptedData = encrypter.decryptBytes(ciphertext, iv: iv);

      print(
        "[DEBUG][EncryptedHttpSource] Decrypted size: ${_cachedDecryptedData!.length} bytes (cached)",
      );

      return _cachedDecryptedData!;
    } finally {
      _isDownloading = false;
      _downloadCompleter?.complete();
    }
  }

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    print("[DEBUG][EncryptedHttpSource] request(start=$start, end=$end)");

    final decryptedBytes = await _getDecryptedData();

    // Handle range request
    start ??= 0;
    end ??= decryptedBytes.length;

    if (start < 0) start = 0;
    if (end > decryptedBytes.length) end = decryptedBytes.length;

    final resultBytes = decryptedBytes.sublist(start, end);

    return StreamAudioResponse(
      sourceLength: decryptedBytes.length,
      contentLength: resultBytes.length,
      offset: start,
      stream: Stream.value(resultBytes),
      contentType: 'audio/mpeg',
    );
  }
}
