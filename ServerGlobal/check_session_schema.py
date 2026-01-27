from database import Database

def check_schema():
    db = Database()
    if db.connect():
        print("--- SHOW CREATE TABLE user_sessions ---")
        try:
            res = db.execute_query("SHOW CREATE TABLE user_sessions")
            for row in res:
                print(row)
        except Exception as e:
            print(e)
            
        print("\n--- SELECT * FROM user_sessions ---")
        try:
            res = db.execute_query("SELECT id, user_id, created_at FROM user_sessions")
            for row in res:
                print(row)
        except Exception as e:
            print(e)
            
        db.disconnect()

if __name__ == "__main__":
    check_schema()
