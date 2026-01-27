from database import Database

def list_tables():
    db = Database()
    if db.connect():
        tables = db.execute_query("SHOW TABLES")
        print("Tables in database:")
        for table in tables:
            print(list(table.values())[0])
        db.disconnect()
    else:
        print("Failed to connect")

if __name__ == "__main__":
    list_tables()
