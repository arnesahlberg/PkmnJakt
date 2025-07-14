#!/usr/bin/env python3
"""
Populate Pokemon types in the database with Swedish type names
"""

import sqlite3
import os
import csv

def load_pokemon_types():
    """Load Pokemon type data from CSV file"""
    pokemon_types = {}
    csv_path = os.path.join(os.path.dirname(__file__), "..", "Pkmn", "pokemon_types.csv")
    
    try:
        with open(csv_path, 'r', newline='', encoding='utf-8') as csvfile:
            reader = csv.DictReader(csvfile)
            for row in reader:
                pokemon_id = int(row['pokemon_id'])
                type_name = row['type_name']
                
                if pokemon_id not in pokemon_types:
                    pokemon_types[pokemon_id] = []
                
                pokemon_types[pokemon_id].append(type_name)
        
        print(f"Loaded types for {len(pokemon_types)} Pokemon from CSV")
        return pokemon_types
        
    except FileNotFoundError:
        print(f"Error: Could not find CSV file at {csv_path}")
        raise
    except Exception as e:
        print(f"Error loading Pokemon types from CSV: {e}")
        raise

def populate_types(db_path):
    """Populate Pokemon types in the database"""
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    try:
        # Load Pokemon types from CSV
        pokemon_types = load_pokemon_types()
        
        # Get type IDs
        cursor.execute("SELECT type_id, type_name FROM PokemonTypes")
        type_map = {name: id for id, name in cursor.fetchall()}
        
        # Clear existing type links first
        cursor.execute("DELETE FROM PokemonTypeLinks")
        
        # Insert Pokemon type links with proper ordering
        for pokemon_id, types in pokemon_types.items():
            # Sort types by name to ensure consistent ordering since GROUP_CONCAT doesn't support ORDER BY in older SQLite
            # Primary type first, then secondary
            for i, type_name in enumerate(types, 1):
                if type_name in type_map:
                    cursor.execute("""
                        INSERT INTO PokemonTypeLinks (pokemon_id, type_id, type_order)
                        VALUES (?, ?, ?)
                    """, (pokemon_id, type_map[type_name], i))
                else:
                    print(f"Warning: Type '{type_name}' not found in database for Pokemon {pokemon_id}")
        
        conn.commit()
        print(f"Successfully populated types for {len(pokemon_types)} Pokemon with Swedish type names")
        
    except Exception as e:
        conn.rollback()
        print(f"Error populating types: {e}")
        raise
    finally:
        conn.close()

if __name__ == "__main__":
    db_path = os.path.join(os.path.dirname(__file__), "..", "Database", "base.db")
    populate_types(db_path)