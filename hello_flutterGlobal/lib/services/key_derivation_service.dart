import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Key derivation service using HKDF-SHA256
/// Must match server-side implementation exactly
class KeyDerivationService {
  /// Derive a user key using HKDF-SHA256
  ///
  /// This MUST match the server implementation:
  /// - Salt: SHA256("user_{userId}")
  /// - Info: "user_{userId}:device_{deviceId}"
  /// - Output: 32 bytes (256 bits)
  ///
  /// Note: The master_secret is NEVER sent to client.
  /// For client-side derivation, we use a different approach where
  /// the server provides wrapped keys.
  static Uint8List deriveUserKey(int userId, String deviceId, Uint8List masterSecret) {
    // Create deterministic salt from user_id
    final saltInput = 'user_$userId';
    final saltBytes = utf8.encode(saltInput);
    final salt = Uint8List.fromList(sha256.convert(saltBytes).bytes);

    // Create info context
    final info = 'user_$userId:device_$deviceId';
    final infoBytes = Uint8List.fromList(utf8.encode(info));

    // Derive key using HKDF
    return hkdf(
      ikm: masterSecret,
      salt: salt,
      info: infoBytes,
      length: 32, // 256 bits
    );
  }

  /// HKDF implementation using SHA-256
  static Uint8List hkdf({
    required Uint8List ikm,
    required Uint8List salt,
    required Uint8List info,
    required int length,
  }) {
    // Extract step: HMAC-SHA256(salt, ikm)
    final prk = _hmacSha256(salt, ikm);

    // Expand step
    return _hkdfExpand(prk, info, length);
  }

  /// HKDF Extract: HMAC-SHA256(salt, ikm)
  static Uint8List _hmacSha256(Uint8List key, Uint8List data) {
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(data);
    return Uint8List.fromList(digest.bytes);
  }

  /// HKDF Expand: Generate derived key material
  static Uint8List _hkdfExpand(Uint8List prk, Uint8List info, int length) {
    final hashLen = 32; // SHA-256 output length
    final n = (length / hashLen).ceil();

    if (n > 255) {
      throw ArgumentError('Derived key too long');
    }

    final okm = <int>[];
    Uint8List tPrev = Uint8List(0);

    for (int i = 1; i <= n; i++) {
      final hmac = Hmac(sha256, prk);
      final input = [...tPrev, ...info, i];
      final t = hmac.convert(input);
      tPrev = Uint8List.fromList(t.bytes);
      okm.addAll(tPrev);
    }

    return Uint8List.fromList(okm.sublist(0, length));
  }
}

/// Content encryption service for AES-256-GCM operations
class ContentEncryptionService {
  /// Unwrap (decrypt) a content key using AES-256-GCM
  ///
  /// Args:
  ///   wrappedKey: Encrypted content key
  ///   userKey: 32-byte user key (derived via HKDF)
  ///   iv: 12-byte initialization vector
  ///   authTag: 16-byte authentication tag
  ///
  /// Returns: 32-byte content key
  static Uint8List unwrapKey({
    required Uint8List wrappedKey,
    required Uint8List userKey,
    required Uint8List iv,
    required Uint8List authTag,
  }) {
    // Combine ciphertext and auth tag for GCM decryption
    final combined = Uint8List.fromList([...wrappedKey, ...authTag]);

    // Decrypt using AES-GCM
    final cipher = GCMBlockCipher(AESEngine());
    final params = AEADParameters(
      KeyParameter(userKey),
      128, // auth tag length in bits
      iv,
      Uint8List(0), // no additional authenticated data
    );

    cipher.init(false, params); // false = decrypt

    try {
      final decrypted = cipher.process(combined);
      return decrypted;
    } catch (e) {
      throw Exception('Failed to unwrap key: Invalid authentication tag or corrupted data');
    }
  }

  /// Decrypt content using AES-256-GCM
  ///
  /// Args:
  ///   ciphertext: Encrypted content
  ///   contentKey: 32-byte content key
  ///   iv: 12-byte initialization vector
  ///   authTag: 16-byte authentication tag
  ///
  /// Returns: Decrypted content
  static Uint8List decryptContent({
    required Uint8List ciphertext,
    required Uint8List contentKey,
    required Uint8List iv,
    required Uint8List authTag,
  }) {
    // Combine ciphertext and auth tag
    final combined = Uint8List.fromList([...ciphertext, ...authTag]);

    // Decrypt using AES-GCM
    final cipher = GCMBlockCipher(AESEngine());
    final params = AEADParameters(
      KeyParameter(contentKey),
      128, // auth tag length in bits
      iv,
      Uint8List(0), // no additional authenticated data
    );

    cipher.init(false, params); // false = decrypt

    try {
      final decrypted = cipher.process(combined);
      return decrypted;
    } catch (e) {
      throw Exception('Failed to decrypt content: Invalid authentication tag or corrupted data');
    }
  }

  /// Decrypt content in streaming fashion (for large files)
  /// Processes data in chunks
  static Stream<Uint8List> decryptContentStream({
    required Stream<Uint8List> ciphertextStream,
    required Uint8List contentKey,
    required Uint8List iv,
    required Uint8List authTag,
    required int totalSize,
  }) async* {
    // For GCM, we need the entire ciphertext + tag at once for authentication
    // So we collect all chunks first
    final chunks = <Uint8List>[];
    await for (final chunk in ciphertextStream) {
      chunks.add(chunk);
    }

    // Combine all chunks
    final fullCiphertext = Uint8List.fromList(
      chunks.expand((chunk) => chunk).toList()
    );

    // Decrypt
    final decrypted = decryptContent(
      ciphertext: fullCiphertext,
      contentKey: contentKey,
      iv: iv,
      authTag: authTag,
    );

    // Yield decrypted data (can be chunked if needed)
    const chunkSize = 64 * 1024; // 64KB chunks
    for (int i = 0; i < decrypted.length; i += chunkSize) {
      final end = (i + chunkSize < decrypted.length)
          ? i + chunkSize
          : decrypted.length;
      yield decrypted.sublist(i, end);
    }
  }
}
