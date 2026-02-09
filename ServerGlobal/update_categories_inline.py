import json
import os
from database import Database
from dotenv import load_dotenv

load_dotenv()

# EMBEDDED CATEGORIES DATA
CATEGORIES_JSON = """
[
    {
        "id": "ancient_medieval_history",
        "title": "Ancient & Medieval History",
        "hasBooks": false,
        "children": [
            {
                "id": "ancient_civilizations",
                "title": "Ancient Civilizations",
                "children": [
                    {
                        "id": "mesopotamia",
                        "title": "Mesopotamia",
                        "children": []
                    },
                    {
                        "id": "ancient_egypt",
                        "title": "Ancient Egypt",
                        "children": []
                    },
                    {
                        "id": "ancient_greece",
                        "title": "Ancient Greece",
                        "children": []
                    },
                    {
                        "id": "ancient_rome",
                        "title": "Ancient Rome",
                        "children": []
                    }
                ]
            },
            {
                "id": "early_middle_ages",
                "title": "Early Middle Ages",
                "children": [
                    {
                        "id": "fall_of_rome",
                        "title": "Fall of Rome",
                        "children": []
                    },
                    {
                        "id": "byzantine_empire",
                        "title": "Byzantine Empire",
                        "children": []
                    },
                    {
                        "id": "islamic_caliphates",
                        "title": "Islamic Caliphates",
                        "children": []
                    },
                    {
                        "id": "viking_age",
                        "title": "Viking Age",
                        "children": []
                    }
                ]
            },
            {
                "id": "high_middle_ages",
                "title": "High Middle Ages",
                "children": [
                    {
                        "id": "feudalism",
                        "title": "Feudalism",
                        "children": []
                    },
                    {
                        "id": "crusades",
                        "title": "Crusades",
                        "children": []
                    },
                    {
                        "id": "holy_roman_empire",
                        "title": "Holy Roman Empire",
                        "children": []
                    },
                    {
                        "id": "medieval_society",
                        "title": "Medieval Society",
                        "children": []
                    }
                ]
            },
            {
                "id": "late_middle_ages",
                "title": "Late Middle Ages",
                "children": [
                    {
                        "id": "hundred_years_war",
                        "title": "Hundred Years' War",
                        "children": []
                    },
                    {
                        "id": "black_death",
                        "title": "Black Death",
                        "children": []
                    },
                    {
                        "id": "rise_of_nations",
                        "title": "Rise of Nation States",
                        "children": []
                    },
                    {
                        "id": "medieval_culture",
                        "title": "Culture & Religion",
                        "children": []
                    }
                ]
            }
        ]
    },
    {
        "id": "modern_contemporary_history",
        "title": "Modern & Contemporary History",
        "hasBooks": false,
        "children": [
            {
                "id": "renaissance_enlightenment",
                "title": "Renaissance & Enlightenment",
                "children": [
                    {
                        "id": "renaissance",
                        "title": "Renaissance",
                        "children": []
                    },
                    {
                        "id": "humanism",
                        "title": "Humanism",
                        "children": []
                    },
                    {
                        "id": "scientific_revolution",
                        "title": "Scientific Revolution",
                        "children": []
                    },
                    {
                        "id": "enlightenment",
                        "title": "Enlightenment",
                        "children": []
                    }
                ]
            },
            {
                "id": "industrial_age",
                "title": "Industrial Age",
                "children": [
                    {
                        "id": "industrial_revolution",
                        "title": "Industrial Revolution",
                        "children": []
                    },
                    {
                        "id": "technological_progress",
                        "title": "Technological Progress",
                        "children": []
                    },
                    {
                        "id": "urbanization",
                        "title": "Urbanization",
                        "children": []
                    },
                    {
                        "id": "social_changes",
                        "title": "Social Changes",
                        "children": []
                    }
                ]
            },
            {
                "id": "world_wars",
                "title": "World Wars",
                "children": [
                    {
                        "id": "world_war_1",
                        "title": "World War I",
                        "children": []
                    },
                    {
                        "id": "interwar_period",
                        "title": "Interwar Period",
                        "children": []
                    },
                    {
                        "id": "world_war_2",
                        "title": "World War II",
                        "children": []
                    },
                    {
                        "id": "postwar_world",
                        "title": "Postwar World",
                        "children": []
                    }
                ]
            },
            {
                "id": "cold_war_modern_world",
                "title": "Cold War & Modern World",
                "children": [
                    {
                        "id": "cold_war",
                        "title": "Cold War",
                        "children": []
                    },
                    {
                        "id": "fall_of_ussr",
                        "title": "Fall of USSR",
                        "children": []
                    },
                    {
                        "id": "globalization",
                        "title": "Globalization",
                        "children": []
                    },
                    {
                        "id": "modern_conflicts",
                        "title": "Modern Conflicts",
                        "children": []
                    }
                ]
            }
        ]
    }
]
"""

def sync_categories():
    print("Parsing embedded JSON data...")
    categories_data = json.loads(CATEGORIES_JSON)

    db = Database()
    if not db.connect():
        print("Failed to connect to database")
        return

    print("Connected to database. Starting sync...")
    
    # Keep track of active category IDs to delete obsolete ones later
    active_ids = set()

    def process_category(cat_data, parent_id=None):
        slug = cat_data['id']
        name = cat_data['title']
        
        # Check if exists
        existing = db.execute_query("SELECT id FROM categories WHERE slug = %s", (slug,))
        
        if existing:
            cat_id = existing[0]['id']
            # Update name and parent if changed
            db.execute_query(
                "UPDATE categories SET name = %s, parent_id = %s WHERE id = %s",
                (name, parent_id, cat_id)
            )
            # print(f"Updated: {name} ({slug})")
        else:
            # Insert
            cursor = db.connection.cursor()
            cursor.execute(
                "INSERT INTO categories (name, slug, parent_id) VALUES (%s, %s, %s) RETURNING id",
                (name, slug, parent_id)
            )
            cat_id = cursor.fetchone()[0]
            db.connection.commit()
            cursor.close()
            print(f"Inserted: {name} ({slug})")
            
        active_ids.add(cat_id)
        
        # Process children
        if 'children' in cat_data:
            for child in cat_data['children']:
                process_category(child, cat_id)

    try:
        # 1. Upsert all categories from JSON
        print("Upserting categories...")
        for root_cat in categories_data:
            process_category(root_cat)
            
        print(f"Synced {len(active_ids)} active categories.")

        # 2. Delete obsolete categories
        all_cats = db.execute_query("SELECT id FROM categories")
        all_ids = set(c['id'] for c in all_cats)
        
        to_delete = all_ids - active_ids
        
        if to_delete:
            print(f"Deleting {len(to_delete)} obsolete categories...")
            
            # Delete one by one for safety or because I don't want to mess with Tuple syntax in library
            # Actually, let's just do it loop
            count = 0
            for cid in to_delete:
                # Due to FK constraints (cascade), deleting parent might delete children.
                # If we delete a child first, fine.
                # If we delete a parent, its children (if also in to_delete) disappear.
                # best to ignore specific errors if already deleted
                try:
                    db.execute_query("DELETE FROM categories WHERE id = %s", (cid,))
                    count += 1
                except Exception as e:
                    print(f"Validation skipping {cid}: {e}")
            
            print(f"Deleted {count} categories.")
        else:
            print("No obsolete categories to delete.")
            
    except Exception as e:
        print(f"Error during sync: {e}")
    finally:
        db.disconnect()

if __name__ == "__main__":
    sync_categories()
