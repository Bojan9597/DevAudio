import mysql.connector
import json

try:
    conn = mysql.connector.connect(
        host="localhost",
        database="audiobooks",
        user="root",
        password="Pijanista123!"
    )
    cursor = conn.cursor(dictionary=True)
    
    # Get last 5 books Join Categories to see slug
    query = """
    SELECT b.id, b.title, b.posted_by_user_id, b.primary_category_id, c.slug as category_slug, c.name as category_name
    FROM books b
    LEFT JOIN categories c ON b.primary_category_id = c.id
    ORDER BY b.id DESC LIMIT 5
    """
    
    cursor.execute(query)
    books = cursor.fetchall()
    
    print("\n--- Recent Books Debug ---")
    for b in books:
        print(f"ID: {b['id']} | Title: {b['title']} | UserID: {b['posted_by_user_id']} | CatID: {b['primary_category_id']} | Slug: {b['category_slug']}")

    cursor.close()
    conn.close()

except Exception as e:
    print(f"Error: {e}")
