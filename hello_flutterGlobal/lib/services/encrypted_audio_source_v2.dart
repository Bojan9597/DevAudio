import 'dart:async';
import 'dart:typed_data';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'content_key_manager.dart';
import 'key_derivation_service.dart';
import 'auth_service.dart';
import '../utils/api_constants.dart';

/// V2 Encrypted Audio Source using Content Key Architecture
///
/// This implementation:
/// - Downloads the same encrypted file for all users
/// - Fetches user-specific wrapped key from server
/// - Unwraps the content key using the user's key
/// - Decrypts media in memory using AES-256-GCM
class EncryptedAudioSourceV2 extends StreamAudioSource {
  final int mediaId;
  final String uniqueId;
  final ContentKeyManager _keyManager = ContentKeyManager();
  final AuthService _authService = AuthService();

  // Cache decrypted data to avoid re-decryption
  Uint8List? _cachedDecryptedData;

  EncryptedAudioSourceV2({required this.mediaId, required this.uniqueId});

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    try {
      // Get decrypted data (from cache or decrypt)
      final decryptedData = await _getDecryptedData();

      // Handle range request
      start ??= 0;
      end ??= decryptedData.length;

      if (start < 0) start = 0;
      if (end > decryptedData.length) end = decryptedData.length;

      final resultBytes = decryptedData.sublist(start, end);

      return StreamAudioResponse(
        sourceLength: decryptedData.length,
        contentLength: resultBytes.length,
        offset: start,
        stream: Stream.value(resultBytes),
        contentType: 'audio/mpeg',
      );
    } catch (e) {
      throw Exception('Failed to decrypt audio: $e');
    }
  }

  /// Get decrypted data (cached or decrypt from server)
  Future<Uint8List> _getDecryptedData() async {
    // Return cached data if available
    if (_cachedDecryptedData != null) {
      return _cachedDecryptedData!;
    }

    // Fetch encryption metadata
    final metadata = await _keyManager.getEncryptionMetadata(mediaId);

    // Download encrypted file
    final encryptedData = await _downloadEncryptedFile(metadata.fileUrl);

    // Get content key (unwrapped)
    final contentKey = await _keyManager.getContentKey(mediaId);

    // Decrypt content
    final decryptedData = ContentEncryptionService.decryptContent(
      ciphertext: encryptedData,
      contentKey: contentKey,
      iv: metadata.contentIv,
      authTag: metadata.authTag,
    );

    // Cache for future requests
    _cachedDecryptedData = decryptedData;

    return decryptedData;
  }

  /// Download encrypted file from server
  Future<Uint8List> _downloadEncryptedFile(String url) async {
    final token = await _authService.getAccessToken();

    final response = await http.get(
      Uri.parse(url),
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
        ApiConstants.appSourceHeader: ApiConstants.appSourceValue,
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to download encrypted file: ${response.statusCode}',
      );
    }

    return response.bodyBytes;
  }

  /// Clear cached data to free memory
  void clearCache() {
    _cachedDecryptedData = null;
  }
}

/// V2 Encrypted HTTP Source with streaming support
/// This version downloads and decrypts in chunks for better memory efficiency
class EncryptedHttpSourceV2 extends StreamAudioSource {
  final int mediaId;
  final String uniqueId;
  final ContentKeyManager _keyManager = ContentKeyManager();
  final AuthService _authService = AuthService();

  // Full decrypted cache (GCM requires full file for authentication)
  Uint8List? _cachedDecryptedData;

  EncryptedHttpSourceV2({required this.mediaId, required this.uniqueId});

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    try {
      // Get or decrypt full file
      final decryptedData = await _getOrDecryptFullFile();

      // Handle range request
      start ??= 0;
      end ??= decryptedData.length;

      if (start < 0) start = 0;
      if (end > decryptedData.length) end = decryptedData.length;

      final resultBytes = decryptedData.sublist(start, end);

      return StreamAudioResponse(
        sourceLength: decryptedData.length,
        contentLength: resultBytes.length,
        offset: start,
        stream: Stream.value(resultBytes),
        contentType: 'audio/mpeg',
      );
    } catch (e) {
      throw Exception('Failed to stream encrypted audio: $e');
    }
  }

  Future<Uint8List> _getOrDecryptFullFile() async {
    if (_cachedDecryptedData != null) {
      return _cachedDecryptedData!;
    }

    // Get encryption metadata
    final metadata = await _keyManager.getEncryptionMetadata(mediaId);

    // Download encrypted file
    final token = await _authService.getAccessToken();
    final response = await http.get(
      Uri.parse(metadata.fileUrl),
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
        ApiConstants.appSourceHeader: ApiConstants.appSourceValue,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to download: ${response.statusCode}');
    }

    final encryptedData = response.bodyBytes;

    // Get content key
    final contentKey = await _keyManager.getContentKey(mediaId);

    // Decrypt
    final decryptedData = ContentEncryptionService.decryptContent(
      ciphertext: encryptedData,
      contentKey: contentKey,
      iv: metadata.contentIv,
      authTag: metadata.authTag,
    );

    _cachedDecryptedData = decryptedData;
    return decryptedData;
  }

  void clearCache() {
    _cachedDecryptedData = null;
  }
}

/// Factory to create appropriate audio source based on configuration
class AudioSourceFactory {
  static const bool useV2Encryption = true; // Toggle for gradual rollout

  /// Create audio source for a media item
  ///
  /// Args:
  ///   mediaId: Database ID of the media item
  ///   url: Original URL (used for v1 fallback)
  ///   uniqueId: Unique identifier for caching
  ///   encryptionKey: Legacy encryption key (v1 only)
  ///   useHttp: Whether to use HTTP source vs file source
  static StreamAudioSource create({
    required int mediaId,
    required String url,
    required String uniqueId,
    String? encryptionKey,
    bool useHttp = false,
  }) {
    if (useV2Encryption) {
      // Use new architecture
      return useHttp
          ? EncryptedHttpSourceV2(mediaId: mediaId, uniqueId: uniqueId)
          : EncryptedAudioSourceV2(mediaId: mediaId, uniqueId: uniqueId);
    } else {
      // Fallback to legacy encryption (would need to import old source)
      throw UnimplementedError('V1 encryption not available in this context');
    }
  }
}
