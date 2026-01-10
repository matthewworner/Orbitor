import os
from PIL import Image

search_dir = "/Users/imac/Projects/screensaver/Resources/Textures/8K"
print(f"🔎 Auditing Texture Resolutions in: {search_dir}")
print("-" * 60)
print(f"{'Filename':<30} | {'Resolution':<15} | {'Size (MB)':<10}")
print("-" * 60)

for f in sorted(os.listdir(search_dir)):
    if f.lower().endswith(('.jpg', '.png')):
        path = os.path.join(search_dir, f)
        try:
            with Image.open(path) as img:
                w, h = img.size
                size_mb = os.path.getsize(path) / (1024 * 1024)
                print(f"{f:<30} | {w}x{h:<9} | {size_mb:.2f}")
        except Exception as e:
            print(f"{f:<30} | {'INVALID':<15} | {0:.2f}")
