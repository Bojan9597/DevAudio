import os
import psycopg2
from dotenv import load_dotenv

# Load env if available
load_dotenv()

# Database Config (Default to Production values if env missing)
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = int(os.getenv("DB_PORT", 6432)) # PgBouncer port
DB_Name = os.getenv("DB_NAME", "velorusb_echoHistory")
DB_USER = os.getenv("DB_USER", "velorusb_echoHistoryAdmin")
DB_PASS = os.getenv("DB_PASSWORD", "Pijanista123!")

def migrate():
    print("Connecting to database...")
    try:
        conn = psycopg2.connect(
            host=DB_HOST,
            database=DB_Name,
            user=DB_USER,
            password=DB_PASS,
            port=DB_PORT
        )
        conn.autocommit = True
        cursor = conn.cursor()
        print("Connected.")

        columns = [
            ("email_notifications_enabled", "SMALLINT DEFAULT 0"),
            ("email_notification_time", "VARCHAR(10) DEFAULT '09:00'"),
            ("email_content_new_releases", "SMALLINT DEFAULT 0"),
            ("email_content_top_picks", "SMALLINT DEFAULT 0")
        ]

        print("Checking/Adding columns...")
        for col_name, col_def in columns:
            try:
                print(f"Adding {col_name}...")
                cursor.execute(f"ALTER TABLE users ADD COLUMN {col_name} {col_def}")
                print(f"  -> Added {col_name}")
            except psycopg2.errors.DuplicateColumn:
                print(f"  -> {col_name} already exists. Skipping.")
            except Exception as e:
                print(f"  -> Error adding {col_name}: {e}")

        conn.close()
        print("\nMigration complete.")

    except Exception as e:
        print(f"\nCRITICAL ERROR: {e}")

if __name__ == "__main__":
    migrate()
