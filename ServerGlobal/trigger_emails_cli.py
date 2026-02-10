# from api import app, db, Database # Causing circular/import issues
from database import Database
from email_service import send_user_email
from datetime import datetime, timedelta
import os
from dotenv import load_dotenv
import sys
import warnings

# Suppress DeprecationWarnings from psycopg2/datetime
warnings.filterwarnings("ignore", category=DeprecationWarning)

# Load env vars manually since we aren't importing api
load_dotenv()

def trigger_emails_cli():
    """
    CLI version of trigger_daily_emails to be run by cron.
    """
    # Fix for Timezone: Server is UTC, User is CET (UTC+1).
    # We check against (UTC + 1 hour).
    utc_now = datetime.utcnow()
    cet_now = utc_now + timedelta(hours=1)
    current_time = cet_now.strftime("%H:%M")
    
    # print(f"[{datetime.now()}] Checking... Server(UTC): {utc_now.strftime('%H:%M')} | User(CET): {current_time}")
    
    db = Database()
    if not db.connect():
        print("Database connection failed")
        return

    try:
        # Select users with notifications enabled
        query = """
            SELECT id, email, name, email_notification_time, 
                   email_content_new_releases, email_content_top_picks
            FROM users 
            WHERE email_notifications_enabled = 1
        """
        users = db.execute_query(query)
        
        sent_count = 0
        if users:
            # print(f"Checking {len(users)} candidates:")
            for user in users:
                user_time = str(user.get('email_notification_time', '09:00')).strip()
                
                # Loose matching: compare first 5 chars
                is_match = (user_time[:5] == current_time[:5])
                
                # print(f" - {user['email']}: '{user_time}' vs '{current_time}' -> Match? {is_match}")
                
                if is_match:
                     print(f"MATCH! Sending daily email to {user['email']} (Scheduled: {user_time})")
                     
                     subject = "Your Daily AudioBooks Update"
                     html_body = f"""
                     <h2>Hi {user.get('name', 'Reader')},</h2>
                     <p>Here is your daily update from AudioBooks!</p>
                     """
                     
                     if user['email_content_new_releases']:
                         html_body += "<h3>New Releases</h3><p>Check out the latest books added today...</p>"
                         
                     if user['email_content_top_picks']:
                         html_body += "<h3>Trending Today</h3><p>See what everyone is listening to...</p>"
                         
                     html_body += "<p><br>Happy Listening!<br>The AudioBooks Team</p>"
                     
                     success, err = send_user_email(user['email'], subject, html_body)
                     if success:
                         sent_count += 1
                         print(f"  -> SUCCESS: Sent to {user['email']}")
                     else:
                         print(f"  -> FAILED to send to {user['email']}: {err}")

        if sent_count > 0:
            print(f"[{datetime.now()}] Completed. Sent to {sent_count} users.")
        
    except Exception as e:
        print(f"Error: {str(e)}")
    finally:
        db.disconnect()

if __name__ == "__main__":
    trigger_emails_cli()
