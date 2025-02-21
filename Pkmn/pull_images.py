import os
import csv
import requests

def get_url_name(name):
    if "nidoran" in name.lower():
        if "♀" in name:
            return "nidoran-f"
        elif "♂" in name:
            return "nidoran-m"
    return name.lower().replace(".", "").replace("'", "").replace(" ", "-")

os.makedirs("Pictures", exist_ok=True)

with open("pkmn.csv", newline='', encoding="utf-8") as csvfile:
    reader = csv.DictReader(csvfile)
    for row in reader:
        number = row["Nr"].strip()
        name = row["Name"].strip()
        url_name = get_url_name(name)
        url = f"https://img.pokemondb.net/artwork/avif/{url_name}.avif"
        try:
            response = requests.get(url)
            response.raise_for_status()
            with open(os.path.join("Pictures", f"{number}.avif"), "wb") as f:
                f.write(response.content)
        except Exception as e:
            print(f"Failed to download {name} ({url}): {e}")