from django.urls import path
from .views import generate_qr_api
from .views import health_check

urlpatterns = [
    path("generate/", generate_qr_api, name="generate_qr_api"),
    path("health/", health_check, name="health-check"),  
]