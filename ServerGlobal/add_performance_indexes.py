#!/usr/bin/env python3
"""
Add performance indexes to the PostgreSQL database.
These indexes speed up the /books endpoint queries significantly.
"""

from database import Database

def add_indexes():
    db = Database()
    if not db.connect():
        print("Failed to connect to database")
        return
    
    indexes = [
        # For subcategory lookups
        ("idx_book_categories_book_id", "book_categories", "book_id"),
        
        # For playlist count and progress queries
        ("idx_playlist_items_book_id", "playlist_items", "book_id"),
        
        # For rating aggregations
        ("idx_book_ratings_book_id", "book_ratings", "book_id"),
        
        # For favorites check
        ("idx_favorites_user_book", "favorites", "user_id, book_id"),
        
        # For read status and user books
        ("idx_user_books_user_book", "user_books", "user_id, book_id"),
        
        # For playback progress (single books)
        ("idx_playback_history_user_book", "playback_history", "user_id, book_id"),
        
        # For playback progress (playlist tracks)
        ("idx_playback_history_user_playlist_item", "playback_history", "user_id, playlist_item_id"),
        
        # For completed tracks
        ("idx_user_completed_tracks_user_track", "user_completed_tracks", "user_id, track_id"),
        
        # For books ordering
        ("idx_books_id_desc", "books", "id DESC"),
        
        # For category joins
        ("idx_books_primary_category", "books", "primary_category_id"),
    ]
    
    print("Adding performance indexes...")
    
    for idx_name, table, columns in indexes:
        try:
            query = f"CREATE INDEX IF NOT EXISTS {idx_name} ON {table} ({columns})"
            db.execute_query(query)
            print(f"✓ Created index: {idx_name} on {table}({columns})")
        except Exception as e:
            print(f"✗ Failed to create {idx_name}: {e}")
    
    print("\nDone! Indexes will speed up the /books endpoint.")
    db.disconnect()

if __name__ == "__main__":
    add_indexes()
