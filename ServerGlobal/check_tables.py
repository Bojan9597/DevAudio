from database import Database

def check_structure():
    db = Database()
    
    # Get CREATE TABLE for books
    books_structure = db.execute_query("SHOW CREATE TABLE books")
    if books_structure:
        print("\n--- BOOKS TABLE ---")
        print(books_structure[0]['Create Table'])

    # Get CREATE TABLE for users
    users_structure = db.execute_query("SHOW CREATE TABLE users")
    if users_structure:
        print("\n--- USERS TABLE ---")
        print(users_structure[0]['Create Table'])
    
    db.disconnect()

if __name__ == "__main__":
    check_structure()
