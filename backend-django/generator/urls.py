from django.urls import path
from .views import generate_qr_api


urlpatterns = [
    path("generate/", generate_qr_api, name="generate_qr_api"),  
]