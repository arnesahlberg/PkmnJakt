import sqlite3
import csv

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
        ''', (row['Nr'], row['Name'], row['Info'], float(row['Size'].replace(' m', ''))))


with open('../Pkmn/catch_codes.csv', newline='', encoding='utf-8') as csvfile:
    reader = csv.DictReader(csvfile)
    for row in reader:
        cursor.execute('''
        INSERT INTO CatchCodes (pokemon_id, catch_code)
        VALUES (?, ?)
        ''', (row['pokemon_id'], row['catch_code']))


conn.commit()
conn.close()
