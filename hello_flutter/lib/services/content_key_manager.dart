import 'dart:typed_data';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'device_id_manager.dart';
import 'key_derivation_service.dart';
import 'auth_service.dart';

/// Manages content keys for encrypted media
/// Handles fetching wrapped keys from server and unwrapping them
class ContentKeyManager {
  static final ContentKeyManager _instance = ContentKeyManager._internal();
  factory ContentKeyManager() => _instance;
  ContentKeyManager._internal();

  final _storage = const FlutterSecureStorage();
  final _dio = Dio();
  final _deviceIdManager = DeviceIdManager();
  final _authService = AuthService();

  // Cache unwrapped content keys in memory (media_id -> content_key)
  final Map<int, Uint8List> _contentKeyCache = {};

  // Cache encryption metadata (media_id -> metadata)
  final Map<int, EncryptionMetadata> _metadataCache = {};

  /// Get content key for a media item
  /// Returns the unwrapped content key ready for decryption
  Future<Uint8List> getContentKey(int mediaId) async {
    // Check cache first
    if (_contentKeyCache.containsKey(mediaId)) {
      return _contentKeyCache[mediaId]!;
    }

    // Fetch and unwrap key
    final contentKey = await _fetchAndUnwrapKey(mediaId);
    _contentKeyCache[mediaId] = contentKey;
    return contentKey;
  }

  /// Get encryption metadata for a media item
  Future<EncryptionMetadata> getEncryptionMetadata(int mediaId) async {
    // Check cache first
    if (_metadataCache.containsKey(mediaId)) {
      return _metadataCache[mediaId]!;
    }

    // Fetch from server
    final metadata = await _fetchEncryptionInfo(mediaId);
    _metadataCache[mediaId] = metadata;
    return metadata;
  }

  /// Fetch and unwrap content key from server
  Future<Uint8List> _fetchAndUnwrapKey(int mediaId) async {
    try {
      final deviceId = await _deviceIdManager.getDeviceId();
      final token = await _authService.getAccessToken();

      if (token == null) {
        throw Exception('Not authenticated');
      }

      // Get base URL from auth service
      final baseUrl = _authService.baseUrl;

      // Fetch wrapped key from server
      final response = await _dio.get(
        '$baseUrl/v2/content-key/$mediaId',
        queryParameters: {'device_id': deviceId},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch content key: ${response.statusCode}');
      }

      final data = response.data;

      // Decode base64 values
      final wrappedKey = base64.decode(data['wrapped_key']);
      final wrapIv = base64.decode(data['wrap_iv']);
      final wrapAuthTag = base64.decode(data['wrap_auth_tag']);

      // Get user ID
      final userId = await _authService.getCurrentUserId();
      if (userId == null) {
        throw Exception('User ID not found');
      }

      // Note: In the real implementation, we don't have the master_secret on client
      // The server should have already derived and stored the wrapped key
      // We just need to derive our UserKey and unwrap the content key

      // For this to work, we need the user key derivation to happen on server
      // and the client just needs to fetch the already-wrapped key

      // Since we can't derive UserKey on client (no master secret),
      // we'll use a different approach: fetch the pre-wrapped key

      // The wrapped_key from server is already wrapped with our UserKey
      // But we need UserKey to unwrap it... This is a circular dependency

      // SOLUTION: Store a user-specific wrapping key in secure storage
      // that was initially derived on the server and sent once during login

      // Get user wrapping key from secure storage
      final userKeyB64 = await _storage.read(key: 'user_key_$userId');
      if (userKeyB64 == null) {
        throw Exception('User key not found. Please re-login.');
      }

      final userKey = base64.decode(userKeyB64);

      // Unwrap content key
      final contentKey = ContentEncryptionService.unwrapKey(
        wrappedKey: Uint8List.fromList(wrappedKey),
        userKey: Uint8List.fromList(userKey),
        iv: Uint8List.fromList(wrapIv),
        authTag: Uint8List.fromList(wrapAuthTag),
      );

      return contentKey;
    } catch (e) {
      print('Error fetching/unwrapping content key: $e');
      rethrow;
    }
  }

  /// Fetch complete encryption info for a media item
  Future<EncryptionMetadata> _fetchEncryptionInfo(int mediaId) async {
    try {
      final deviceId = await _deviceIdManager.getDeviceId();
      final token = await _authService.getAccessToken();

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final baseUrl = await _authService.getBaseUrl();

      final response = await _dio.get(
        '$baseUrl/v2/encryption-info/$mediaId',
        queryParameters: {'device_id': deviceId},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch encryption info: ${response.statusCode}');
      }

      final data = response.data;

      return EncryptionMetadata(
        mediaId: data['media_id'],
        encryptedPath: data['encrypted_path'],
        fileUrl: data['file_url'],
        wrappedKey: base64.decode(data['wrapped_key']),
        wrapIv: base64.decode(data['wrap_iv']),
        wrapAuthTag: base64.decode(data['wrap_auth_tag']),
        contentIv: base64.decode(data['content_iv']),
        authTag: base64.decode(data['auth_tag']),
      );
    } catch (e) {
      print('Error fetching encryption info: $e');
      rethrow;
    }
  }

  /// Store user-specific wrapping key (called during login)
  /// This key is derived on the server and sent to client once
  Future<void> storeUserKey(int userId, String deviceId, Uint8List userKey) async {
    final keyB64 = base64.encode(userKey);
    await _storage.write(key: 'user_key_$userId', value: keyB64);
  }

  /// Clear all cached keys (on logout)
  Future<void> clearCache() async {
    _contentKeyCache.clear();
    _metadataCache.clear();
  }

  /// Clear user key (on logout)
  Future<void> clearUserKey(int userId) async {
    await _storage.delete(key: 'user_key_$userId');
  }
}

/// Encryption metadata for a media item
class EncryptionMetadata {
  final int mediaId;
  final String encryptedPath;
  final String fileUrl;
  final Uint8List wrappedKey;
  final Uint8List wrapIv;
  final Uint8List wrapAuthTag;
  final Uint8List contentIv;
  final Uint8List authTag;

  EncryptionMetadata({
    required this.mediaId,
    required this.encryptedPath,
    required this.fileUrl,
    required this.wrappedKey,
    required this.wrapIv,
    required this.wrapAuthTag,
    required this.contentIv,
    required this.authTag,
  });
}
