from database import Database

def inspect():
    db = Database()
    if db.connect():
        print("Books Schema:")
        res = db.execute_query("DESCRIBE books")
        for row in res:
            print(row)
        db.disconnect()

if __name__ == "__main__":
    inspect()
