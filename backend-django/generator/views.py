# Create your views here.
import io
import base64
from PIL import Image
import json
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from generator.qrcode_core.generate_QR import generate_qr
from generator.qrcode_core.utils.color_utils import is_valid_hex_color

@csrf_exempt
def generate_qr_api(request):
    if request.method != "POST":
        return JsonResponse({"error": "POST method required"}, status=405)

    try:
        data = json.loads(request.body)
        url = data.get("url")
        color = data.get("color", "#000000")
        bg_color = data.get("bg_color", "#ffffff")
        logo_data = data.get("logo_data")
        logo_name = data.get("logo")  # e.g., "github.png"
        minify = data.get("minify", False)  # Default to False

        logo_img = None
        if logo_data:
            try:
                logo_img = Image.open(io.BytesIO(base64.b64decode(logo_data)))
            except Exception as e:
                return JsonResponse({"error": "Invalid logo image data"}, status=400)

        if not is_valid_hex_color(color):
            return JsonResponse({"error": f"Invalid foreground color: {color}"}, status=400)
        
        if not is_valid_hex_color(bg_color):
            return JsonResponse({"error": f"Invalid background color: {color}"}, status=400)

        if not url:
            return JsonResponse({"error": "URL is required"}, status=400)

        # Assuming you have a function like this already
        img = generate_qr(url, logo_name, logo_img, color, bg_color, minify)  # Must return a PIL image

        # Convert image to base64
        buffer = io.BytesIO()
        img.save(buffer, format="PNG")
        base64_image = base64.b64encode(buffer.getvalue()).decode()

        return JsonResponse({"qr_image": f"data:image/png;base64,{base64_image}"})

    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)
