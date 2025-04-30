import os
import sys
from pathlib import Path

# Add the root directory to sys.path to import from app/
sys.path.append(str(Path(__file__).resolve().parent.parent))

from app.QRify import generate_qr

def main():

    print("Welcome to QRify CLI\n")
    
    while True:
        url = input("Enter a URL (or type 'exit' to quit): ").strip()
        if url.lower() == 'exit':
            print("Exiting.... Goodbye")
            break
        
        if not url.startswith("http"):
            print("Please enter a valid URL (starting with http or https).")
            continue

        filename = input("Enter output filename (e.g. linkedin.png): ").strip()

        if not filename.endswith(".png"):
            filename += ".png"
        int_logo = 0
        logo = input("Would you like to add a logo? Choose '1' for linkedIn, '2' for Github, or type 'no' for none").strip()
        while True:
            if logo.lower() == 'no':
                break
            elif logo == '1':
                int_logo = int(logo)
                break
            elif logo == '2':
                int_logo = int(logo)
                break
            else:
                print("Please choose a valid input...\nChoose '1' for linkedIn, '2' for Github, or type 'no' for none")
                continue

        #print("Would you like to add a logo? Choose '1' for linkedIn, '2' for Github, or type 'no' for none")

        try:
            output = generate_qr(url, filename, int_logo)
            print(f"QR code saved as: {output}")
        except Exception as e:
            print(f"Failed to generate QR: {e}")


if __name__== "__main__":
    main()