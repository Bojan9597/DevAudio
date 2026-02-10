"""
Email Service for sending support messages
Uses SMTP with SSL/TLS
"""
import os
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Email configuration
SMTP_SERVER = "mail.velorus.ba"
SMTP_PORT = 465  # SSL port
SENDER_EMAIL = "audiobooks_support@velorus.ba"
SENDER_PASSWORD = os.getenv('EMAIL_PASSWORD', '')  # Load from .env file
RECIPIENT_EMAIL = "bojanpejic97@gmail.com"

def send_support_email(user_name, user_email, user_id, message, is_admin=False):
    """
    Send support/contact email to admin.

    Args:
        user_name: Name of the user sending the message
        user_email: Email of the user
        user_id: User ID in database
        message: The message content
        is_admin: Whether the sender is an admin

    Returns:
        tuple: (success: bool, error_message: str or None)
    """

    # Check if password is set
    if not SENDER_PASSWORD:
        # Try to get from environment
        import os
        password = os.getenv('EMAIL_PASSWORD')
        if not password:
            return False, "Email password not configured"
    else:
        password = SENDER_PASSWORD

    try:
        # Create message
        msg = MIMEMultipart('alternative')
        msg['Subject'] = f"{'[ADMIN] ' if is_admin else ''}Support Message from {user_name}"
        msg['From'] = SENDER_EMAIL
        msg['To'] = RECIPIENT_EMAIL
        msg['Reply-To'] = user_email

        # Prepare message formatting - escape HTML special characters first
        import html
        message_escaped = html.escape(message)
        message_html = message_escaped.replace('\n', '<br>')
        admin_badge = '<span style="color: red;">[ADMIN]</span>' if is_admin else ''
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')

        # Escape user name and email too for safety
        user_name_safe = html.escape(user_name)
        user_email_safe = html.escape(user_email)

        # Create HTML body
        html_body = f"""
        <html>
          <head></head>
          <body>
            <h2>Support Message from AudioBooks App</h2>
            <hr>
            <p><strong>From:</strong> {user_name_safe} {admin_badge}</p>
            <p><strong>Email:</strong> {user_email_safe}</p>
            <p><strong>User ID:</strong> {user_id}</p>
            <p><strong>Date:</strong> {timestamp}</p>
            <hr>
            <h3>Message:</h3>
            <div style="background-color: #f5f5f5; padding: 15px; border-left: 4px solid #4CAF50;">
                {message_html}
            </div>
            <hr>
            <p style="color: #666; font-size: 12px;">
                This message was sent from the AudioBooks mobile application.
            </p>
          </body>
        </html>
        """

        # Create plain text version
        admin_text = '[ADMIN]' if is_admin else ''
        text_body = f"""
Support Message from AudioBooks App

From: {user_name} {admin_text}
Email: {user_email}
User ID: {user_id}
Date: {timestamp}

Message:
{message}

---
This message was sent from the AudioBooks mobile application.
        """

        # Attach both versions
        part1 = MIMEText(text_body, 'plain')
        part2 = MIMEText(html_body, 'html')
        msg.attach(part1)
        msg.attach(part2)

        # Connect and send
        with smtplib.SMTP_SSL(SMTP_SERVER, SMTP_PORT) as server:
            server.login(SENDER_EMAIL, password)
            server.send_message(msg)

        return True, None

    except smtplib.SMTPAuthenticationError:
        return False, "Email authentication failed. Check credentials."
    except smtplib.SMTPException as e:
        return False, f"SMTP error: {str(e)}"
    except Exception as e:
        return False, f"Failed to send email: {str(e)}"


def test_email_connection():
    """Test if email configuration is working"""
    import os
    password = os.getenv('EMAIL_PASSWORD') or SENDER_PASSWORD

    if not password:
        return False, "Email password not configured"

    try:
        with smtplib.SMTP_SSL(SMTP_SERVER, SMTP_PORT) as server:
            server.login(SENDER_EMAIL, password)
        return True, "Email connection successful"
    except smtplib.SMTPAuthenticationError:
        return False, "Authentication failed. Check email and password."
    except Exception as e:
        return False, f"Connection failed: {str(e)}"


def send_user_email(to_email, subject, html_content, text_content=None):
    """
    Send an email to a specific user.
    """
    import os
    password = os.getenv('EMAIL_PASSWORD') or SENDER_PASSWORD
    if not password:
        return False, "Email password not configured"

    try:
        msg = MIMEMultipart('alternative')
        msg['Subject'] = subject
        msg['From'] = SENDER_EMAIL
        msg['To'] = to_email

        if text_content:
            msg.attach(MIMEText(text_content, 'plain'))
        
        if html_content:
            msg.attach(MIMEText(html_content, 'html'))

        with smtplib.SMTP_SSL(SMTP_SERVER, SMTP_PORT) as server:
            server.login(SENDER_EMAIL, password)
            server.send_message(msg)
        
        return True, None
    except Exception as e:
        return False, str(e)


if __name__ == "__main__":
    # Test the email service
    print("Testing email configuration...")
    success, message = test_email_connection()
    print(f"Result: {'SUCCESS' if success else 'FAILED'}")
    print(f"Message: {message}")
