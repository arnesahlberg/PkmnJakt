import csv
import uuid



def generate_catch_codes():
    with open('pkmn.csv', newline='', encoding='utf-8') as csvfile:
        reader = csv.DictReader(csvfile)
        with open('catch_codes.csv', 'w', newline='') as catchfile:
            writer = csv.writer(catchfile)
            writer.writerow(['pokemon_id', 'catch_code'])
            for row in reader:
                writer.writerow([row['Nr'], str(uuid.uuid4())])


if __name__ == '__main__':
    generate_catch_codes()

