import mysql.connector

def get_db_connection():
    return mysql.connector.connect(
        host="localhost",
        user="root",
        password="Pijanista123!",
        database="audiobooks"
    )

def reset_badges():
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        print("--- Resetting Badges ---")
        
        # 1. Clear existing
        print("Clearing user_badges and badges...")
        cursor.execute("TRUNCATE TABLE user_badges")
        cursor.execute("DELETE FROM badges")
        
        # 2. Insert New Badges
        badges = [
            # Read Badges
            ('read', 'Read 1 Book', 'Finished your first book', 'read_1', 1),
            ('read', 'Read 2 Books', 'Finished 2 books', 'read_2', 2),
            ('read', 'Read 5 Books', 'Finished 5 books', 'read_5', 5),
            ('read', 'Read 10 Books', 'Finished 10 books', 'read_10', 10),
            
            # Buy Badges
            ('buy', 'Collector I', 'Bought your first book', 'buy_1', 1),
            ('buy', 'Collector II', 'Bought 2 books', 'buy_2', 2),
            ('buy', 'Collector III', 'Bought 5 books', 'buy_5', 5),
            ('buy', 'Collector IV', 'Bought 10 books', 'buy_10', 10),
        ]

        print("Inserting 8 new badges...")
        query = "INSERT INTO badges (category, name, description, code, threshold) VALUES (%s, %s, %s, %s, %s)"
        cursor.executemany(query, badges)
        
        conn.commit()
        print("✅ Badges reset successfully.")

    except Exception as e:
        print(f"Error: {e}")
    finally:
        cursor.close()
        conn.close()

if __name__ == "__main__":
    reset_badges()
