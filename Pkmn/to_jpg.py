import os
import pillow_avif
from PIL import Image

def convert_avif_to_jpg(root_dir):
    for subdir, _, files in os.walk(root_dir):
        for file in files:
            if file.lower().endswith('.avif'):
                avif_path = os.path.join(subdir, file)
                jpg_path = os.path.splitext(avif_path)[0] + '.jpg'
                try:
                    with Image.open(avif_path) as img:
                        rgb_img = img.convert("RGB")
                        rgb_img.save(jpg_path, "JPEG")
                    print(f"Converted: {avif_path} -> {jpg_path}")
                except Exception as e:
                    print(f"Failed to convert {avif_path}: {e}")

if __name__ == '__main__':
    # Change the directory path if needed.
    pictures_dir = 'Pictures'
    convert_avif_to_jpg(pictures_dir)
