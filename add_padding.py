from PIL import Image
import os

def add_padding(input_path, output_path, padding_factor=0.35):
    try:
        img = Image.open(input_path).convert("RGBA")
        width, height = img.size
        
        # Calculate new size based on padding factor
        # If padding_factor is 0.35, the original image will take up (1 - 2*0.35) = 30%? 
        # No, let's say we want the original image to be roughly 60-70% of the total size.
        # Safe zone is 66% diameter.
        # So we need new_size such that old_size / new_size <= 0.65
        # new_size >= old_size / 0.65
        
        scale_ratio = 1.0 / (1.0 - padding_factor) # e.g. 1 / 0.65 ~= 1.53
        
        new_width = int(width * scale_ratio)
        new_height = int(height * scale_ratio)
        
        # Create new transparent image
        new_img = Image.new("RGBA", (new_width, new_height), (0, 0, 0, 0))
        
        # Paste original image in center
        paste_x = (new_width - width) // 2
        paste_y = (new_height - height) // 2
        
        new_img.paste(img, (paste_x, paste_y), img)
        
        new_img.save(output_path)
        print(f"Successfully created padded image at {output_path}")
        
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    input_file = "hello_flutter/assets/icon/logo1.png"
    output_file = "hello_flutter/assets/icon/logo1_padded.png"
    
    # Check if files exist relative to current CWD
    if not os.path.exists(input_file):
        print(f"Input file not found: {input_file}")
    else:
        add_padding(input_file, output_file, padding_factor=0.5) # Increase padding to be safe (50% expansion means old is 2/3 of new?) 
        # Let's try explicit logic:
        # We want the content to fit in circle. 
        # If diameter is 108px, safe zone is 72px (66%).
        # So we need to pad such that original image is ~60-65% of the canvas.
        # old_w / new_w = 0.6 -> new_w = old_w / 0.6
        # padding_param of add_padding logic above:
        # scale_ratio = 1 / (1 - 0.4) = 1/0.6 = 1.66
