"""
Image utility functions for thumbnail generation
"""
from PIL import Image
import os

def create_thumbnail(source_path, thumbnail_path, size=(200, 200)):
    """
    Create a thumbnail from an image file

    Args:
        source_path: Path to the source image
        thumbnail_path: Path where thumbnail should be saved
        size: Tuple of (width, height) for thumbnail size
    """
    try:
        # Open the image
        with Image.open(source_path) as img:
            # Convert RGBA to RGB if necessary (for JPEG)
            if img.mode == 'RGBA':
                # Create a white background
                background = Image.new('RGB', img.size, (255, 255, 255))
                background.paste(img, mask=img.split()[3])  # Use alpha channel as mask
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
        print(f"Error creating thumbnail: {e}")
        return False

def ensure_thumbnail_exists(cover_path, static_dir='static'):
    """
    Ensure a thumbnail exists for a cover image
    Returns the relative path to the thumbnail

    Args:
        cover_path: Relative path like "/static/BookCovers/image.jpg" or "BookCovers/image.jpg"
        static_dir: Base static directory path
    """
    # Normalize the cover path
    if cover_path.startswith('/static/'):
        cover_path = cover_path[8:]  # Remove "/static/"
    elif cover_path.startswith('static/'):
        cover_path = cover_path[7:]  # Remove "static/"

    if not cover_path.startswith('BookCovers/'):
        return cover_path  # Not a book cover, return as is

    # Extract filename
    filename = os.path.basename(cover_path)

    # Define paths
    source_full_path = os.path.join(static_dir, 'BookCovers', filename)
    thumbnail_dir = os.path.join(static_dir, 'BookCovers', 'thumbnails')
    thumbnail_full_path = os.path.join(thumbnail_dir, filename)

    # Check if thumbnail already exists
    if not os.path.exists(thumbnail_full_path):
        # Create thumbnail if source exists
        if os.path.exists(source_full_path):
            create_thumbnail(source_full_path, thumbnail_full_path)

    # Return relative path to thumbnail
    if os.path.exists(thumbnail_full_path):
        return f"BookCovers/thumbnails/{filename}"

    # Fallback to original if thumbnail creation failed
    return cover_path
