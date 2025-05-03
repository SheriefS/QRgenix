#app/QRify

from app.utils.link_utils import clean_url
from app.utils.image_utils import embed_logo
import qrcode
from PIL import Image
import qrcode.constants

def generate_qr(data, logo_choice=0):


    if not data or not data.strip():
        raise ValueError("Input URL cannot be empty.")

    if logo_choice == 0:
        error_correction = qrcode.constants.ERROR_CORRECT_L
    else:
        error_correction = qrcode.constants.ERROR_CORRECT_H
    
    #Create the QR code
    qr = qrcode.QRCode(
        version = 1, 
        error_correction=error_correction,
        box_size=10, 
        border=4
    )
    data = clean_url(data)
    print(data)
    qr.add_data(data)
    qr.make(fit=True)
    qr_img = qr.make_image(fill="black", back_color="white").convert("RGB")

    if logo_choice:
        qr_img = embed_logo(qr_img, logo_choice)
    
    return qr_img
