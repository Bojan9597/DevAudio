from database import Database

def check_schema():
    print("Checking Schemas...")
    db = Database()
    if not db.connect():
        print("Failed to connect")
        return

    with open("schema_out.txt", "w") as f:
        try:
            tables = ["user_books", "books", "playlist_items", "user_completed_tracks"]
            for table in tables:
                res = db.execute_query(f"SHOW CREATE TABLE {table}")
                f.write(f"\n--- {table} ---\n")
                f.write(str(res))
                f.write("\n")
                
        finally:
            db.disconnect()

if __name__ == "__main__":
    check_schema()
