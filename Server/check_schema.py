from database import Database

def check():
    db = Database()
    if db.connect():
        print("--- Users Table ---")
        res = db.execute_query("DESCRIBE users")
        for r in res:
             print(f"{r['Field']}: {r['Type']}")
        
        print("\n--- Books Table ---")
        res = db.execute_query("DESCRIBE books")
        for r in res:
             print(f"{r['Field']}: {r['Type']}")
        db.disconnect()

if __name__ == "__main__":
    check()
