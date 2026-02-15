#!/usr/bin/env python3
"""
Delete book(s) by title or ID.
Usage:
    python3 manage_books.py <book_id>       - Delete book by ID
    python3 manage_books.py title "Name"    - Delete book by title (partial match)
    python3 manage_books.py *               - Delete ALL books
    python3 manage_books.py list            - List all books
"""

import sys
from dotenv import load_dotenv
load_dotenv()
from database import Database


def list_books():
    """List all books."""
    db = Database()
    if not db.connect():
        print("ERROR: Could not connect to database.")
        return

    try:
        books = db.execute_query("""
            SELECT b.id, b.title, b.author, b.cover_image_path,
                   (SELECT COUNT(*) FROM playlist_items pi WHERE pi.book_id = b.id) as tracks
            FROM books b ORDER BY b.id
        """)
        if not books:
            print("No books found.")
            return

        print(f"{'ID':>4}  {'Title':<40} {'Author':<25} {'Tracks':>6}  {'Cover'}")
        print("-" * 110)
        for b in books:
            cover = "YES" if b['cover_image_path'] else "NO"
            print(f"{b['id']:>4}  {b['title'][:40]:<40} {b['author'][:25]:<25} {b['tracks']:>6}  {cover}")
        print(f"\nTotal: {len(books)} books")

    except Exception as e:
        print(f"ERROR: {e}")
    finally:
        db.disconnect()


def delete_book_by_id(book_id):
    """Delete a specific book by ID."""
    db = Database()
    if not db.connect():
        print("ERROR: Could not connect to database.")
        return

    try:
        result = db.execute_query("SELECT id, title, author FROM books WHERE id = %s", (book_id,))
        if not result:
            print(f"No book found with ID: {book_id}")
            return

        book = result[0]
        print(f"Found: [{book['id']}] {book['title']} by {book['author']}")

        # Show related data
        tracks = db.execute_query("SELECT COUNT(*) as cnt FROM playlist_items WHERE book_id = %s", (book_id,))
        owners = db.execute_query("SELECT COUNT(*) as cnt FROM user_books WHERE book_id = %s", (book_id,))
        quizzes = db.execute_query("SELECT COUNT(*) as cnt FROM quizzes WHERE book_id = %s", (book_id,))
        print(f"  -> Tracks: {tracks[0]['cnt'] if tracks else 0}")
        print(f"  -> Owners: {owners[0]['cnt'] if owners else 0}")
        print(f"  -> Quizzes: {quizzes[0]['cnt'] if quizzes else 0}")

        # CASCADE handles all related records
        del_count = db.execute_query("DELETE FROM books WHERE id = %s", (book_id,))
        print(f"  -> Deleted {del_count or 0} book(s) (cascade deletes related data)")
        print(f"SUCCESS: Book '{book['title']}' deleted.")

    except Exception as e:
        print(f"ERROR: {e}")
    finally:
        db.disconnect()


def delete_book_by_title(title_query):
    """Delete book(s) matching a title pattern."""
    db = Database()
    if not db.connect():
        print("ERROR: Could not connect to database.")
        return

    try:
        results = db.execute_query("SELECT id, title, author FROM books WHERE LOWER(title) LIKE LOWER(%s)", (f"%{title_query}%",))
        if not results:
            print(f"No books found matching: {title_query}")
            return

        print(f"Found {len(results)} book(s):")
        for b in results:
            print(f"  [{b['id']}] {b['title']} by {b['author']}")

        for book in results:
            del_count = db.execute_query("DELETE FROM books WHERE id = %s", (book['id'],))
            print(f"  -> Deleted '{book['title']}' (cascade)")

        print(f"SUCCESS: {len(results)} book(s) deleted.")

    except Exception as e:
        print(f"ERROR: {e}")
    finally:
        db.disconnect()


def delete_all_books():
    """Delete ALL books."""
    db = Database()
    if not db.connect():
        print("ERROR: Could not connect to database.")
        return

    try:
        count = db.execute_query("SELECT COUNT(*) as cnt FROM books")
        total = count[0]['cnt'] if count else 0
        print(f"Total books: {total}")

        if total == 0:
            print("Nothing to delete.")
            return

        del_count = db.execute_query("DELETE FROM books")
        print(f"Deleted {del_count or 0} book(s) (cascade deletes all related data).")
        print("SUCCESS: All books removed.")

    except Exception as e:
        print(f"ERROR: {e}")
    finally:
        db.disconnect()


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    arg = sys.argv[1].strip()

    if arg == "list":
        list_books()
    elif arg == "*":
        confirm = input("Delete ALL books? (yes/no): ")
        if confirm.lower() == "yes":
            delete_all_books()
        else:
            print("Cancelled.")
    elif arg == "title":
        if len(sys.argv) < 3:
            print("Usage: python3 manage_books.py title \"Book Name\"")
            sys.exit(1)
        title_q = sys.argv[2]
        confirm = input(f"Delete books matching '{title_q}'? (yes/no): ")
        if confirm.lower() == "yes":
            delete_book_by_title(title_q)
        else:
            print("Cancelled.")
    else:
        # Assume numeric ID
        try:
            book_id = int(arg)
        except ValueError:
            print(f"Invalid argument: {arg}. Use a book ID, 'title', 'list', or '*'.")
            sys.exit(1)
        confirm = input(f"Delete book ID {book_id}? (yes/no): ")
        if confirm.lower() == "yes":
            delete_book_by_id(book_id)
        else:
            print("Cancelled.")
