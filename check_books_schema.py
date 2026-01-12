import mysql.connector
import json
import datetime

def default_serializer(obj):
    if isinstance(obj, (datetime.date, datetime.datetime)):
        return obj.isoformat()
    return str(obj)

try:
    conn = mysql.connector.connect(
        host="localhost",
        database="audiobooks",
        user="root",
        password="Pijanista123!"
    )
    if conn.is_connected():
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM books LIMIT 1")
        row = cursor.fetchone()
        if row:
            print(json.dumps(list(row.keys()), default=default_serializer))
        else:
            # Fallback to SHOW COLUMNS if empty
            cursor.execute("SHOW COLUMNS FROM books")
            columns = [col['Field'] for col in cursor.fetchall()]
            print(json.dumps(columns, default=default_serializer))
            
        cursor.close()
        conn.close()
except Exception as e:
    print(f"Error: {e}")
