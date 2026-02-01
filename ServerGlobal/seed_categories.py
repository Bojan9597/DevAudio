#!/usr/bin/env python3
"""Seed default categories into the PostgreSQL database."""

from database import Database

def seed_categories():
    db = Database()
    if db.connect():
        
        defaults = [
            ("Fiction", "fiction"),
            ("Non-Fiction", "non-fiction"),
            ("Science", "science"),
            ("History", "history"),
            ("Technology", "technology"),
            ("Biography", "biography")
        ]
        
        # Check if categories table exists using PostgreSQL information_schema
        result = db.execute_query("""
            SELECT EXISTS (
                SELECT FROM information_schema.tables 
                WHERE table_schema = 'public' AND table_name = 'categories'
            )
        """)
        table_exists = result and result[0].get('exists', False)
        
        if not table_exists:
            print("'categories' table not found. Creating it...")
            db.execute_query("""
                CREATE TABLE categories (
                    id SERIAL PRIMARY KEY,
                    name VARCHAR(255) NOT NULL,
                    slug VARCHAR(255) NOT NULL UNIQUE,
                    parent_id INT DEFAULT NULL
                )
            """)
        
        print("Seeding table 'categories'...")
        
        for name, slug in defaults:
            try:
                # Check for duplicates
                existing = db.execute_query("SELECT id FROM categories WHERE slug = %s", (slug,))
                if not existing:
                    db.execute_query("INSERT INTO categories (name, slug) VALUES (%s, %s)", (name, slug))
                    print(f"Inserted: {name}")
                else:
                    print(f"Skipped (exists): {name}")
            except Exception as e:
                print(f"Error inserting {name}: {e}")
                
        db.disconnect()
        print("Seeding complete.")
    else:
        print("Failed to connect to DB")

if __name__ == "__main__":
    seed_categories()
