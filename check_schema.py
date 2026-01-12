from database import Database
import json
import datetime

def default_serializer(obj):
    if isinstance(obj, (datetime.date, datetime.datetime)):
        return obj.isoformat()
    return str(obj)

db = Database()
if db.connect():
    try:
        # Use SELECT * LIMIT 1 to look at keys
        result = db.execute_query("SELECT * FROM books LIMIT 1") 
        if result:
            print("Columns found based on first row keys:")
            print(json.dumps(list(result[0].keys()), default=default_serializer))
        else:
            print("No books found, running SHOW COLUMNS")
            result = db.execute_query("SHOW COLUMNS FROM books")
            print(json.dumps(result, default=default_serializer))

    except Exception as e:
        print(f"Error: {e}")
    finally:
        db.disconnect()
