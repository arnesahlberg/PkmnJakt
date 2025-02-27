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

def pad_number(number, length=3):
    """Pad a number string with leading zeros to reach specified length."""
    return number.zfill(length)

# Create both directories
os.makedirs("Pictures", exist_ok=True)
os.makedirs("PicturesHQ", exist_ok=True)

with open("pkmn.csv", newline='', encoding="utf-8") as csvfile:
    reader = csv.DictReader(csvfile)
    for row in reader:
        number = row["Nr"].strip()
        name = row["Name"].strip()
        
        # First source - Pokemon DB
        url_name = get_url_name(name)
        url = f"https://img.pokemondb.net/artwork/avif/{url_name}.avif"
        try:
            response = requests.get(url)
            response.raise_for_status()
            with open(os.path.join("Pictures", f"{number}.avif"), "wb") as f:
                f.write(response.content)
            print(f"Downloaded {name} to Pictures folder")
        except Exception as e:
            print(f"Failed to download {name} ({url}) to Pictures folder: {e}")
        
        # Second source - GitHub HQ images
        padded_number = pad_number(number)
        github_url = f"https://raw.githubusercontent.com/HybridShivam/Pokemon/master/assets/imagesHQ/{padded_number}.png"
        try:
            response = requests.get(github_url)
            response.raise_for_status()
            with open(os.path.join("PicturesHQ", f"{number}.png"), "wb") as f:
                f.write(response.content)
            print(f"Downloaded {name} (HQ) to PicturesHQ folder")
        except Exception as e:
            print(f"Failed to download HQ image for {name} ({github_url}): {e}")