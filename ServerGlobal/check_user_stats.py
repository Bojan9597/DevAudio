from database import Database

db = Database()
if db.connect():
    user_id = 5  # Replace with actual user ID
    
    # Check books completed
    res = db.execute_query("SELECT COUNT(*) as cnt FROM user_books WHERE user_id = %s AND is_read = 1", (user_id,))
    print(f"Books completed (is_read=1): {res[0]['cnt']}")
    
    # Check books at 100%
    res2 = db.execute_query("""
        SELECT b.id, b.title, ub.is_read
        FROM user_books ub
        JOIN books b ON ub.book_id = b.id
        WHERE ub.user_id = %s
    """, (user_id,))
    
    print("\nUser's books:")
    for r in res2:
        print(f"  Book {r['id']}: {r['title']} - is_read: {r['is_read']}")
    
    # Check current badges
    res3 = db.execute_query("SELECT * FROM user_badges WHERE user_id = %s", (user_id,))
    print(f"\nUser badges: {len(res3) if res3 else 0}")
    
    db.disconnect()
