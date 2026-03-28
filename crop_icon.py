from PIL import Image

def analyze_and_crop(input_path, output_path, padding_percent=0.15):
    img = Image.open(input_path).convert('RGB')
    width, height = img.size
    print(f"Original size: {width}x{height}")
    
    # Try an edge-detection-based auto-crop
    bg_color = img.getpixel((5, 5))
    
    left, right, top, bottom = width, 0, height, 0
    for y in range(height):
        for x in range(width):
            # L1 distance
            diff = sum(abs(a - b) for a, b in zip(img.getpixel((x, y)), bg_color))
            # 30 threshold for shadow/border detection
            if diff > 40:
                left = min(left, x)
                right = max(right, x)
                top = min(top, y)
                bottom = max(bottom, y)
                
    print(f"Detected bounding box: {left}, {top}, {right}, {bottom}")
    
    # Calculate sizes
    box_w = right - left
    box_h = bottom - top
    
    # If the algorithm fails to find a reasonable box (e.g. background is very noisy)
    # just fallback to a standard center crop for typical AI generated icons
    if box_w < width * 0.4 or box_w > width * 0.95:
        print("Fallback to 15% center crop")
        left = int(width * padding_percent)
        right = int(width * (1 - padding_percent))
        top = int(height * padding_percent)
        bottom = int(height * (1 - padding_percent))
        
    # Force Square Layout
    box_w = right - left
    box_h = bottom - top
    size = max(box_w, box_h)
    
    cx = (left + right) // 2
    cy = (top + bottom) // 2
    
    cl = max(0, cx - size // 2)
    ct = max(0, cy - size // 2)
    cr = min(width, cx + size // 2)
    cb = min(height, cy + size // 2)
    
    # Ensure it's perfectly square after clamping
    final_size = min(cr - cl, cb - ct)
    cr = cl + final_size
    cb = ct + final_size
    
    crop_box = (cl, ct, cr, cb)
    print(f"Final crop box: {crop_box}")
    
    cropped = img.crop(crop_box)
    cropped.save(output_path, 'PNG')
    print("Crop successful!")

analyze_and_crop(
    r'C:\Users\ANKIT RAI\.gemini\antigravity\brain\910388e9-8a8e-4f88-b8dd-80be2fa5fa8a\media__1772383145006.jpg',
    r'd:\Project_02\project_plan\assets\images\app_icon.png'
)
