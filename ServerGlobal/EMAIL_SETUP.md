# Email Support Setup Guide

## Overview

The app now includes a "Contact Support" feature that allows users (and admins) to send messages directly to your email from within the app.

---

## Configuration

### 1. Add Email Password to .env

Edit your `Server/.env` file and add:

```bash
# Email Configuration
EMAIL_PASSWORD=your_actual_password_here
```

**Replace `your_actual_password_here`** with the password for `audiobooks_support@velorus.ba`

### 2. Email Settings

The email configuration is already set in `email_service.py`:

```python
SMTP_SERVER = "mail.velorus.ba"
SMTP_PORT = 465  # SSL
SENDER_EMAIL = "audiobooks_support@velorus.ba"
RECIPIENT_EMAIL = "bojanpejic97@gmail.com"
```

Messages sent by users will:
- **From**: audiobooks_support@velorus.ba
- **To**: bojanpejic97@gmail.com
- **Reply-To**: User's email (so you can reply directly)

---

## Testing the Email Service

### 1. Test Connection

```bash
cd Server
python email_service.py
```

This will test if the email credentials work.

**Expected output if successful:**
```
Testing email configuration...
Result: SUCCESS
Message: Email connection successful
```

**If it fails:**
- Check EMAIL_PASSWORD in .env
- Verify email account credentials
- Check if SMTP server is accessible

### 2. Test from API

Start the server:
```bash
python api.py
```

Then test the endpoint (requires authentication):
```bash
curl -X POST "http://localhost:5000/send-support-email" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"message": "Test message from API"}'
```

---

## How It Works

### User Flow

1. User opens app → Settings
2. Taps "Contact Support"
3. Writes message in dialog
4. Clicks "Send"
5. Message is sent to bojanpejic97@gmail.com

### Email Content

You'll receive emails like this:

```
Subject: Support Message from John Doe
(or: [ADMIN] Support Message from John Doe)

From: John Doe [ADMIN if admin]
Email: john@example.com
User ID: 123
Date: 2026-01-23 15:30:45

Message:
[User's message here]

---
This message was sent from the AudioBooks mobile application.
```

### Features

✓ **HTML formatted emails** (nice looking)
✓ **Plain text fallback** (for email clients without HTML)
✓ **Reply-To set to user's email** (click reply to respond directly)
✓ **Admin messages tagged** with [ADMIN] marker
✓ **User info included** (name, email, user ID)
✓ **Timestamp included**
✓ **Secure SSL/TLS connection**

---

## Security

- ✓ Password stored in .env (not in code)
- ✓ .env already in .gitignore
- ✓ SSL/TLS encryption (port 465)
- ✓ Requires JWT authentication
- ✓ Message length limited (max 5000 characters)

---

## Troubleshooting

### "Email authentication failed"

**Solution**: Check EMAIL_PASSWORD in .env
```bash
cat Server/.env | grep EMAIL_PASSWORD
```

### "Connection failed"

**Possible causes:**
1. SMTP server not accessible
2. Firewall blocking port 465
3. Wrong server address

**Test manually:**
```python
python
>>> import smtplib
>>> server = smtplib.SMTP_SSL('mail.velorus.ba', 465)
>>> server.login('audiobooks_support@velorus.ba', 'your_password')
>>> server.quit()
```

### "Email password not configured"

**Solution**: Add to .env file:
```bash
echo "EMAIL_PASSWORD=your_password_here" >> Server/.env
```

### Email not received

**Check:**
1. Spam folder
2. Email address correct (bojanpejic97@gmail.com)
3. Server logs for errors
4. SMTP credentials are valid

---

## Changing Settings

### Change Recipient Email

Edit `email_service.py`:
```python
RECIPIENT_EMAIL = "newemail@example.com"
```

### Change Sender Email

If you have a different email account:
```python
SMTP_SERVER = "smtp.example.com"
SMTP_PORT = 465
SENDER_EMAIL = "support@example.com"
```

Update .env:
```bash
EMAIL_PASSWORD=new_password_here
```

---

## Flutter UI

The Contact Support button appears in:
- **Settings screen** (for all users)
- Located between Upload Book (admin only) and Logout

**Dialog features:**
- Multi-line text input
- Character counter (max 5000)
- Validation (min 10 characters)
- Loading state while sending
- Success/error notifications

---

## API Endpoint

### POST /send-support-email

**Headers:**
```
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

**Body:**
```json
{
  "message": "User's message here"
}
```

**Response (Success):**
```json
{
  "message": "Email sent successfully",
  "success": true
}
```

**Response (Error):**
```json
{
  "error": "Failed to send email",
  "details": "Error details",
  "success": false
}
```

---

## Production Checklist

- [ ] Add EMAIL_PASSWORD to .env
- [ ] Test email connection: `python email_service.py`
- [ ] Test from app (send test message)
- [ ] Check email received at bojanpejic97@gmail.com
- [ ] Verify Reply-To works (reply to test email)
- [ ] Check spam folder settings
- [ ] Add email to safe senders list

---

## Quick Setup

```bash
# 1. Add password to .env
echo "EMAIL_PASSWORD=your_password_here" >> Server/.env

# 2. Test connection
cd Server
python email_service.py

# 3. Start server
python api.py

# 4. Test from app (Settings → Contact Support)
```

That's it! Users can now contact you directly from the app. 📧
