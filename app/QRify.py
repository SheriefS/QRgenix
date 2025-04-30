#app/QRify

import qrcode
from PIL import Image
import os

import qrcode.constants

def generate_qr(data, filename, logo_choice=0):

    #Create the QR code
    qr = qrcode.QRCode(
        version = 1, 
        error_correction=qrcode.constants.ERROR_CORRECT_H,
        box_size=10, 
        border=4
    )
    qr.add_data(data)
    qr.make(fit=True)
    qr_img = qr.make_image(fill="black", back_color="white").convert("RGB")

    #Path to logos
    base_dir = os.path.dirname(os.path.dirname(__file__))
    logo_dir = os.path.join(base_dir, 'assets', 'logos')

    #Choose logo
    logo_path = None
    if logo_choice == 1:
        logo_path = os.path.join(logo_dir, '1_Linkedin_unofficial_colored_svg-128.webp')
    elif logo_choice == 2:
        logo_path = os.path.join(logo_dir, 'github_rounded-64.webp')
    
    #Embed logo if provided
    if logo_path and os.path.exists(logo_path):
        logo = Image.open(logo_path)

        qr_width, qr_height = qr_img.size
        logo_size = qr_width//4
        logo = logo.resize((logo_size, logo_size), Image.LANCZOS)

        pos = ((qr_width - logo_size)//2, (qr_height - logo_size)//2)

        #qr_img.paste(logo, pos, mask=logo if logo.mode =='RGBA' else None)
        if logo.mode in ("RGBA", "LA"):
            background = Image.new("RGB", logo.size, (255, 255, 255))
            background.paste(logo, mask = logo.split()[-1])
            logo = background
        else:
            logo = logo.convert("RGB")
        qr_img.paste(logo, pos)    
    
    output_dir = os.path.join(base_dir, 'output')
    #Create folder if it doesn't exist
    os.makedirs(output_dir, exist_ok=True)
    output_path = os.path.join(output_dir, filename)
    qr_img.save(output_path)
    return os.path.abspath(output_path)