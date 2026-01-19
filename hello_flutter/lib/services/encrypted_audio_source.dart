import 'dart:async';
import 'dart:io';
import 'package:just_audio/just_audio.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
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
class EncryptedHttpSource extends StreamAudioSource {
  final String url; // The static URL (will be converted to encrypted endpoint)
  final String uniqueId;
  final String keyString;
  final String? authToken; // JWT token for authenticated requests

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

  Future<File> _downloadToTemp() async {
    final encryptedUrl = _getEncryptedUrl();
    print("[DEBUG][EncryptedHttpSource] Downloading from: $encryptedUrl");

    final tempDir = await getTemporaryDirectory();
    // Use unique cache key based on URL hash to avoid stale data
    final cacheKey = url.hashCode.toString();
    final tempFile = File('${tempDir.path}/enc_stream_$cacheKey.enc');

    // Always download fresh from server (server encrypts on-the-fly)
    if (await tempFile.exists()) {
      await tempFile.delete();
    }

    // Prepare request with auth token
    final headers = <String, String>{};
    if (authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
      print("[DEBUG][EncryptedHttpSource] Using auth token");
    } else {
      // Try to get token from AuthService
      final token = await AuthService().getAccessToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
        print("[DEBUG][EncryptedHttpSource] Got token from AuthService");
      }
    }

    print("[DEBUG][EncryptedHttpSource] Downloading...");
    final response = await http.get(Uri.parse(encryptedUrl), headers: headers);

    print(
      "[DEBUG][EncryptedHttpSource] Response: ${response.statusCode}, size: ${response.bodyBytes.length}",
    );

    if (response.statusCode == 200) {
      await tempFile.writeAsBytes(response.bodyBytes);
      print(
        "[DEBUG][EncryptedHttpSource] Saved encrypted data to: ${tempFile.path}",
      );
      return tempFile;
    } else {
      throw Exception(
        "Failed to download encrypted audio: ${response.statusCode} - ${response.body}",
      );
    }
  }

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    print("[DEBUG][EncryptedHttpSource] request(start=$start, end=$end)");
    final file = await _downloadToTemp();
    print(
      "[DEBUG][EncryptedHttpSource] Using key: ${keyString.substring(0, 10)}...",
    );
    final source = EncryptedFileSource(file, uniqueId, keyString);
    return source.request(start, end);
  }
}
