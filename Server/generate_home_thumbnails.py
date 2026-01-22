"""
Generate thumbnails for homeImages folder
"""
from PIL import Image
import os

def create_thumbnail(source_path, thumbnail_path, size=(200, 200)):
    """Create a thumbnail from an image file"""
    try:
        with Image.open(source_path) as img:
            # Convert RGBA to RGB if necessary (for JPEG)
            if img.mode == 'RGBA':
                background = Image.new('RGB', img.size, (255, 255, 255))
                background.paste(img, mask=img.split()[3])
                img = background
            elif img.mode != 'RGB':
                img = img.convert('RGB')

            # Create thumbnail maintaining aspect ratio
            img.thumbnail(size, Image.Resampling.LANCZOS)

            # Ensure thumbnail directory exists
            os.makedirs(os.path.dirname(thumbnail_path), exist_ok=True)

            # Save thumbnail
            img.save(thumbnail_path, 'JPEG', quality=85, optimize=True)
            print(f"Created thumbnail: {thumbnail_path}")
            return True
    except Exception as e:
        print(f"Error creating thumbnail for {source_path}: {e}")
        return False

def main():
    home_images_dir = 'static/homeImages'
    thumbnails_dir = os.path.join(home_images_dir, 'thumbnails')
    
    # Create thumbnails directory
    os.makedirs(thumbnails_dir, exist_ok=True)
    
    # Process all images in homeImages
    for filename in os.listdir(home_images_dir):
        source_path = os.path.join(home_images_dir, filename)
        # Skip directories
        if os.path.isdir(source_path):
            continue
        if filename.lower().endswith(('.jpg', '.jpeg', '.png', '.gif')):
            thumbnail_path = os.path.join(thumbnails_dir, filename)
            
            if not os.path.exists(thumbnail_path):
                create_thumbnail(source_path, thumbnail_path)
            else:
                print(f"Thumbnail already exists: {thumbnail_path}")

if __name__ == '__main__':
    main()
    print("Done generating homeImages thumbnails!")
