# Content Encryption Setup Guide

This guide walks you through setting up the secure content encryption architecture for your audio book platform.

## Architecture Overview

### Key Concepts

1. **Content Encryption (One-Time)**
   - Each media file is encrypted ONCE with a random 256-bit ContentKey
   - Uses AES-256-GCM for authenticated encryption
   - All users download the SAME encrypted file

2. **Key Derivation (Per User Per Device)**
   - A master secret (stored only on server) is used to derive user keys
   - Uses HKDF-SHA256 with deterministic salt and info parameters
   - Each user on each device gets a unique UserKey

3. **Key Wrapping**
   - The ContentKey is "wrapped" (encrypted) with each user's UserKey
   - Each user can only unwrap their own wrapped key
   - Wrapping uses AES-256-GCM

4. **Client Decryption**
   - Client fetches the wrapped ContentKey for their user/device
   - Client unwraps the ContentKey using their UserKey
   - Client decrypts media in-memory only (no plaintext saved to disk)

### Security Properties

✅ **Server never encrypts/decrypts per request** - Content is encrypted once
✅ **All users share the same encrypted file** - Efficient storage and delivery
✅ **Each user has their own key** - Cannot decrypt other users' content
✅ **Device-specific keys** - Different key per device for the same user
✅ **No plaintext keys sent to clients** - Master secret never leaves server
✅ **In-memory decryption only** - No decrypted files written to disk

---

## Setup Instructions

### Step 1: Database Migration

Run the database migration to add encryption tables and columns:

```bash
cd Server
python migrate_content_encryption.py
```

This creates:
- `user_content_keys` table - Stores wrapped keys per user/device/media
- `encrypted_files` table - Tracks encrypted media files
- New columns in `playlist_items` - Stores encryption metadata
- `server_config` table - Stores server configuration (master secret)

### Step 2: Initialize Master Secret

Generate and store the master secret:

```bash
python init_master_secret.py
```

**CRITICAL**:
- Back up this secret securely
- Store it in environment variables for production
- Loss of this secret = loss of all user access to content
- NEVER commit it to version control

The master secret will be displayed once. Save it somewhere secure.

### Step 3: Encrypt Existing Files

Encrypt all existing audio files:

```bash
python encrypt_existing_files.py
```

This will:
1. Find all unencrypted media in `playlist_items`
2. Encrypt each unique file with AES-256-GCM
3. Store encrypted files alongside originals (with `_encrypted` suffix)
4. Update database with encryption metadata
5. Create wrapped keys for all users with access

**Note**: Original files are kept for now. Delete them after verifying the system works.

### Step 4: Update Flutter Client

Install new dependencies:

```bash
cd ../hello_flutter
flutter pub get
```

New dependencies added:
- `pointycastle: ^3.9.1` - Cryptographic operations
- `crypto: ^3.0.3` - Hashing and HKDF
- `device_info_plus: ^11.2.0` - Device identification

### Step 5: Test the System

1. **Server Test**:
```bash
cd Server
python -c "from content_encryption import ContentEncryptionManager; print('✓ Server encryption module OK')"
```

2. **API Test**:
```bash
# Start the server
python api.py

# In another terminal, test the endpoints
curl -X GET "http://localhost:5000/v2/content-key/1?device_id=test_device" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

3. **Client Test**:
   - Build and run the Flutter app
   - Login with a test account
   - Try playing an encrypted audio file
   - Verify audio plays correctly

---

## File Structure

### Server Files

```
Server/
├── content_encryption.py          # Core encryption module
├── api_encryption_endpoints.py    # New API endpoints
├── migrate_content_encryption.py  # Database migration
├── init_master_secret.py          # Master secret setup
├── encrypt_existing_files.py      # Bulk file encryption
└── api.py                          # Main API (updated)
```

### Flutter Client Files

```
hello_flutter/lib/services/
├── device_id_manager.dart          # Device ID management
├── key_derivation_service.dart     # HKDF and AES-GCM operations
├── content_key_manager.dart        # Fetch and unwrap keys
└── encrypted_audio_source_v2.dart  # Audio source with new encryption
```

---

## API Endpoints

### v2/encrypted-audio/<path:filepath>

**GET** - Download encrypted audio file (same for all users)

Headers:
- `Authorization: Bearer <jwt_token>`
- `Range: bytes=<start>-<end>` (optional, for seeking)

Returns: Binary encrypted audio data

---

### v2/content-key/<media_id>

**GET** - Get wrapped content key for a media item

Query Parameters:
- `device_id` (required) - Device identifier

Headers:
- `Authorization: Bearer <jwt_token>`

Returns:
```json
{
  "wrapped_key": "base64_encoded_wrapped_key",
  "wrap_iv": "base64_encoded_iv",
  "wrap_auth_tag": "base64_encoded_tag",
  "content_iv": "base64_encoded_content_iv",
  "auth_tag": "base64_encoded_content_auth_tag"
}
```

---

### v2/encryption-info/<media_id>

**GET** - Get complete encryption info (convenience endpoint)

Query Parameters:
- `device_id` (required)

Headers:
- `Authorization: Bearer <jwt_token>`

Returns:
```json
{
  "media_id": 123,
  "encrypted_path": "AudioBooks/book/track_encrypted.wav",
  "file_url": "http://server/v2/encrypted-audio/...",
  "wrapped_key": "...",
  "wrap_iv": "...",
  "wrap_auth_tag": "...",
  "content_iv": "...",
  "auth_tag": "..."
}
```

---

## Key Derivation Details

### Server-Side (HKDF)

```python
# Inputs
master_secret = 32-byte secret (from server_config)
user_id = integer
device_id = string

# Process
salt = SHA256(f"user_{user_id}")
info = f"user_{user_id}:device_{device_id}".encode()

# HKDF-SHA256
user_key = HKDF(
    algorithm=SHA256,
    length=32,
    salt=salt,
    info=info,
    ikm=master_secret
)
```

### Client-Side (Key Unwrapping)

The client does NOT derive the UserKey (it doesn't have the master secret).
Instead, the server:
1. Derives the UserKey on the server
2. Uses it to wrap the ContentKey
3. Stores the wrapped key in `user_content_keys`
4. Client fetches the wrapped key and unwraps it using stored UserKey

**Note**: The UserKey itself could be sent to the client once during login and stored securely.
For this implementation, we rely on server-side key management.

---

## Troubleshooting

### "Master secret not found"
- Run `python init_master_secret.py`

### "Content key not found"
- Run `python encrypt_existing_files.py`
- Ensure the media file exists in database

### "Wrapped key not found"
- User may not have access to the book
- Re-run `encrypt_existing_files.py` to regenerate wrapped keys

### "Failed to decrypt: Invalid authentication tag"
- Content was corrupted during transmission
- Wrapped key doesn't match the content key
- Check database integrity

### Audio won't play on client
- Check Flutter console for errors
- Verify device_id is being generated
- Ensure user has valid JWT token
- Test API endpoints directly with curl

---

## Security Considerations

### ✅ DO:
- Store master secret in environment variables in production
- Use HTTPS for all API communication
- Rotate master secret periodically (requires re-wrapping all keys)
- Monitor for suspicious key access patterns
- Implement rate limiting on key endpoints

### ❌ DON'T:
- Commit master secret to git
- Log encryption keys or master secret
- Send plaintext ContentKey to clients
- Store decrypted audio on client disk
- Reuse IVs for encryption

---

## Production Deployment

### Environment Variables

```bash
# .env
MASTER_SECRET=<your_base64_master_secret>
DB_HOST=localhost
DB_NAME=audiobooks
DB_USER=root
DB_PASSWORD=<your_password>
```

### Load Master Secret from Environment

Update `content_encryption.py`:

```python
import os

def _get_master_secret(self):
    if self._master_secret is None:
        # Try environment variable first
        secret_b64 = os.getenv('MASTER_SECRET')
        if secret_b64:
            self._master_secret = base64.b64decode(secret_b64)
        else:
            # Fallback to database
            query = "SELECT config_value FROM server_config WHERE config_key = 'master_secret'"
            result = self.db.execute_query(query)
            if not result:
                raise ValueError("Master secret not found!")
            self._master_secret = base64.b64decode(result[0]['config_value'])
    return self._master_secret
```

### Key Rotation Strategy

To rotate the master secret:

1. Generate new master secret
2. Derive new UserKeys for all users
3. Re-wrap all ContentKeys with new UserKeys
4. Update `user_content_keys` table
5. Update master secret in secure storage
6. No need to re-encrypt content files

---

## Performance Considerations

### Server
- ContentKey wrapping is fast (AES-GCM operation)
- Key lookups are indexed by (user_id, device_id, media_id)
- No per-request encryption/decryption overhead

### Client
- First play requires downloading full encrypted file and decrypting
- Subsequent seeks use cached decrypted data
- Memory usage: ~file_size during playback
- Consider implementing chunked decryption for very large files

### Optimization Tips
- Implement CDN for encrypted file distribution
- Cache wrapped keys on client (they don't change)
- Pre-fetch wrapped keys for upcoming tracks
- Clear decrypted audio cache when memory is low

---

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review server logs for error details
3. Test API endpoints with curl to isolate client vs server issues
4. Verify database schema matches migration

---

## License & Credits

Content encryption architecture designed for secure audiobook delivery.
Implements industry-standard AES-256-GCM and HKDF-SHA256.
