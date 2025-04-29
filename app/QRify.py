#app/QRify

import qrcode
def generate_qr(data, filename="qrcode.png"):
    qr = qrcode.QRCode(version = 1, box_size=18, border=5)
    qr.add_data(data)
    qr.make(fit=True)
    img = qr.make_image(fill="black", back_color="white")
    img.save(filename)
    return filename