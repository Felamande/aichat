from PIL import Image
import os

def resize_icon(input_path, output_path, size):
    img = Image.open(input_path)
    img = img.resize((size, size), Image.Resampling.LANCZOS)
    img.save(output_path, 'PNG')

def main():
    # Define icon sizes for different densities
    icon_sizes = {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192
    }
    
    # Get the script's directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_dir = os.path.dirname(script_dir)
    
    # Source icon path
    source_icon = os.path.join(project_dir, 'assets', 'icons', 'app_icon.png')
    
    # Android res directory
    android_res_dir = os.path.join(project_dir, 'android', 'app', 'src', 'main', 'res')
    
    # Generate icons for each density
    for mipmap_dir, size in icon_sizes.items():
        output_dir = os.path.join(android_res_dir, mipmap_dir)
        if not os.path.exists(output_dir):
            os.makedirs(output_dir)
            
        output_path = os.path.join(output_dir, 'ic_launcher.png')
        resize_icon(source_icon, output_path, size)
        
        # Also create round icon
        output_path = os.path.join(output_dir, 'ic_launcher_round.png')
        resize_icon(source_icon, output_path, size)
        
    print("Icons generated successfully!")

if __name__ == '__main__':
    main() 