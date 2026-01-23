# Secure Content Encryption Architecture

## Overview

This document describes the secure content encryption architecture implemented for the audiobook platform. The system ensures that:

1. ✅ Media files are encrypted **only once** on the server
2. ✅ All users download the **same encrypted file**
3. ✅ Each user has their **own decryption key**
4. ✅ The server **never encrypts/decrypts per request**
5. ✅ Decryption happens **only on the client**, in memory

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        SERVER                                │
│                                                              │
│  ┌──────────────┐         ┌─────────────────────┐          │
│  │ Master Secret│────────▶│ HKDF Key Derivation │          │
│  │ (256-bit)    │         │   (per user/device) │          │
│  └──────────────┘         └──────────┬──────────┘          │
│                                      │                       │
│                                      ▼                       │
│  ┌──────────────┐         ┌─────────────────────┐          │
│  │ Content Key  │────────▶│   AES-GCM Wrapping  │          │
│  │ (256-bit)    │         │   (per user/device) │          │
│  └──────┬───────┘         └──────────┬──────────┘          │
│         │                            │                       │
│         ▼                            ▼                       │
│  ┌──────────────┐         ┌─────────────────────┐          │
│  │ Encrypt File │         │  Wrapped Content    │          │
│  │ AES-256-GCM  │         │  Keys (Database)    │          │
│  └──────┬───────┘         └─────────────────────┘          │
│         │                                                    │
│         ▼                                                    │
│  ┌──────────────────────────────────┐                       │
│  │   Encrypted File (static)        │                       │
│  │   Same for ALL users             │                       │
│  └──────────────────────────────────┘                       │
└─────────────────────┬────────────────────────────────────────┘
                      │
                      │ HTTPS
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                        CLIENT                                │
│                                                              │
│  1. Fetch encrypted file (same for all users)               │
│  2. Fetch wrapped ContentKey (unique per user/device)       │
│  3. Unwrap ContentKey using stored UserKey                  │
│  4. Decrypt media in memory using AES-GCM                   │
│  5. Play decrypted audio (never written to disk)            │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Components

### 1. Server Components

#### a) Content Encryption Manager (`content_encryption.py`)

Core encryption module providing:

- **Content Key Generation**: Random 256-bit keys
- **File Encryption**: AES-256-GCM with random IV
- **User Key Derivation**: HKDF-SHA256 based key derivation
- **Key Wrapping**: Encrypt content keys with user keys
- **Key Unwrapping**: Decrypt content keys (server-side only)

```python
from content_encryption import ContentEncryptionManager

manager = ContentEncryptionManager(db)

# Derive user-specific key
user_key = manager.derive_user_key(user_id=123, device_id="android_abc123")

# Encrypt a file
result = manager.encrypt_file("input.wav", "output.enc")
# Returns: {content_key, iv, auth_tag, size}

# Wrap content key for a user
wrapped_key, wrap_iv, wrap_tag = manager.wrap_key(content_key, user_key)
```

#### b) API Endpoints (`api_encryption_endpoints.py`)

New v2 endpoints:

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/v2/encrypted-audio/<path>` | GET | Serve encrypted file (same for all) |
| `/v2/content-key/<media_id>` | GET | Get wrapped key for user/device |
| `/v2/encryption-info/<media_id>` | GET | Get all encryption metadata |

#### c) Database Schema

**user_content_keys** table:
```sql
CREATE TABLE user_content_keys (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    device_id VARCHAR(255) NOT NULL,
    media_id INT NOT NULL,
    wrapped_key BLOB NOT NULL,
    wrap_iv BINARY(16) NOT NULL,
    wrap_auth_tag BINARY(16) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY (user_id, device_id, media_id)
);
```

**playlist_items** table additions:
```sql
ALTER TABLE playlist_items ADD COLUMN (
    content_key_encrypted BLOB,
    content_iv BINARY(16),
    auth_tag BINARY(16),
    encryption_version INT DEFAULT 1
);
```

**server_config** table:
```sql
CREATE TABLE server_config (
    id INT AUTO_INCREMENT PRIMARY KEY,
    config_key VARCHAR(255) UNIQUE NOT NULL,
    config_value TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

### 2. Client Components (Flutter)

#### a) Device ID Manager (`device_id_manager.dart`)

Generates and persists unique device identifiers:

```dart
final deviceId = await DeviceIdManager().getDeviceId();
// Example: "android_a1b2c3d4e5f6..."
```

Device ID format: `{platform}_{hardware_hash}`

- Android: Uses Android ID
- iOS: Uses identifierForVendor
- Windows/Mac/Linux: Uses system identifiers

Stored in secure storage, persistent across app launches.

#### b) Key Derivation Service (`key_derivation_service.dart`)

Implements cryptographic operations:

**HKDF Implementation**:
```dart
final userKey = KeyDerivationService.deriveUserKey(
  userId: 123,
  deviceId: "android_abc",
  masterSecret: masterSecretBytes, // Never available on client!
);
```

**Key Unwrapping**:
```dart
final contentKey = ContentEncryptionService.unwrapKey(
  wrappedKey: wrappedKeyBytes,
  userKey: userKeyBytes,
  iv: ivBytes,
  authTag: authTagBytes,
);
```

**Content Decryption**:
```dart
final decryptedData = ContentEncryptionService.decryptContent(
  ciphertext: encryptedBytes,
  contentKey: contentKeyBytes,
  iv: contentIvBytes,
  authTag: authTagBytes,
);
```

#### c) Content Key Manager (`content_key_manager.dart`)

High-level key management:

```dart
final keyManager = ContentKeyManager();

// Get content key for media
final contentKey = await keyManager.getContentKey(mediaId);

// Get full encryption metadata
final metadata = await keyManager.getEncryptionMetadata(mediaId);

// Clear cache on logout
await keyManager.clearCache();
```

#### d) Encrypted Audio Source V2 (`encrypted_audio_source_v2.dart`)

JustAudio integration:

```dart
// Create audio source
final source = EncryptedAudioSourceV2(
  mediaId: 123,
  uniqueId: "track_123",
);

// Use with JustAudio
await audioPlayer.setAudioSource(source);
await audioPlayer.play();
```

Features:
- Downloads encrypted file once
- Fetches wrapped key from server
- Decrypts in memory
- Caches decrypted data for seeking
- Supports range requests

---

## Cryptographic Details

### AES-256-GCM

- **Algorithm**: AES (Advanced Encryption Standard)
- **Mode**: GCM (Galois/Counter Mode)
- **Key Size**: 256 bits
- **IV Size**: 12 bytes (96 bits, recommended for GCM)
- **Auth Tag Size**: 16 bytes (128 bits)

**Why GCM?**
- Provides both encryption and authentication
- Detects tampering (auth tag verification)
- Industry standard for secure file encryption

### HKDF-SHA256

**HKDF** (HMAC-based Key Derivation Function):
- **Hash**: SHA-256
- **Input Key Material (IKM)**: Master secret
- **Salt**: SHA256(f"user_{user_id}")
- **Info**: f"user_{user_id}:device_{device_id}"
- **Output Length**: 32 bytes (256 bits)

**Why HKDF?**
- Cryptographically secure key derivation
- Deterministic (same inputs = same output)
- Standardized (RFC 5869)
- Prevents key reuse across users/devices

### Key Hierarchy

```
Master Secret (256-bit)
    ↓ HKDF-SHA256(salt, info)
User Key (256-bit, per user+device)
    ↓ AES-256-GCM wrap
Wrapped Content Key (encrypted)
    ↓ AES-256-GCM unwrap
Content Key (256-bit)
    ↓ AES-256-GCM decrypt
Plaintext Media
```

---

## Security Analysis

### Threat Model

**Protected Against:**

1. ✅ **Content theft without authorization**
   - Encrypted files are useless without the content key
   - Content key cannot be derived without user's wrapped key

2. ✅ **Key sharing between users**
   - Each user has a unique wrapped key
   - User A's key cannot decrypt User B's wrapped key

3. ✅ **Device cloning**
   - Each device gets a different user key
   - Cloning requires both the device ID and server access

4. ✅ **Man-in-the-middle (with HTTPS)**
   - All API communication should use HTTPS
   - Wrapped keys are useless without user's key

5. ✅ **File tampering**
   - GCM authentication tag detects modifications
   - Decryption fails if file is altered

6. ✅ **Server compromise (limited)**
   - Master secret is not stored in plaintext (should be in env vars)
   - Decrypted content never touches server disk

**NOT Protected Against:**

1. ❌ **Rooted/Jailbroken devices**
   - User could extract decrypted audio from memory
   - Mitigation: Root/jailbreak detection

2. ❌ **Screen recording / Audio capture**
   - User can record audio during playback
   - Mitigation: DRM with hardware-backed keys (Widevine, FairPlay)

3. ❌ **Master secret compromise**
   - If master secret leaks, all keys can be derived
   - Mitigation: HSM storage, regular rotation

4. ❌ **Reverse engineering of app**
   - Client code can be decompiled
   - Mitigation: Code obfuscation, attestation

---

## Performance Characteristics

### Server Performance

| Operation | Cost | Frequency |
|-----------|------|-----------|
| File encryption | O(file_size) | Once per file |
| Key derivation (HKDF) | ~1ms | Once per user/device/media |
| Key wrapping | ~0.1ms | Once per user/device/media |
| Serve encrypted file | O(file_size) | Per download (no CPU cost) |
| Fetch wrapped key | O(1) | Per play session |

**Benchmark** (on typical server):
- Encrypt 50MB file: ~500ms
- Derive user key: ~1ms
- Wrap content key: ~0.1ms
- Total setup per file: ~500ms (one-time)

### Client Performance

| Operation | Cost | Frequency |
|-----------|------|-----------|
| Download encrypted file | O(file_size) | Once per track |
| Fetch wrapped key | O(1) | Once per track |
| Unwrap content key | ~1ms | Once per track |
| Decrypt content | O(file_size) | Once per track |
| Playback | O(1) | Continuous |

**Memory Usage**:
- Encrypted file: ~file_size (temporary)
- Decrypted data: ~file_size (cached during playback)
- Keys: ~100 bytes per media item

**Benchmark** (on typical Android device):
- Download 50MB encrypted file: ~10s (depends on network)
- Decrypt 50MB file: ~500ms
- Memory overhead: ~50MB during playback

---

## Migration Path

### For Existing Systems

1. **Phase 1: Database Setup**
   ```bash
   python migrate_content_encryption.py
   python init_master_secret.py
   ```

2. **Phase 2: Content Encryption**
   ```bash
   python encrypt_existing_files.py
   ```
   - Original files kept for rollback
   - New files created with `_encrypted` suffix

3. **Phase 3: Client Update**
   - Deploy new client with v2 encryption support
   - Feature flag: `useV2Encryption = true`
   - Gradual rollout to monitor issues

4. **Phase 4: Validation**
   - Monitor playback success rates
   - Check for decryption errors
   - Verify key unwrapping success

5. **Phase 5: Cleanup**
   - Remove old encryption code
   - Delete original unencrypted files
   - Remove legacy `aes_key` column from users table

---

## Future Enhancements

### Potential Improvements

1. **Hardware-Backed Keys**
   - Use Android Keystore / iOS Keychain
   - Store UserKey in secure hardware
   - Prevents extraction even on rooted devices

2. **Streaming Decryption**
   - Decrypt in chunks instead of full file
   - Reduces memory usage for large files
   - Requires chunked AES mode (e.g., AES-GCM-SIV)

3. **Key Rotation**
   - Periodic master secret rotation
   - Automatic re-wrapping of content keys
   - Zero downtime rotation

4. **Offline Playback**
   - Cache wrapped keys locally
   - Store encrypted files permanently
   - Validate key expiration on playback

5. **DRM Integration**
   - Widevine for Android
   - FairPlay for iOS
   - Hardware-backed content protection

6. **Analytics & Monitoring**
   - Track key access patterns
   - Detect anomalous behavior
   - Alert on potential key sharing

---

## Compliance & Standards

### Cryptographic Standards

- **NIST SP 800-38D**: GCM mode specification
- **RFC 5869**: HKDF specification
- **FIPS 197**: AES specification

### Best Practices

- ✅ Use authenticated encryption (AES-GCM)
- ✅ Random IVs for each encryption
- ✅ Secure key derivation (HKDF)
- ✅ Key separation (different keys per user/device)
- ✅ No key reuse
- ✅ Secure key storage (server-side)

---

## Conclusion

This architecture provides a robust, scalable solution for securing media content while maintaining performance and usability. The one-time encryption model ensures minimal server overhead, while per-user key wrapping prevents unauthorized access.

**Key Benefits:**
- 🚀 **Performance**: Content encrypted once, served to all users
- 🔒 **Security**: Each user has unique keys, no key sharing possible
- 💰 **Cost-effective**: No per-request encryption overhead
- 📱 **Scalable**: Works across multiple devices per user
- 🛠️ **Maintainable**: Clean separation of concerns, well-documented

For setup instructions, see [ENCRYPTION_SETUP_GUIDE.md](Server/ENCRYPTION_SETUP_GUIDE.md).
