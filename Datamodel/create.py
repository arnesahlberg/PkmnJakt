import sqlite3
import csv
import hashlib
import os
import random   # added for salt generation
import string   # added for salt generation

conn = sqlite3.connect('../Database/base.db')
cursor = conn.cursor()

with open('def.sqlite', 'r') as sql_file:
    sql_script = sql_file.read()
cursor.executescript(sql_script)

with open('../Pkmn/pkmn.csv', newline='', encoding='utf-8') as csvfile:
    reader = csv.DictReader(csvfile)
    for row in reader:
        cursor.execute('''
        INSERT INTO Pokemon (pokemon_id, name, description, height)
        VALUES (?, ?, ?, ?)
        ''', (row['Nr'], row['Name'], row['Info'], float(row['Height (m)'])))


with open('../Pkmn/catch_codes.csv', newline='', encoding='utf-8') as csvfile:
    reader = csv.DictReader(csvfile)
    for row in reader:
        cursor.execute('''
        INSERT INTO CatchCodes (pokemon_id, catch_code)
        VALUES (?, ?)
        ''', (row['pokemon_id'], row['catch_code']))


# also insert into User table an admin user
# Changed to use simple SHA256(password+salt) matching Rust
salt = ''.join(random.choices(string.ascii_letters, k=8))
password_hash = hashlib.sha256("stensund".encode() + salt.encode()).hexdigest()
password_salt = salt

cursor.execute('''
INSERT INTO Users (user_id, name, password_hash, password_salt, admin)
VALUES (?, ?, ?, ?, ?)
''', ('admin', 'admin', password_hash, password_salt, 1))


conn.commit()
conn.close()
