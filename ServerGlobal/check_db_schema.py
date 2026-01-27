import mysql.connector
from database import Database

def check_tables():
    db = Database()
    if db.connect():
        cursor = db.connection.cursor()
        cursor.execute("SHOW TABLES")
        tables = [table[0] for table in cursor.fetchall()]
        print("Existing Tables:", tables)
        
        required = ['quizzes', 'quiz_questions', 'user_quiz_results']
        for r in required:
            if r in tables:
                print(f"[OK] Table '{r}' exists.")
            else:
                print(f"[ERROR] Table '{r}' is MISSING.")
                
        old = ['book_quizzes', 'book_quiz_questions', 'user_book_quiz_results']
        for o in old:
            if o in tables:
                print(f"[WARNING] Renamed table '{o}' STILL EXISTS.")
            
        db.disconnect()
    else:
        print("Failed to connect to DB")

if __name__ == "__main__":
    check_tables()
