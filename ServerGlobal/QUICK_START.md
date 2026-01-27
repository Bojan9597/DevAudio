# Quick Start Guide - Content Encryption

Get up and running with the new encryption system in 5 minutes.

## Prerequisites

- Python 3.7+ installed
- MySQL database running
- Flask dependencies installed
- Flutter development environment

---

## Server Setup (3 steps)

### 1. Run Database Migration

```bash
cd Server
python migrate_content_encryption.py
```

Expected output:
```
Adding encryption fields to playlist_items...
Creating user_content_keys table...
Creating server_config table...
Creating encrypted_files table...
Migration completed successfully!
```

### 2. Initialize Master Secret

```bash
python init_master_secret.py
```

**IMPORTANT**: Save the displayed master secret securely!

### 3. Encrypt Media Files

```bash
python encrypt_existing_files.py
```

Type `yes` when prompted.

Expected output:
```
Found X unique audio files to encrypt
Encrypting: AudioBooks/...
✓ Encrypted successfully
...
Encryption complete!
✓ Encrypted: X files
```

---

## Client Setup (2 steps)

### 1. Install Dependencies

```bash
cd hello_flutter
flutter pub get
```

New packages will be installed:
- pointycastle (cryptography)
- crypto (HKDF)
- device_info_plus (device ID)

### 2. Update Code (if needed)

If you're updating existing audio player code:

**Old way** (v1):
```dart
import 'services/encrypted_audio_source.dart';

final source = EncryptedFileSource(file, uniqueId, encryptionKey);
await player.setAudioSource(source);
```

**New way** (v2):
```dart
import 'services/encrypted_audio_source_v2.dart';

final source = EncryptedAudioSourceV2(
  mediaId: track.id,  // Database ID
  uniqueId: 'track_${track.id}',
);
await player.setAudioSource(source);
```

---

## Testing

### 1. Test Server

Start the Flask server:
```bash
cd Server
python api.py
```

Verify endpoints are registered:
```
✓ Encryption endpoints (v2) registered
Server initialized with BASE_URL: http://...
```

### 2. Test Client

1. Build and run the Flutter app
2. Log in with a test account
3. Navigate to any audio book
4. Play a track
5. Audio should play normally

**If it doesn't work**:
- Check Flutter console for errors
- Verify the track has `encryption_version = 1` in database
- Ensure user has access to the book

---

## Verification Checklist

- [ ] Database migration completed without errors
- [ ] Master secret generated and backed up
- [ ] Existing files encrypted successfully
- [ ] Flutter dependencies installed (`flutter pub get`)
- [ ] Server starts without errors
- [ ] New API endpoints registered (check server logs)
- [ ] Audio plays correctly in app
- [ ] No decryption errors in client logs

---

## Common Issues

### Issue: "Master secret not found"

**Solution**:
```bash
python init_master_secret.py
```

---

### Issue: "Content key not found" on client

**Solution**: The file hasn't been encrypted yet.
```bash
python encrypt_existing_files.py
```

---

### Issue: "Failed to decrypt: Invalid authentication tag"

**Possible causes**:
1. File corruption during download
2. Wrong wrapped key fetched
3. Database inconsistency

**Debug steps**:
1. Check server logs for errors
2. Verify media_id is correct
3. Re-run encryption script for that specific file
4. Test API endpoint directly:
   ```bash
   curl "http://localhost:5000/v2/content-key/1?device_id=test" \
     -H "Authorization: Bearer YOUR_TOKEN"
   ```

---

### Issue: Audio player shows error immediately

**Solution**: Check Flutter console output. Common errors:
- `User key not found` → User needs to re-login
- `Not authenticated` → JWT token expired
- `Access denied` → User doesn't have access to the book

---

## Next Steps

Once everything works:

1. **Backup master secret** to environment variables:
   ```bash
   export MASTER_SECRET="your_base64_secret_here"
   ```

2. **Update production config** to load from env:
   ```python
   # In content_encryption.py
   master_secret = os.getenv('MASTER_SECRET')
   ```

3. **Enable HTTPS** for production API

4. **Delete original files** (after thorough testing):
   ```bash
   # Be VERY careful with this command!
   # Make backups first!
   find static/AudioBooks -type f ! -name '*_encrypted*' -delete
   ```

5. **Monitor logs** for any decryption errors

---

## Rollback Plan

If you need to rollback:

1. **Server**: Keep using old `/encrypted-audio/` endpoint
2. **Client**: Set `useV2Encryption = false` in AudioSourceFactory
3. **Database**: Old columns still exist, system still works

The new system is additive - old encryption still works!

---

## Getting Help

**Before asking for help**:
1. Check server logs (`python api.py`)
2. Check Flutter console output
3. Verify database schema with:
   ```bash
   python -c "from database import Database; db=Database(); print(db.execute_query('SHOW TABLES'))"
   ```
4. Test API endpoints with curl

**Debug mode**:
```python
# In api.py, enable debug mode
app.run(host='0.0.0.0', port=5000, debug=True)
```

---

## Success!

If audio plays correctly, congratulations! Your secure content encryption system is now active.

**What's happening**:
- ✅ Files encrypted once on server
- ✅ All users download same encrypted file
- ✅ Each user gets their own wrapped key
- ✅ Decryption happens on client in-memory
- ✅ No plaintext files on client disk

Enjoy your secure, scalable content delivery system! 🎉
