"""
Test script to verify duration tracking and listen history functionality.
This script will check if the changes are working correctly.
"""

from database import Database

def test_schema_changes():
    """Verify database schema has been updated"""
    print("=" * 60)
    print("1. Testing Database Schema Changes")
    print("=" * 60)
    
    db = Database()
    if not db.connect():
        print("❌ Database connection failed")
        return False
    
    try:
        cursor = db.connection.cursor(dictionary=True)
        
        # Check playback_history has playlist_item_id column
        cursor.execute("SHOW COLUMNS FROM playback_history WHERE Field = 'playlist_item_id'")
        result = cursor.fetchone()
        
        if result:
            print("✓ playback_history.playlist_item_id column exists")
        else:
            print("❌ playback_history.playlist_item_id column missing")
            return False
        
        # Check playlist_items has duration_seconds column
        cursor.execute("SHOW COLUMNS FROM playlist_items WHERE Field = 'duration_seconds'")
        result = cursor.fetchone()
        
        if result:
            print("✓ playlist_items.duration_seconds column exists")
        else:
            print("❌ playlist_items.duration_seconds column missing")
            return False
        
        cursor.close()
        print("\n✅ All schema changes verified!\n")
        return True
        
    except Exception as e:
        print(f"❌ Error checking schema: {e}")
        return False
    finally:
        db.disconnect()

def test_sample_data():
    """Check if there's any sample data to test with"""
    print("=" * 60)
    print("2. Checking Sample Data")
    print("=" * 60)
    
    db = Database()
    if not db.connect():
        print("❌ Database connection failed")
        return False
    
    try:
        # Check for playlist books
        result = db.execute_query("""
            SELECT b.id, b.title, COUNT(pi.id) as track_count, SUM(pi.duration_seconds) as total_duration
            FROM books b
            JOIN playlist_items pi ON b.id = pi.book_id
            GROUP BY b.id, b.title
            LIMIT 3
        """)
        
        if result and len(result) > 0:
            print(f"\n✓ Found {len(result)} playlist book(s):")
            for book in result:
                print(f"  - Book ID {book['id']}: {book['title']}")
                print(f"    Tracks: {book['track_count']}, Total Duration: {book['total_duration']}s")
        else:
            print("\nℹ️  No playlist books found yet (upload a multi-track book to test)")
        
        # Check for any playback history
        result = db.execute_query("""
            SELECT COUNT(*) as count, COUNT(DISTINCT user_id) as users, COUNT(DISTINCT book_id) as books
            FROM playback_history
        """)
        
        if result:
            count = result[0]['count']
            users = result[0]['users']
            books = result[0]['books']
            print(f"\n✓ Playback history: {count} records from {users} user(s) for {books} book(s)")
            
            # Show sample with playlist_item_id
            result = db.execute_query("""
                SELECT id, user_id, book_id, playlist_item_id, played_seconds
                FROM playback_history
                ORDER BY id DESC
                LIMIT 3
            """)
            if result:
                print("\n  Recent playback history entries:")
                for record in result:
                    pid = record['playlist_item_id'] or 'NULL'
                    print(f"    User {record['user_id']}, Book {record['book_id']}, Track {pid}: {record['played_seconds']}s")
        
        print("\n✅ Data check complete!\n")
        return True
        
    except Exception as e:
        print(f"❌ Error checking data: {e}")
        return False
    finally:
        db.disconnect()

def show_instructions():
    """Show testing instructions"""
    print("=" * 60)
    print("3. Testing Instructions")
    print("=" * 60)
    print("""
To fully test the new functionality:

1. **Upload a Multi-Track Book**
   - Use the Flutter app or API to upload a book with 2-3 audio files
   - Check the server console for "Extracted duration for..." messages
   - Verify in database that playlist_items have duration_seconds values

2. **Play Some Tracks**
   - Play different tracks partially (e.g., 50% of track 1, 25% of track 2)
   - The playback progress will be recorded in playback_history

3. **Check Listen History**
   - Call: GET /listen-history/<user_id>
   - Should return cumulative progress across all tracks
   - Field "percentage" shows total % of book listened
   - Field "lastPosition" shows total seconds listened

4. **View Database**
   Run these queries to inspect the data:
   
   -- Check playlist items with durations
   SELECT * FROM playlist_items WHERE book_id = <your_book_id>;
   
   -- Check playback history with track IDs
   SELECT * FROM playback_history WHERE user_id = <your_user_id> ORDER BY id DESC;
   
   -- Test the listen history calculation
   SELECT 
       pi.id as track_id,
       pi.title,
       pi.duration_seconds,
       MAX(ph.played_seconds) as last_position
   FROM playlist_items pi
   LEFT JOIN playback_history ph ON ph.playlist_item_id = pi.id AND ph.user_id = <your_user_id>
   WHERE pi.book_id = <your_book_id>
   GROUP BY pi.id;
""")
    print("=" * 60)

if __name__ == "__main__":
    print("\n🔍 Testing Duration Tracking and Listen History Updates\n")
    
    schema_ok = test_schema_changes()
    data_ok = test_sample_data()
    
    if schema_ok and data_ok:
        show_instructions()
        print("\n✅ All automated checks passed!")
        print("   Follow the instructions above to do full end-to-end testing.\n")
    else:
        print("\n❌ Some checks failed. Please review the errors above.\n")
