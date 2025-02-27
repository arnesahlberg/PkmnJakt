import os
import csv
from PIL import Image

# Base height in pixels
BASE_HEIGHT = 1280

os.makedirs("ScaledPictures", exist_ok=True)
os.makedirs("ScaledPrint", exist_ok=True)
with open("pkmn.csv", newline='', encoding="utf-8") as csvfile:
    reader = csv.DictReader(csvfile)
    for row in reader:
        number = row["Nr"].strip()
        size_str = row["Size"].strip()
        size_val = float(size_str.split()[0])
        scale = size_val / 0.7
        
        img_path = os.path.join("PicturesHQ", f"{number}.png")
        try:
            img = Image.open(img_path)
        except Exception as e:
            print(f"Error opening {img_path}: {e}")
            continue
            
        # Calculate target height based on scale factor and BASE_HEIGHT
        target_height = int(BASE_HEIGHT * scale)
        # Calculate width to maintain aspect ratio
        target_width = int(img.width * (target_height / img.height))
        
        # Resize image to target dimensions
        resized = img.resize((target_width, target_height), Image.DEFAULT_STRATEGY)
        
        # Create a white background image
        white_bg = Image.new("RGB", resized.size, (255, 255, 255))
        
        # Paste the resized image onto the white background, preserving transparency
        if resized.mode in ('RGBA', 'LA') or (resized.mode == 'P' and 'transparency' in resized.info):
            white_bg.paste(resized, (0, 0), resized.convert('RGBA'))
            final_img = white_bg
        else:
            # If no transparency, just convert to RGB
            final_img = resized.convert("RGB")
        out_folder = "PicturesHQ-Scaled"
        os.makedirs(out_folder, exist_ok=True)
        out_path = os.path.join(out_folder, f"{number}.jpg")
        final_img.save(out_path, "JPEG")    