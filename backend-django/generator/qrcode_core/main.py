import sys
from pathlib import Path

# Test backend Git Trigger

# Add the root directory to sys.path to import from app/
sys.path.append(str(Path(__file__).resolve().parent.parent))

from qrcode_core.utils.output_utils import save_img
from generate_QR import generate_qr

def main():

    print("Welcome to QRify CLI\n")
    
    while True:
        url = input("Enter a URL (or type 'exit' to quit): ").strip()
        if url.lower() == 'exit':
            print("Exiting.... Goodbye")
            break
        
        # if not url.startswith("http"):
        #     print("Please enter a valid URL (starting with http or https).")
        #     continue

        filename = input("Enter output filename (e.g. linkedin.png): ").strip()

        if not filename.endswith(".png"):
            filename += ".png"
        int_logo = 0
        logo = input("Would you like to add a logo? Choose '1' for linkedIn, '2' for Github, or type 'no' for none: ").strip()
        while True:
            print("HERE")
            if logo.lower() == 'no':
                break
            elif logo == '1':
                int_logo = int(logo)
                break
            elif logo == '2':
                int_logo = '5296501_linkedin_network_linkedin logo_icon.png'
                break
            else:
                logo = input("Please choose a valid input...\nChoose '1' for linkedIn, '2' for Github, or type 'no' for none: ")
                continue

        #print("Would you like to add a logo? Choose '1' for linkedIn, '2' for Github, or type 'no' for none")

        try:
            print(url, int_logo)
            output = generate_qr(url, int_logo)
            save_img(output, filename)
            print(f"QR code saved as: {filename}")
        except Exception as e:
            print(f"Failed to generate QR: {e}")


if __name__== "__main__":
    main()