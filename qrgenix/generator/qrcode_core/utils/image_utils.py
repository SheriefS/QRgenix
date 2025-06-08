import os
from PIL import Image
from generator.qrcode_core.utils.output_utils import base_dir

# function for embedding logo into QR img
def embed_logo(qr_img, logo, bg_color="#ffffff"):
    qr_width, qr_height = qr_img.size
    logo_size = qr_width//4
    logo = logo.resize((logo_size, logo_size), Image.LANCZOS)

    pos = ((qr_width - logo_size)//2, (qr_height - logo_size)//2)

    #qr_img.paste(logo, pos, mask=logo if logo.mode =='RGBA' else None)
    if logo.mode in ("RGBA", "LA"):
        background = Image.new("RGB", logo.size, color=bg_color)
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

# function for local drive use
def open_img(qr_img, logo_name, bg_color="#ffffff"):
    #Path to logos
    logo_dir = os.path.join(base_dir(), 'assets', 'logos')

    #Choose logo
    logo_path = os.path.join(logo_dir, logo_name)
    print(logo_path)
    #Embed logo if provided
    if not logo_path or not os.path.exists(logo_path):
        raise FileNotFoundError(f"Logo not found at: {logo_path}")
    else:
        logo = Image.open(logo_path)
        embedded_logo = embed_logo(qr_img, logo, bg_color)

    return embedded_logo

#placeholder for image storage option
def pull_img():
    return 1

        


