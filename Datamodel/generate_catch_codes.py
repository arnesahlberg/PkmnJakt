import csv
import uuid


# read csv file ../Pkmn/pkmn.csv
# for each row, generate a catch code and write to a new csv file with columns: pokemon_id, catch_code
# write to ../Pkmn/catch_codes.csv

def generate_catch_codes():
    with open('../Pkmn/pkmn.csv', newline='', encoding='utf-8') as csvfile:
        reader = csv.DictReader(csvfile)
        with open('../Pkmn/catch_codes.csv', 'w', newline='') as catchfile:
            writer = csv.writer(catchfile)
            writer.writerow(['pokemon_id', 'catch_code'])
            for row in reader:
                writer.writerow([row['Nr'], str(uuid.uuid4())])


if __name__ == '__main__':
    generate_catch_codes()

