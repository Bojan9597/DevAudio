
from database import Database

def fix_schema():
    print("Connecting to database...")
    db = Database()
    if not db.connect():
        print("Failed to connect to DB")
        return

    cursor = db.connection.cursor()
    
    try:
        print("Dropping constraint `unique_book_quiz`...")
        cursor.execute("ALTER TABLE quizzes DROP INDEX unique_book_quiz")
        print("Constraint dropped.")
    except Exception as e:
        print(f"Error (might handle if not exists): {e}")

    db.disconnect()

if __name__ == "__main__":
    fix_schema()
