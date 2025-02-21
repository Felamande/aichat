from PIL import Image
import os

def create_ico(input_path, output_path):
    # Windows icon sizes
    sizes = [16, 32, 48, 64, 128, 256]
    
    # Open original image
    img = Image.open(input_path)
    
    # Create images for all sizes
    images = []
    for size in sizes:
        resized_img = img.resize((size, size), Image.Resampling.LANCZOS)
        images.append(resized_img)
    
    # Save as ICO
    img.save(output_path, format='ICO', sizes=[(i.width, i.height) for i in images])
    print(f"Windows icon generated: {output_path}")

def main():
    # Get the script's directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_dir = os.path.dirname(script_dir)
    
    # Source and output paths
    source_icon = os.path.join(project_dir, 'assets', 'icons', 'app_icon.png')
    windows_dir = os.path.join(project_dir, 'windows', 'runner', 'resources')
    
    # Create output directory if it doesn't exist
    os.makedirs(windows_dir, exist_ok=True)
    
    # Generate app icon
    create_ico(source_icon, os.path.join(windows_dir, 'app_icon.ico'))

if __name__ == '__main__':
    main() 