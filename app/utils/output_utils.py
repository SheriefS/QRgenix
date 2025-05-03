import os
from pathlib import Path

def base_dir():
    return Path(__file__).resolve().parents[2]

def save_img(qr_img, filename):   
    output_dir = os.path.join(base_dir(), 'output')
    #Create folder if it doesn't exist
    os.makedirs(output_dir, exist_ok=True)
    output_path = os.path.join(output_dir, filename)
    qr_img.save(output_path)
    return os.path.abspath(output_path)