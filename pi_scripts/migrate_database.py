""" 

Database migration script to add appliance support to existing data

"""

import sqlite3
from pathlib import Path

SCRIPT_DIR = Path(__file__).parent.absolute()
DB_PATH = SCRIPT_DIR / "energy_data.db"

def migrate():
    print("Starting database migration...")
    conn = sqlite3.connect(str(DB_PATH))
    c = conn.cursor()

    try:
        # Check if columns exist
        c.execute("PRAGMA table_info(usage)")
        columns = [col[1] for col in c.fetchall()]

        changes_made = False

        if 'appliance_id' not in columns:
            print("Adding appliance_id column...")
            c.execute("ALTER TABLE usage ADD COLUMN appliance_id INTEGER DEFAULT 1")

        if 'appliance_name' not in columns:
            print("Adding appliance_name column...")
            c.execute("ALTER TABLE usage ADD COLUMN appliance_name TEXT DEFAULT 'Main Appliance'")

        if 'id' not in columns:
            print("Note: Cannot add primary key to existing table. Consider recreating.")

        if not changes_made:
            print("Database already up to date!")
        else:
            conn.commit()
            print("Migration completed successfully.")
        
        c.execute("SELECT COUNT(*) FROM usage WHERE appliance_id = 1")
        count = c.fetchone()[0]
        print(f" Total records for Appliance 1: {count}")

    except Exception as e:
        print(f"Migration failed: {e}")
        conn.rollback()
    finally:
        conn.close()

if __name__ == "__main__":
    migrate()