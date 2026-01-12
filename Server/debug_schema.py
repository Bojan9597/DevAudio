from database import Database

def check_schema():
    db = Database()
    if db.connect():
        try:
            print("--- BOOKS TABLE ---")
            res = db.execute_query("DESCRIBE books")
            for row in res:
                print(row)
                
            print("\n--- PLAYLIST_ITEMS TABLE ---")
            res2 = db.execute_query("DESCRIBE playlist_items")
            if res2:
                for row in res2:
                    print(row)
            else:
                print("Table playlist_items does not exist.")

        except Exception as e:
            print(f"Error: {e}")
        finally:
            db.disconnect()

if __name__ == "__main__":
    check_schema()
