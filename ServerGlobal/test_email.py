from email_service import send_user_email
import sys

def test_send():
    print("Attempting to send test email to bojanpejic97@gmail.com...")
    subject = "Test Email from Manual Script"
    body = "<h1>It Works!</h1><p>This is a test email to verify the server configuration.</p>"
    
    success, err = send_user_email("bojanpejic97@gmail.com", subject, body)
    if success:
        print("SUCCESS: Email sent.")
    else:
        print(f"FAILURE: {err}")

if __name__ == "__main__":
    test_send()
