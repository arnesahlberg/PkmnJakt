import os
import csv
import qrcode
from qrcode.constants import ERROR_CORRECT_H

csv_file = os.path.join(os.path.dirname(__file__), "catch_codes.csv")
output_dir = os.path.join(os.path.dirname(__file__), "QR_codes")
os.makedirs(output_dir, exist_ok=True)

with open(csv_file, newline='') as f:
    reader = csv.DictReader(f)
    for row in reader:
        pokemon_id = row['pokemon_id']
        catch_code = row['catch_code']
        qr = qrcode.QRCode(
            version=1,
            error_correction=ERROR_CORRECT_H,
            box_size=10,
            border=4,
        )
        qr.add_data(catch_code)
        qr.make(fit=True)
        img = qr.make_image(fill_color="black", back_color="white")
        img.save(os.path.join(output_dir, f"{pokemon_id}.png"))
