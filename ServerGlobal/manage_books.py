#!/usr/bin/env python3
"""
Delete book(s) by title or ID, including R2 storage cleanup.
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
from r2_storage import is_r2_ref, get_r2_key, delete_r2_object, delete_r2_prefix, is_r2_enabled


def list_books():
    """List all books."""
    db = Database()
    if not db.connect():
        print("ERROR: Could not connect to database.")
        return

    try:
        books = db.execute_query("""
            SELECT b.id, b.title, b.author, b.cover_image_path, b.audio_path, b.pdf_path,
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


def cleanup_r2_files(book, playlist_items=None):
    """Delete R2 files associated with a book."""
    if not is_r2_enabled():
        print("  [R2] R2 not configured, skipping file cleanup.")
        return

    deleted = 0

    # Delete cover image from R2
    if book.get('cover_image_path') and is_r2_ref(book['cover_image_path']):
        cover_key = get_r2_key(book['cover_image_path'])
        if delete_r2_object(cover_key):
            deleted += 1
        # Also delete thumbnail
        thumb_key = cover_key.replace('BookCovers/', 'BookCovers/thumbnails/', 1)
        delete_r2_object(thumb_key)

    # Delete audio files from R2
    if book.get('audio_path') and is_r2_ref(book['audio_path']):
        audio_key = get_r2_key(book['audio_path'])
        # Check if it's a playlist folder (contains /)
        # e.g. AudioBooks/12345_title/01_file.mp3 -> delete whole folder
        parts = audio_key.split('/')
        if len(parts) >= 3:
            # Playlist: AudioBooks/folder_name/...
            folder_prefix = '/'.join(parts[:2]) + '/'
            deleted += delete_r2_prefix(folder_prefix)
        else:
            # Single file
            if delete_r2_object(audio_key):
                deleted += 1

    # If we have playlist items, delete each track individually (in case audio_path didn't cover them)
    if playlist_items:
        for item in playlist_items:
            path = item.get('file_path', '')
            if is_r2_ref(path):
                r2_key = get_r2_key(path)
                if delete_r2_object(r2_key):
                    deleted += 1

    # Delete PDF from R2
    if book.get('pdf_path') and is_r2_ref(book['pdf_path']):
        pdf_key = get_r2_key(book['pdf_path'])
        if delete_r2_object(pdf_key):
            deleted += 1

    print(f"  [R2] Cleaned up {deleted} file(s) from R2.")


def delete_book_by_id(book_id):
    """Delete a specific book by ID, including R2 files."""
    db = Database()
    if not db.connect():
        print("ERROR: Could not connect to database.")
        return

    try:
        result = db.execute_query(
            "SELECT id, title, author, audio_path, cover_image_path, pdf_path FROM books WHERE id = %s",
            (book_id,)
        )
        if not result:
            print(f"No book found with ID: {book_id}")
            return

        book = result[0]
        print(f"Found: [{book['id']}] {book['title']} by {book['author']}")

        # Get playlist items for R2 cleanup
        tracks = db.execute_query("SELECT file_path FROM playlist_items WHERE book_id = %s", (book_id,))
        owners = db.execute_query("SELECT COUNT(*) as cnt FROM user_books WHERE book_id = %s", (book_id,))
        quizzes = db.execute_query("SELECT COUNT(*) as cnt FROM quizzes WHERE book_id = %s", (book_id,))
        print(f"  -> Tracks: {len(tracks) if tracks else 0}")
        print(f"  -> Owners: {owners[0]['cnt'] if owners else 0}")
        print(f"  -> Quizzes: {quizzes[0]['cnt'] if quizzes else 0}")

        # Clean up R2 files BEFORE deleting DB records
        cleanup_r2_files(book, tracks)

        # CASCADE handles all related DB records
        del_count = db.execute_query("DELETE FROM books WHERE id = %s", (book_id,))
        print(f"  -> Deleted {del_count or 0} book(s) from DB (cascade deletes related data)")
        print(f"SUCCESS: Book '{book['title']}' fully deleted (DB + R2).")

    except Exception as e:
        print(f"ERROR: {e}")
    finally:
        db.disconnect()


def delete_book_by_title(title_query):
    """Delete book(s) matching a title pattern, including R2 files."""
    db = Database()
    if not db.connect():
        print("ERROR: Could not connect to database.")
        return

    try:
        results = db.execute_query(
            "SELECT id, title, author, audio_path, cover_image_path, pdf_path FROM books WHERE LOWER(title) LIKE LOWER(%s)",
            (f"%{title_query}%",)
        )
        if not results:
            print(f"No books found matching: {title_query}")
            return

        print(f"Found {len(results)} book(s):")
        for b in results:
            print(f"  [{b['id']}] {b['title']} by {b['author']}")

        for book in results:
            tracks = db.execute_query("SELECT file_path FROM playlist_items WHERE book_id = %s", (book['id'],))
            cleanup_r2_files(book, tracks)
            del_count = db.execute_query("DELETE FROM books WHERE id = %s", (book['id'],))
            print(f"  -> Deleted '{book['title']}' from DB (cascade)")

        print(f"SUCCESS: {len(results)} book(s) fully deleted (DB + R2).")

    except Exception as e:
        print(f"ERROR: {e}")
    finally:
        db.disconnect()


def delete_all_books():
    """Delete ALL books, including R2 files."""
    db = Database()
    if not db.connect():
        print("ERROR: Could not connect to database.")
        return

    try:
        books = db.execute_query("SELECT id, title, author, audio_path, cover_image_path, pdf_path FROM books")
        if not books:
            print("No books to delete.")
            return

        print(f"Total books: {len(books)}")

        for book in books:
            tracks = db.execute_query("SELECT file_path FROM playlist_items WHERE book_id = %s", (book['id'],))
            cleanup_r2_files(book, tracks)

        del_count = db.execute_query("DELETE FROM books")
        print(f"Deleted {del_count or 0} book(s) from DB (cascade deletes all related data).")
        print("SUCCESS: All books fully deleted (DB + R2).")

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
        confirm = input("Delete ALL books (DB + R2 files)? (yes/no): ")
        if confirm.lower() == "yes":
            delete_all_books()
        else:
            print("Cancelled.")
    elif arg == "title":
        if len(sys.argv) < 3:
            print("Usage: python3 manage_books.py title \"Book Name\"")
            sys.exit(1)
        title_q = sys.argv[2]
        confirm = input(f"Delete books matching '{title_q}' (DB + R2 files)? (yes/no): ")
        if confirm.lower() == "yes":
            delete_book_by_title(title_q)
        else:
            print("Cancelled.")
    else:
        try:
            book_id = int(arg)
        except ValueError:
            print(f"Invalid argument: {arg}. Use a book ID, 'title', 'list', or '*'.")
            sys.exit(1)
        confirm = input(f"Delete book ID {book_id} (DB + R2 files)? (yes/no): ")
        if confirm.lower() == "yes":
            delete_book_by_id(book_id)
        else:
            print("Cancelled.")
