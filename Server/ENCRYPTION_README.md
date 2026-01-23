# Content Encryption System - Server Setup

## Quick Setup (3 Steps)

### Option 1: Automatic Setup (Recommended)

Run the setup wizard:
```bash
python setup_encryption.py
```

This will automatically:
1. Check dependencies
2. Create database tables
3. Generate master secret
4. Encrypt files
5. Verify setup

---

### Option 2: Manual Setup

```bash
# 1. Install dependencies
pip install -r requirements.txt

# 2. Create database tables
python migrate_content_encryption.py

# 3. Generate master secret (saved to .env)
python init_master_secret.py

# 4. Encrypt existing files
python encrypt_existing_files.py

# 5. Verify setup
python verify_encryption_setup.py
```

---

## Files Overview

### Setup Scripts

| File | Purpose |
|------|---------|
| `setup_encryption.py` | **Automated setup wizard** - runs all steps |
| `migrate_content_encryption.py` | Creates database tables |
| `init_master_secret.py` | Generates master secret, saves to .env |
| `encrypt_existing_files.py` | Encrypts all audio files |
| `verify_encryption_setup.py` | Checks if setup is correct |

### Core Modules

| File | Purpose |
|------|---------|
| `content_encryption.py` | Core encryption/decryption module |
| `api_encryption_endpoints.py` | Flask endpoints for v2 encryption |
| `api.py` | Main Flask app (updated with v2 endpoints) |

### Configuration

| File | Purpose |
|------|---------|
| `.env` | **Master secret storage** (NOT in git) |
| `.env.example` | Template for .env file |
| `requirements.txt` | Python dependencies |

---

## Environment Variables

The master secret is stored in `.env` file:

```bash
# .env
MASTER_SECRET=your_base64_master_secret_here
```

**Important:**
- ✓ `.env` is already in `.gitignore`
- ✓ Never commit `.env` to version control
- ✓ Back up your master secret securely
- ⚠ Loss of master secret = loss of all user access

---

## Verification

To check if everything is set up correctly:

```bash
python verify_encryption_setup.py
```

This checks:
- ✓ .env file exists with MASTER_SECRET
- ✓ Database tables created
- ✓ Master secret stored
- ✓ Files encrypted
- ✓ Encrypted files on disk

---

## How It Works

### 1. One-Time File Encryption

```python
# Encrypt a file once
manager = ContentEncryptionManager()
result = manager.encrypt_file("input.wav", "output_encrypted.wav")

# Returns: content_key, iv, auth_tag
```

### 2. Per-User Key Derivation

```python
# Derive unique key for user+device
user_key = manager.derive_user_key(
    user_id=123,
    device_id="android_abc123"
)
```

### 3. Key Wrapping

```python
# Wrap content key with user key
wrapped_key, iv, tag = manager.wrap_key(content_key, user_key)

# Store in database: user_content_keys table
```

### 4. Client Downloads

1. Client requests encrypted file (same for all users)
2. Client requests wrapped key (unique per user+device)
3. Client unwraps key and decrypts in-memory

---

## API Endpoints

### v2 Endpoints (New)

```python
# Serve encrypted file (same for all users)
GET /v2/encrypted-audio/<filepath>
  Headers: Authorization: Bearer <token>
  Returns: Binary encrypted data

# Get wrapped content key (unique per user+device)
GET /v2/content-key/<media_id>?device_id=<device_id>
  Headers: Authorization: Bearer <token>
  Returns: {wrapped_key, wrap_iv, wrap_auth_tag, content_iv, auth_tag}

# Get complete encryption info
GET /v2/encryption-info/<media_id>?device_id=<device_id>
  Headers: Authorization: Bearer <token>
  Returns: {media_id, encrypted_path, file_url, ...keys...}
```

---

## Troubleshooting

### "Master secret not found"

```bash
python init_master_secret.py
```

### "No files to encrypt"

Check:
1. Files exist in `static/AudioBooks/`
2. Files are referenced in `playlist_items` table
3. Files don't already have `encryption_version = 1`

### "Database tables missing"

```bash
python migrate_content_encryption.py
```

### Verify entire setup

```bash
python verify_encryption_setup.py
```

---

## Security Notes

### ✅ Good Practices

- Master secret stored in .env (not in code)
- .env is in .gitignore
- AES-256-GCM with random IVs
- Per-user-per-device keys
- HTTPS for API communication

### ⚠ Important

- Never commit .env to git
- Back up master secret securely
- Use HTTPS in production
- Rotate master secret periodically
- Monitor for suspicious key access

---

## Production Deployment

### 1. Environment Setup

```bash
# Set environment variable (recommended)
export MASTER_SECRET="your_base64_secret"

# Or use .env file
# Server will load from .env automatically
```

### 2. Enable HTTPS

Update Flask app:
```python
# Use SSL context
app.run(
    host='0.0.0.0',
    port=443,
    ssl_context=('cert.pem', 'key.pem')
)
```

### 3. Monitor Logs

```bash
# Check for encryption errors
tail -f logs/encryption.log
```

---

## File Structure After Setup

```
Server/
├── .env                          # Master secret (DO NOT COMMIT)
├── .env.example                  # Template
├── content_encryption.py         # Core module
├── api_encryption_endpoints.py   # API endpoints
├── setup_encryption.py           # Setup wizard
├── verify_encryption_setup.py    # Verification
└── static/
    └── AudioBooks/
        ├── book1/
        │   ├── track1.wav              # Original (plaintext)
        │   ├── track1_encrypted.wav    # Encrypted version ✓
        │   └── ...
        └── ...
```

---

## Performance

### Server
- File encryption: ~1 second per 50MB file (one-time)
- Key derivation: ~1ms per user+device
- Serving encrypted files: No CPU overhead (static files)

### Database
- `user_content_keys`: Indexed by (user_id, device_id, media_id)
- Query time: <5ms for key lookup

### Storage
- Encrypted files: Same size as original
- Overhead: ~32 bytes per file (IV + auth tag)

---

## Support

For issues:
1. Run `python verify_encryption_setup.py`
2. Check server logs
3. Review ENCRYPTION_SETUP_GUIDE.md
4. Review ENCRYPTION_ARCHITECTURE.md

---

## References

- [ENCRYPTION_ARCHITECTURE.md](../ENCRYPTION_ARCHITECTURE.md) - Complete technical spec
- [ENCRYPTION_SETUP_GUIDE.md](ENCRYPTION_SETUP_GUIDE.md) - Detailed setup guide
- [QUICK_START.md](QUICK_START.md) - 5-minute quick start

---

**Ready to start?**

```bash
python setup_encryption.py
```
