# from api import app, db, Database # Causing circular/import issues
from database import Database
from email_service import send_user_email
from datetime import datetime, timedelta
import os
from urllib.request import Request, urlopen
from urllib.error import URLError
from dotenv import load_dotenv
import sys
import warnings
from r2_storage import resolve_url

# Suppress DeprecationWarnings from psycopg2/datetime
warnings.filterwarnings("ignore", category=DeprecationWarning)

# Load env vars manually since we aren't importing api
load_dotenv()

# Header required by WAF for media.velorus.ba
APP_SOURCE_HEADER = 'X-App-Source'
APP_SOURCE_VALUE = os.getenv('APP_SOURCE_VALUE', 'Echo_Secured_9xQ2zP5mL8kR4wN1vJ7')
CACHE_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'image_cache')

def fetch_cover_image(url):
    """
    Download a cover image from the URL (with WAF header).
    Uses local file caching to minimize bandwidth.
    Returns (image_bytes, content_type) or (None, None) on failure.
    """
    if not url:
        return None, None
        
    try:
        # Ensure cache directory exists
        if not os.path.exists(CACHE_DIR):
            os.makedirs(CACHE_DIR)
            
        # Create a safe filename hash from the URL
        import hashlib
        url_hash = hashlib.md5(url.encode('utf-8')).hexdigest()
        cache_path = os.path.join(CACHE_DIR, f"{url_hash}.jpg")
        
        # Check Cache (valid for 24 hours)
        if os.path.exists(cache_path):
            file_age = datetime.now() - datetime.fromtimestamp(os.path.getmtime(cache_path))
            if file_age < timedelta(hours=24):
                with open(cache_path, 'rb') as f:
                    # print(f"  [DEBUG] Serving from cache: {url}")
                    return f.read(), 'image/jpeg'

        # Validated: User wants this header present
        # Also add User-Agent to avoid generic WAF blocking
        headers = {
            APP_SOURCE_HEADER: APP_SOURCE_VALUE,
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        }
        
        req = Request(url, headers=headers)
        resp = urlopen(req, timeout=10)
        data = resp.read()
        
        if data and len(data) > 0:
            ctype = resp.headers.get('Content-Type', 'image/jpeg')
            
            # Save to Cache
            try:
                with open(cache_path, 'wb') as f:
                    f.write(data)
            except Exception as cache_err:
                print(f"  [WARN] Failed to write cache: {cache_err}")
                
            return data, ctype
            
    except (URLError, Exception) as e:
        print(f"  [WARN] Failed to fetch cover ({url}): {e}")
    return None, None

def get_new_releases_html(db):
    """
    Fetch top 3 newest books and generate HTML table with inline CID images.
    Returns (html_string, images_list) or (None, []).
    """
    try:
        query = """
            SELECT title, author, cover_image_path
            FROM books
            ORDER BY created_at DESC
            LIMIT 3
        """
        books = db.execute_query(query)
        
        if not books:
            return None, []

        BASE_URL = "https://velorus.ba/devaudioserver2" 
        images = []

        html_parts = [
            '<div style="margin-top: 20px; border-top: 1px solid #eee; padding-top: 15px;">',
            '<h3 style="color: #333;">New Releases</h3>',
            '<table style="width: 100%; border-collapse: collapse;">'
        ]

        for i, book in enumerate(books):
            # Resolve URL - this will return the public Cloudflare URL
            img_url = resolve_url(book['cover_image_path'], base_url=BASE_URL)
            title = book.get('title', 'Unknown Title')
            author = book.get('author', 'Unknown Author')
            
            # Fallback
            if not img_url:
                img_url = "https://via.placeholder.com/80x120?text=No+Cover"
            
            # Use DIRECT LINK
            html_parts.append(f"""
                <tr>
                    <td style="padding: 10px; width: 100px; vertical-align: top;">
                        <img src="{img_url}" alt="{title}" style="width: 80px; height: auto; border-radius: 4px; display: block;">
                    </td>
                    <td style="padding: 10px; vertical-align: top;">
                        <p style="margin: 0; font-weight: bold; font-size: 16px;">{title}</p>
                        <p style="margin: 5px 0 0; color: #666;">by {author}</p>
                    </td>
                </tr>
            """)
        
        html_parts.append('</table></div>')
        return "".join(html_parts), [] # Empty images list
    except Exception as e:
        print(f"Error fetching new releases: {e}")
        return None, []

def get_trending_books_html(db):
    """
    Fetch 3 random books to feature as 'Trending Today'.
    """
    try:
        query = """
            SELECT title, author, cover_image_path
            FROM books
            ORDER BY RANDOM()
            LIMIT 3
        """
        books = db.execute_query(query)
        
        if not books:
            return None, []

        BASE_URL = "https://velorus.ba/devaudioserver2" 
        images = []

        html_parts = [
            '<div style="margin-top: 20px; border-top: 1px solid #eee; padding-top: 15px;">',
            '<h3 style="color: #333;">Trending Today</h3>',
            '<p style="color: #666; font-size: 14px;">See what everyone is listening to...</p>',
            '<table style="width: 100%; border-collapse: collapse;">'
        ]

        for i, book in enumerate(books):
            # Resolve URL - this will return the public Cloudflare URL
            img_url = resolve_url(book['cover_image_path'], base_url=BASE_URL)
            title = book.get('title', 'Unknown')
            author = book.get('author', 'Unknown')
            
            # Fallback
            if not img_url:
                img_url = "https://via.placeholder.com/80x120?text=No+Cover"

            # Use DIRECT LINK - Zero bandwidth from our server
            html_parts.append(f"""
                <tr>
                    <td style="padding: 10px; width: 100px; vertical-align: top;">
                        <img src="{img_url}" alt="{title}" style="width: 80px; height: auto; border-radius: 4px; display: block;">
                    </td>
                    <td style="padding: 10px; vertical-align: top;">
                        <p style="margin: 0; font-weight: bold; font-size: 16px;">{title}</p>
                        <p style="margin: 5px 0 0; color: #666;">by {author}</p>
                    </td>
                </tr>
            """)
        
        html_parts.append('</table></div>')
        return "".join(html_parts), [] # Empty list for images (we are not embedding)
    except Exception as e:
        print(f"Error fetching trending: {e}")
        return None, []

def trigger_emails_cli():
    """
    CLI version of trigger_daily_emails to be run by cron.
    """
    utc_now = datetime.utcnow()
    cet_now = utc_now + timedelta(hours=1)
    current_time = cet_now.strftime("%H:%M")
    
    db = Database()
    if not db.connect():
        print("Database connection failed")
        return

    try:
        # Fetch users FIRST
        query = """
            SELECT id, email, name, email_notification_time, 
                   email_content_new_releases, email_content_top_picks
            FROM users 
            WHERE email_notifications_enabled = 1
        """
        users = db.execute_query(query)
        
        # print(f"[{datetime.now()}] DEBUG: ServerTime(UTC)={utc_now.strftime('%H:%M')} | UserTime(CET)={current_time}")

        users_to_alert = []
        if users:
            # print(f"[{datetime.now()}] DEBUG: Found {len(users)} enabled users. Checking times...")
            for user in users:
                user_time = str(user.get('email_notification_time', '09:00')).strip()
                # Loose matching: compare first 5 chars
                if user_time[:5] == current_time[:5]:
                    users_to_alert.append(user)
                    print(f"[{datetime.now()}] MATCH: {user['email']} at {user_time}")

        # Only generate content if we actually have recipients (lazy loading)
        if not users_to_alert:
            # print(f"[{datetime.now()}] No users scheduled for {current_time}. Exiting.")
            return

        print(f"[{datetime.now()}] Found {len(users_to_alert)} users to alert. Generating content...")

        # NOW fetch content & download images
        new_releases_html, new_releases_images = get_new_releases_html(db)
        trending_html, trending_images = get_trending_books_html(db)
        
        sent_count = 0
        for user in users_to_alert:
             subject = "Your Daily AudioBooks Update"
             all_images = []
             
             # Build Email Body
             html_body = f"""
             <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                 <h2 style="color: #333;">Hi {user.get('name', 'Reader')},</h2>
                 <p>Here is your daily update from AudioBooks!</p>
             """
             
             # Inject New Releases
             if user['email_content_new_releases'] and new_releases_html:
                 html_body += new_releases_html
                 all_images.extend(new_releases_images)
             elif user['email_content_new_releases']:
                 html_body += "<p>Check out the app for the latest books added today!</p>"
                 
             # Inject Trending/Top Picks
             if user['email_content_top_picks'] and trending_html:
                 html_body += trending_html
                 all_images.extend(trending_images)
             elif user['email_content_top_picks']:
                  html_body += "<p>Check out the app for trending books!</p>"
                 
             html_body += """
                <br>
                <p style="border-top: 1px solid #eee; padding-top: 20px; color: #888; font-size: 12px;">
                    Happy Listening!<br>The AudioBooks Team
                </p>
             </div>
             """
             
             success, err = send_user_email(
                 user['email'], subject, html_body, 
                 inline_images=all_images if all_images else None
             )
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
