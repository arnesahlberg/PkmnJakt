import sqlite3
import csv
import hashlib
import os
import random   # added for salt generation
import string   # added for salt generation
import datetime

db_path = '../Database/base.db'
db_dir = os.path.dirname(db_path)
if not os.path.exists(db_dir):
    os.makedirs(db_dir)
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

with open('def.sql', 'r') as sql_file:
    sql_script = sql_file.read()
cursor.executescript(sql_script)

with open('../Pkmn/pkmn.csv', 'r', newline='', encoding='utf-8') as csvfile:
    reader = csv.DictReader(csvfile)
    for row in reader:
        cursor.execute('''
        INSERT INTO Pokemon (pokemon_id, name, description, height)
        VALUES (?, ?, ?, ?)
        ''', (row['Nr'], row['Name'], row['Info'], float(row['Height (m)'])))


with open('../Pkmn/catch_codes.csv', 'r', newline='', encoding='utf-8') as csvfile:
    reader = csv.DictReader(csvfile)
    for row in reader:
        cursor.execute('''
        INSERT INTO CatchCodes (pokemon_id, catch_code)
        VALUES (?, ?)
        ''', (row['pokemon_id'], row['catch_code']))


def add_user(cursor, user_id, name, password, is_admin=False):
    salt = ''.join(random.choices(population=string.ascii_letters, k=8))
    password_hash = hashlib.sha256(password.encode() + salt.encode()).hexdigest()
    
    cursor.execute('''
    INSERT INTO Users (user_id, name, password_hash, password_salt, admin)
    VALUES (?, ?, ?, ?, ?)
    ''', (user_id, name, password_hash, salt, 1 if is_admin else 0))

# Add admin user
add_user(cursor, 'admin', 'admin', 'stensund', is_admin=True)

def add_pokemon_caught(cursor, user_id, pokemon_id):
    cursor.execute('''
    INSERT INTO FoundPokemon (user_id, pokemon_id, found_timestamp)
    VALUES (?, ?, ?)
    ''', (user_id, pokemon_id, datetime.datetime.now().isoformat()))



if "--test-users" in os.sys.argv:
    print("Adding test users and Pokémon...")
    # Add demo users too with found pokemon
    add_user(cursor, '00001', 'Ash', 'ash-pass')
    # Add 150 different Pokémon to Ash (IDs 1–150)
    for pid in range(1, 151):
        add_pokemon_caught(cursor, '00001', pid)

    add_user(cursor, '00002', 'Misty', 'misty-pass')

    # Add 29 different Pokémon to Misty (IDs 50–78)
    for pid in range(50, 79):
        add_pokemon_caught(cursor, '00002', pid)


    add_user(cursor, '00003', 'Brock', 'brock-pass')
    # Add 20 different Pokémon to Brock (IDs 1–20)
    for pid in range(1, 21):
        add_pokemon_caught(cursor, '00003', pid)
    
    add_user(cursor, '00004', 'Jessie', 'jessie-pass')

    # add 59 different Pokémon to Jessie (IDs 1–59)
    for pid in range(1, 60):
        add_pokemon_caught(cursor, '00004', pid)

    add_user(cursor, '00005', 'James', 'james-pass')
    # add 59 different Pokémon to James (IDs 1–59)
    for pid in range(1, 60):
        add_pokemon_caught(cursor, '00005', pid)

    add_user(cursor, '00006', 'Gary', 'gary-pass')
    # add 149 different Pokémon to Gary (IDs 1–149)
    for pid in range(1, 150):
        add_pokemon_caught(cursor, '00006', pid)

    add_user(cursor, '00007', 'May', 'may-pass')
    # Add 135 different Pokémon to May (IDs 1–135)
    for pid in range(1, 136):
        add_pokemon_caught(cursor, '00007', pid)
    
    add_user(cursor, '00008', 'Dawn', 'dawn-pass')
    # add 99 different Pokémon to Dawn (IDs 1–99)
    for pid in range(1, 100):
        add_pokemon_caught(cursor, '00008', pid)
        
    add_user(cursor, '00009', 'Iris', 'iris-pass')
    add_user(cursor, '00010', 'Cilan', 'cilan-pass')
    add_user(cursor, '00011', 'Serena', 'serena-pass')
    add_user(cursor, '00012', 'Clemont', 'clemont-pass')
    add_user(cursor, '00013', 'Bonnie', 'bonnie-pass')
    add_user(cursor, '00014', 'Lana', 'lana-pass')
    add_user(cursor, '00015', 'Kiawe', 'kiawe-pass')
    add_user(cursor, '00016', 'Lillie', 'lillie-pass')
    add_user(cursor, '00017', 'Mallow', 'mallow-pass')
    add_user(cursor, '00018', 'Sophocles', 'sophocles-pass')
    add_user(cursor, '00019', 'Goh', 'goh-pass')
    add_user(cursor, '00020', 'Chloe', 'chloe-pass')




conn.commit()
conn.close()
