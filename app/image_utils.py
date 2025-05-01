import os
from PIL import Image
from .output_utils import base_dir

def embed_logo(qr_img, logo_choice):
    #Path to logos
    logo_dir = os.path.join(base_dir(), 'assets', 'logos')

    #Choose logo
    logo_path = None
    if logo_choice == 1:
        logo_path = os.path.join(logo_dir, '5296501_linkedin_network_linkedin logo_icon.png')
    elif logo_choice == 2:
        logo_path = os.path.join(logo_dir, '4747499_github_icon.png')
        print("logo_path")
        #Embed logo if provided
    if logo_path and os.path.exists(logo_path):
        print("HERE!!!")
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

    # Define your desired size in inches
    width_in_inches = 1.2
    dpi = 300
    pixels = int(width_in_inches * dpi)
    qr_img = qr_img.resize((pixels, pixels), Image.LANCZOS)
    return qr_img
