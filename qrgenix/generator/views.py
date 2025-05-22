from django.shortcuts import render

# Create your views here.

from django.http import JsonResponse
from generator.qrcode_core.generate_QR import generate_qr_code

def generate_qr_view(request):
    if request.method == "POST":
        data = request.POST.get("data")
        image_path = generate_qr_code(data)
        return JsonResponse({"image": image_path})
