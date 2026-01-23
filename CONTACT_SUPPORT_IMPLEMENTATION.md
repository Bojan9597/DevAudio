# Contact Support Feature - Implementation Summary

## What Was Added

A complete "Contact Support" feature that allows users to send messages to your email (bojanpejic97@gmail.com) directly from the app.

---

## 📁 Files Created/Modified

### Backend (Server/)

**New Files:**
1. `email_service.py` - Email sending service with SMTP SSL/TLS
2. `EMAIL_SETUP.md` - Complete setup guide

**Modified Files:**
1. `api.py` - Added `/send-support-email` endpoint
2. `.env.example` - Added EMAIL_PASSWORD configuration

### Frontend (Flutter)

**New Files:**
1. `lib/widgets/support_dialog.dart` - Contact support dialog UI

**Modified Files:**
1. `lib/screens/settings_screen.dart` - Added "Contact Support" button

---

## 🎯 Features

### For Users
- ✅ Tap "Contact Support" in Settings
- ✅ Write message in a dialog
- ✅ Message sent to your email
- ✅ User info automatically included
- ✅ Success/error notifications

### For You (Admin)
- ✅ Receive emails at bojanpejic97@gmail.com
- ✅ See user's name, email, and user ID
- ✅ Reply directly (Reply-To set to user's email)
- ✅ Admin messages tagged with [ADMIN]
- ✅ HTML formatted emails

---

## 📧 Email Configuration

**Email Account:**
- Server: mail.velorus.ba
- Port: 465 (SSL)
- From: audiobooks_support@velorus.ba
- To: bojanpejic97@gmail.com

**Email Format:**
```
Subject: Support Message from John Doe

From: John Doe
Email: john@example.com
User ID: 123
Date: 2026-01-23 15:30:45

Message:
[User's message here]
```

---

## 🚀 Setup Instructions

### 1. Add Email Password

Edit `Server/.env` and add:
```bash
EMAIL_PASSWORD=your_email_password_here
```

### 2. Test Email Connection

```bash
cd Server
python email_service.py
```

**Expected output:**
```
Testing email configuration...
Result: SUCCESS
Message: Email connection successful
```

### 3. Start Server

```bash
python api.py
```

The endpoint `/send-support-email` is now available.

### 4. Test from App

1. Open Settings
2. Tap "Contact Support"
3. Write a test message
4. Send
5. Check bojanpejic97@gmail.com for the email

---

## 📱 User Interface

**Location:** Settings Screen

**Button:**
```
[🤖] Contact Support
     Send us a message
     [→]
```

**Dialog:**
- Title: "Contact Support"
- Message input: Multi-line, 5000 char max
- Validation: Minimum 10 characters
- Buttons: Cancel / Send
- Loading state while sending
- Success/error snackbar notifications

---

## 🔐 Security Features

- ✅ Requires JWT authentication
- ✅ Email password in .env (not in code)
- ✅ SSL/TLS encryption (port 465)
- ✅ Message length validation (max 5000 chars)
- ✅ User info from authenticated session
- ✅ Rate limiting possible (add if needed)

---

## 🎨 Example Email

**HTML Version (what you'll see):**

```html
Subject: Support Message from Bojan Pejic

┌─────────────────────────────────────┐
│ Support Message from AudioBooks App │
├─────────────────────────────────────┤
│ From: Bojan Pejic [ADMIN]          │
│ Email: bojanpejic97@gmail.com      │
│ User ID: 1                          │
│ Date: 2026-01-23 15:30:45          │
├─────────────────────────────────────┤
│ Message:                            │
│ ┌─────────────────────────────┐   │
│ │ I need help with my account │   │
│ │ subscription. Can you help? │   │
│ └─────────────────────────────┘   │
├─────────────────────────────────────┤
│ This message was sent from the      │
│ AudioBooks mobile application.      │
└─────────────────────────────────────┘
```

**Click Reply** → Responds directly to user's email!

---

## 🧪 Testing Checklist

- [ ] Email password added to .env
- [ ] Email connection test passes
- [ ] Server starts without errors
- [ ] Contact Support button visible in Settings
- [ ] Dialog opens when tapped
- [ ] Can type message
- [ ] Validation works (min 10 chars)
- [ ] Sending shows loading indicator
- [ ] Success message appears
- [ ] Email received at bojanpejic97@gmail.com
- [ ] User info is correct in email
- [ ] Can reply to user's email
- [ ] Admin messages show [ADMIN] tag

---

## 📊 API Endpoint Details

### POST /send-support-email

**Authentication:** JWT Bearer token (required)

**Request:**
```json
{
  "message": "User's message here"
}
```

**Response (Success - 200):**
```json
{
  "message": "Email sent successfully",
  "success": true
}
```

**Response (Error - 400):**
```json
{
  "error": "Message cannot be empty",
  "success": false
}
```

**Response (Error - 500):**
```json
{
  "error": "Failed to send email",
  "details": "SMTP authentication failed",
  "success": false
}
```

---

## 🔧 Troubleshooting

### Issue: "Email authentication failed"

**Solution:**
1. Check EMAIL_PASSWORD in .env
2. Verify password is correct
3. Test login manually:
   ```bash
   python email_service.py
   ```

### Issue: "Connection timeout"

**Possible causes:**
- Firewall blocking port 465
- SMTP server unavailable
- Wrong server address

**Test:**
```python
import smtplib
smtplib.SMTP_SSL('mail.velorus.ba', 465)
```

### Issue: Email not received

**Check:**
1. Spam folder in Gmail
2. Email address: bojanpejic97@gmail.com (correct?)
3. Server logs for errors
4. Email sent successfully (check app snackbar)

---

## 🎯 Future Enhancements (Optional)

- [ ] Add file attachments (screenshots)
- [ ] Add category selection (Bug/Question/Feedback)
- [ ] Save message history in database
- [ ] Add admin reply system in app
- [ ] Push notification when admin replies
- [ ] Rate limiting (max 5 messages per hour)
- [ ] Auto-reply acknowledgment email

---

## 📝 Quick Reference

**Email Settings:**
- From: audiobooks_support@velorus.ba
- To: bojanpejic97@gmail.com
- SMTP: mail.velorus.ba:465 (SSL)
- Password: In .env file

**Files to Check:**
- Backend: `Server/email_service.py`, `Server/api.py`
- Frontend: `lib/widgets/support_dialog.dart`, `lib/screens/settings_screen.dart`
- Config: `Server/.env` (EMAIL_PASSWORD)

**Test Commands:**
```bash
# Test email
cd Server && python email_service.py

# Start server
python api.py

# Check logs
tail -f logs/*.log
```

---

## ✅ Status

**Implementation: COMPLETE**

All features implemented and ready to use after adding EMAIL_PASSWORD to .env file!

🎉 Users can now contact you directly from the app!

For detailed setup instructions, see [EMAIL_SETUP.md](Server/EMAIL_SETUP.md)
