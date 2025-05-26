#app/QRify

from generator.qrcode_core.utils.link_utils import clean_url
from generator.qrcode_core.utils.image_utils import embed_logo
import qrcode
from PIL import Image
import qrcode.constants

def generate_qr(url, logo_name=None, color="#000000", bg_color="#ffffff", minify=False):


    if not url or not url.strip():
        raise ValueError("Input URL cannot be empty.")

    if not logo_name:
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
    if minify:
        url = clean_url(url)
    qr.add_data(url)
    qr.make(fit=True)
    qr_img = qr.make_image(fill_color=color, back_color=bg_color).convert("RGB")

    if logo_name is not None:
        qr_img = embed_logo(qr_img, logo_name, bg_color)
    
    return qr_img
