import os
import csv
from PIL import Image
import pillow_avif  

os.makedirs("ScaledPictures", exist_ok=True)
with open("pkmn.csv", newline='', encoding="utf-8") as csvfile:
    reader = csv.DictReader(csvfile)
    for row in reader:
        number = row["Nr"].strip()
        size_str = row["Size"].strip()
        size_val = float(size_str.split()[0])
        scale = size_val / 0.7
        img_path = os.path.join("Pictures", f"{number}.avif")
        try:
            img = Image.open(img_path)
        except Exception as e:
            print(f"Error opening {img_path}: {e}")
            continue
        new_dimensions = (int(img.width * scale), int(img.height * scale))
        resized = img.resize(new_dimensions, Image.DEFAULT_STRATEGY)
        out_path = os.path.join("ScaledPictures", f"{number}.jpg")
        resized.convert("RGB").save(out_path, "JPEG")