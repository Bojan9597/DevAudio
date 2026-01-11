from database import Database

def check():
    db = Database()
    if db.connect():
        try:
            res = db.execute_query("SHOW CREATE TABLE users")
            print(res)
        except Exception as e:
            print(e)
        finally:
            db.disconnect()

if __name__ == "__main__":
    check()
