import json
from dotenv import load_dotenv
import os

load_dotenv()

from database import Database

def seed_history():
    db = Database()
    if not db.connect():
        print("Failed to connect to DB")
        return

    print("Connected to DB")
    
    # 1. Clear existing categories
    # using DELETE to trigger cascades if any (though TRUNCATE CASCADE works too)
    print("Clearing old categories...")
    try:
        db.execute_query("DELETE FROM categories")
        # Reset sequence if needed, but not strictly necessary for functionality.
        # If we want IDs to start from 1, we can reset.
        db.execute_query("ALTER SEQUENCE categories_id_seq RESTART WITH 1")
    except Exception as e:
        print(f"Error clearing categories: {e}")
        return

    # 2. Define New Data
    categories = [
        {
            "id": "ancient_medieval_history",
            "title": "Ancient & Medieval History",
            "children": [
                {
                    "id": "ancient_civilizations",
                    "title": "Ancient Civilizations",
                    "children": [
                        { "id": "mesopotamia", "title": "Mesopotamia", "children": [] },
                        { "id": "ancient_egypt", "title": "Ancient Egypt", "children": [] },
                        { "id": "ancient_greece", "title": "Ancient Greece", "children": [] },
                        { "id": "ancient_rome", "title": "Ancient Rome", "children": [] }
                    ]
                },
                {
                    "id": "early_middle_ages",
                    "title": "Early Middle Ages",
                    "children": [
                        { "id": "fall_of_rome", "title": "Fall of Rome", "children": [] },
                        { "id": "byzantine_empire", "title": "Byzantine Empire", "children": [] },
                        { "id": "islamic_caliphates", "title": "Islamic Caliphates", "children": [] },
                        { "id": "viking_age", "title": "Viking Age", "children": [] }
                    ]
                },
                {
                    "id": "high_middle_ages",
                    "title": "High Middle Ages",
                    "children": [
                        { "id": "feudalism", "title": "Feudalism", "children": [] },
                        { "id": "crusades", "title": "Crusades", "children": [] },
                        { "id": "holy_roman_empire", "title": "Holy Roman Empire", "children": [] },
                        { "id": "medieval_society", "title": "Medieval Society", "children": [] }
                    ]
                },
                {
                    "id": "late_middle_ages",
                    "title": "Late Middle Ages",
                    "children": [
                        { "id": "hundred_years_war", "title": "Hundred Years' War", "children": [] },
                        { "id": "black_death", "title": "Black Death", "children": [] },
                        { "id": "rise_of_nations", "title": "Rise of Nation States", "children": [] },
                        { "id": "medieval_culture", "title": "Culture & Religion", "children": [] }
                    ]
                }
            ]
        },
        {
            "id": "modern_contemporary_history",
            "title": "Modern & Contemporary History",
            "children": [
                {
                    "id": "renaissance_enlightenment",
                    "title": "Renaissance & Enlightenment",
                    "children": [
                        { "id": "renaissance", "title": "Renaissance", "children": [] },
                        { "id": "humanism", "title": "Humanism", "children": [] },
                        { "id": "scientific_revolution", "title": "Scientific Revolution", "children": [] },
                        { "id": "enlightenment", "title": "Enlightenment", "children": [] }
                    ]
                },
                {
                    "id": "industrial_age",
                    "title": "Industrial Age",
                    "children": [
                        { "id": "industrial_revolution", "title": "Industrial Revolution", "children": [] },
                        { "id": "technological_progress", "title": "Technological Progress", "children": [] },
                        { "id": "urbanization", "title": "Urbanization", "children": [] },
                        { "id": "social_changes", "title": "Social Changes", "children": [] }
                    ]
                },
                {
                    "id": "world_wars",
                    "title": "World Wars",
                    "children": [
                        { "id": "world_war_1", "title": "World War I", "children": [] },
                        { "id": "interwar_period", "title": "Interwar Period", "children": [] },
                        { "id": "world_war_2", "title": "World War II", "children": [] },
                        { "id": "postwar_world", "title": "Postwar World", "children": [] }
                    ]
                },
                {
                    "id": "cold_war_modern_world",
                    "title": "Cold War & Modern World",
                    "children": [
                        { "id": "cold_war", "title": "Cold War", "children": [] },
                        { "id": "fall_of_ussr", "title": "Fall of USSR", "children": [] },
                        { "id": "globalization", "title": "Globalization", "children": [] },
                        { "id": "modern_conflicts", "title": "Modern Conflicts", "children": [] }
                    ]
                }
            ]
        }
    ]

    # 3. Recursive Insert Function
    # 3. Recursive Insert Function
    def insert_category(cat, parent_id=None):
        name = cat['title']
        slug = cat['id'] # Using the JSON 'id' as the DB 'slug'
        
        # Insert
        query = "INSERT INTO categories (name, slug, parent_id) VALUES (%s, %s, %s) RETURNING id"
        try:
            with db.connection.cursor() as cursor:
                cursor.execute(query, (name, slug, parent_id))
                res = cursor.fetchone()
                if res:
                    # Generic cursor might return tuple or dict depending on factory, usually tuple from standard psycopg2 if not dict cursor
                    # Database class uses RealDictCursor factory?
                    # Let's check database.py.. yes RealDictCursor.
                    # So res is accessible by key if using that cursor, or we just trust it.
                    # Wait, RealDictCursor is set in execute_query.
                    # If I create cursor from connection, does it inherit?
                    # connection.cursor(cursor_factory=RealDictCursor) is used in execute_query.
                    # The connection itself doesn't strictly have a factory set unless set at creation?
                    # database.py: self.connection = p.getconn() ...
                    # It doesn't seem to set factory on connection level.
                    # So default cursor is likely tuple.
                    # Let's check res type or access by index for safety since it is RETURNING id (one col).
                    if isinstance(res, dict):
                        new_id = res['id']
                    else:
                        new_id = res[0]
                        
                    print(f"Inserted: {name} (ID: {new_id}, Parent: {parent_id})")
                    
                    # Recurse for children
                    for child in cat.get('children', []):
                        insert_category(child, new_id)
                else:
                    print(f"Failed to get ID for {name}")
        except Exception as e:
            print(f"Error inserting {name}: {e}")
            # We should probably stop if parent fails? Or just continue log error.

    # 4. Run Insertion
    print("Seeding new categories...")
    for cat in categories:
        insert_category(cat, None)
    
    db.connection.commit()
    db.disconnect()
    print("Done.")

if __name__ == "__main__":
    seed_history()
