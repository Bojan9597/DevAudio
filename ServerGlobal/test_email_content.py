from database import Database
from trigger_emails_cli import get_new_releases_html
from email_service import send_user_email
import sys
import os

# Mock DB connection to fetch real data
from dotenv import load_dotenv
load_dotenv()

def test_content_delivery():
    print("Connecting to DB...")
    db = Database()
    if not db.connect():
        print("DB Connection failed")
        return

    print("Fetching New Releases HTML...")
    html_content, images = get_new_releases_html(db)
    db.disconnect()

    if not html_content:
        print("No new releases found or error generating HTML.")
        html_content = "<p>No new releases found.</p>"
        images = []
    else:
        print("HTML Generated. Length:", len(html_content))
        print(f"Inline images: {len(images)}")
        print("Preview:", html_content[:200])

    print("Sending test email to bojanpejic97@gmail.com...")
    subject = "[TEST] New Releases Visual Check"
    body = f"""
    <h1>Visual Check</h1>
    <p>This email contains the generated New Releases section.</p>
    <hr>
    {html_content}
    <hr>
    <p>End of test.</p>
    """

    success, err = send_user_email(
        "bojanpejic97@gmail.com", subject, body,
        inline_images=images if images else None
    )
    if success:
        print("Email SENT successfully.")
    else:
        print(f"Email FAILED: {err}")

if __name__ == "__main__":
    test_content_delivery()
