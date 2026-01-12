import mysql.connector
import json

try:
    conn = mysql.connector.connect(
        host="localhost",
        database="audiobooks",
        user="root",
        password="Pijanista123!"
    )
    if conn.is_connected():
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SHOW COLUMNS FROM books")
        columns = cursor.fetchall()
        print(json.dumps(columns, default=str))
        cursor.close()
        conn.close()
except Exception as e:
    print(f"Error: {e}")
