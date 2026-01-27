from database import Database

def init_db():
    db = Database()
    if db.connect():
        print("Connected.")
        # Try dropping first to ensure clean slate if it partially exists
        db.execute_query("DROP TABLE IF EXISTS favorites")
        
        # Try creating with INT (Signed) first - wait, that failed.
        # Try INT UNSIGNED.
        query = """
        CREATE TABLE favorites (
            user_id INT,
            book_id INT,
            PRIMARY KEY (user_id, book_id),
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
            FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE
        );
        """
        # If the above failed (as it did), we need to match the type.
        # Since I can't see the type, I'll try to 'peek' by creating a dummy table from select? 
        # No.
        
        # Let's try ignoring FKs if they fail, or try one by one?
        # A robust way:
        
        # 1. Try INT UNSIGNED
        query_unsigned = """
        CREATE TABLE favorites (
            user_id INT UNSIGNED,
            book_id INT UNSIGNED,
            PRIMARY KEY (user_id, book_id),
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
            FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE
        )
        """
        
        print("Attempting with INT UNSIGNED...")
        res = db.execute_query(query_unsigned)
        
        # If that failed (res is None implies likely failure in this db wrapper if exception printed)
        # Actually execute_query returns None for DDL even on success?
        # database.py: 
        # if query.startswith(SELECT/SHOW): return fetchall
        # else: commit; return rowcount.
        # DDL returns 0 rowcount?
        
        # I'll check if table exists after.
        res = db.execute_query("SHOW TABLES LIKE 'favorites'")
        if res:
            print("Favorites table created successfully.")
        else:
            print("Creation with UNSIGNED failed. Trying SIGNED...")
            query_signed = """
            CREATE TABLE favorites (
                user_id INT,
                book_id INT,
                PRIMARY KEY (user_id, book_id),
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
                FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE
            )
            """
            db.execute_query(query_signed)
            
            res = db.execute_query("SHOW TABLES LIKE 'favorites'")
            if res:
                print("Favorites table created with SIGNED INT.")
            else:
                 print("Creation failed. Creating without FKs as fallback.")
                 query_nofk = """
                 CREATE TABLE favorites (
                    user_id INT,
                    book_id INT,
                    PRIMARY KEY (user_id, book_id)
                 )
                 """
                 db.execute_query(query_nofk)
                 res = db.execute_query("SHOW TABLES LIKE 'favorites'")
                 if res:
                     print("Favorites table created (No FKs).")
                 else:
                     print("Critical Failure creating table.")

        db.disconnect()

if __name__ == "__main__":
    init_db()
