import smtplib
import os
from dotenv import load_dotenv

load_dotenv()

SMTP_SERVER = "mail.velorus.ba"
SMTP_PORT = 465
SENDER_EMAIL = "audiobooks_support@velorus.ba"
PASSWORD = os.getenv('EMAIL_PASSWORD', '')

print(f"Connecting to {SMTP_SERVER}:{SMTP_PORT}...")
print(f"User: {SENDER_EMAIL}")
print(f"Password length: {len(PASSWORD)}")

try:
    with smtplib.SMTP_SSL(SMTP_SERVER, SMTP_PORT) as server:
        server.set_debuglevel(1)
        print("Connected. Logging in...")
        server.login(SENDER_EMAIL, PASSWORD)
        print("Login SUCCESS!")
except Exception as e:
    print(f"\nERROR: {e}")
