from PIL import Image

# Use full path to where you saved the image
image_path = r"C:\Users\HH Traders\Desktop\sample.jpg"

# Open and resize (optional if already 96x96)
img = Image.open(image_path).convert("RGB").resize((96, 96))
img.show()  # Optional: displays image
