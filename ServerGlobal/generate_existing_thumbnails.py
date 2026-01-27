"""
Generate thumbnails for all existing book cover images
"""
import os
from image_utils import create_thumbnail

def generate_all_thumbnails():
    """Generate thumbnails for all existing cover images"""
    covers_dir = os.path.join('static', 'BookCovers')
    thumbnails_dir = os.path.join(covers_dir, 'thumbnails')

    # Create thumbnails directory if it doesn't exist
    os.makedirs(thumbnails_dir, exist_ok=True)

    # Get all image files in BookCovers
    if not os.path.exists(covers_dir):
        print(f"BookCovers directory not found: {covers_dir}")
        return

    image_extensions = ('.jpg', '.jpeg', '.png', '.webp')
    processed = 0
    skipped = 0
    errors = 0

    for filename in os.listdir(covers_dir):
        if not filename.lower().endswith(image_extensions):
            continue

        source_path = os.path.join(covers_dir, filename)

        # Skip if it's a directory
        if os.path.isdir(source_path):
            continue

        thumbnail_path = os.path.join(thumbnails_dir, filename)

        # Skip if thumbnail already exists
        if os.path.exists(thumbnail_path):
            print(f"Thumbnail already exists: {filename}")
            skipped += 1
            continue

        # Generate thumbnail
        print(f"Generating thumbnail for: {filename}")
        if create_thumbnail(source_path, thumbnail_path):
            processed += 1
        else:
            errors += 1

    print(f"\nThumbnail generation complete!")
    print(f"  Processed: {processed}")
    print(f"  Skipped (already exist): {skipped}")
    print(f"  Errors: {errors}")

if __name__ == "__main__":
    generate_all_thumbnails()
