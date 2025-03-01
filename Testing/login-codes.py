import os
import random
from pylibdmtx.pylibdmtx import encode
from PIL import Image, ImageDraw, ImageFont

def generate_login_codes():
    output_dir = "./logincodes"
    os.makedirs(output_dir, exist_ok=True)
    
    numbers = random.sample(range(100000, 1000000), 100)
    
    for number in numbers:
        print(f"Generating login code: {number}")
        text = str(number)
        encoded = encode(text.encode('utf8'))
        base_img = Image.frombytes('RGB', (encoded.width, encoded.height), encoded.pixels)
        
        font = ImageFont.load_default()
        
        dummy_img = Image.new("RGB", (1, 1))
        dummy_draw = ImageDraw.Draw(dummy_img)
        bbox = dummy_draw.textbbox((0, 0), text, font=font)
        text_width = bbox[2] - bbox[0]
        text_height = bbox[3] - bbox[1]
        margin = 10
        new_height = encoded.height + text_height + margin
        
        new_img = Image.new("RGB", (encoded.width, new_height), "white")
        new_img.paste(base_img, (0, 0))
        draw = ImageDraw.Draw(new_img)
        text_x = (encoded.width - text_width) // 2
        text_y = encoded.height + (margin // 2)
        draw.text((text_x, text_y), text, fill="black", font=font)
        
        file_path = os.path.join(output_dir, f"{text}.png")
        new_img.save(file_path)

if __name__ == "__main__":
    generate_login_codes()
