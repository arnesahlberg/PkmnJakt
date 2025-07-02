#!/usr/bin/env python3
"""
Apply the Pokemon types migration to add type tracking functionality
"""

import sqlite3
import os
import sys

def apply_migration():
    """Apply the Pokemon types migration and populate type data"""
    
    # Database path
    db_path = os.path.join(os.path.dirname(__file__), "Database", "base.db")
    if not os.path.exists(db_path):
        print(f"Error: Database not found at {db_path}")
        print("Please run the database creation script first.")
        sys.exit(1)
    
    # Migration script path
    migration_path = os.path.join(os.path.dirname(__file__), "Datamodel", "add_pokemon_types.sql")
    if not os.path.exists(migration_path):
        print(f"Error: Migration script not found at {migration_path}")
        sys.exit(1)
    
    # Type data population script
    populate_script = os.path.join(os.path.dirname(__file__), "Datamodel", "populate_pokemon_types.py")
    if not os.path.exists(populate_script):
        print(f"Error: Population script not found at {populate_script}")
        sys.exit(1)
    
    print("Applying Pokemon types migration...")
    
    try:
        # Connect to database
        conn = sqlite3.connect(db_path)
        
        # Read and execute migration script
        with open(migration_path, 'r') as f:
            migration_sql = f.read()
        
        # Execute migration in transaction
        conn.executescript(migration_sql)
        conn.commit()
        print("✓ Migration applied successfully")
        
        conn.close()
        
        # Run type population script
        print("Populating Pokemon type data...")
        os.system(f"python3 '{populate_script}'")
        print("✓ Type data populated successfully")
        
        print("\n🎉 Pokemon types migration completed!")
        print("\nNew features available:")
        print("- Pokemon now have type information (Fire, Water, etc.)")
        print("- API endpoints for type statistics:")
        print("  - GET /user_pokemon_by_type/{user_id}")
        print("  - GET /total_pokemon_by_type")
        print("- Updated views include type information")
        print("- MissingNo has Bird/Normal types")
        
    except Exception as e:
        print(f"Error applying migration: {e}")
        sys.exit(1)

if __name__ == "__main__":
    apply_migration()