import json
from django.test import Client

client = Client()

def test_valid_colors():
    response = client.post("/api/generate/", json.dumps({
        "url": "https://example.com",
        "color": "#123456",
        "background_color": "#abcdef"
    }), content_type="application/json")

    assert response.status_code == 200
    assert "qr_image" in response.json()

def test_invalid_foreground_color():
    response = client.post("/api/generate/", json.dumps({
        "url": "https://example.com",
        "color": "#zzzzzz"
    }), content_type="application/json")

    assert response.status_code == 400
    assert "Invalid foreground color" in response.json()["error"]

def test_invalid_background_color():
    response = client.post("/api/generate/", json.dumps({
        "url": "https://example.com",
        "bg_color": "not-a-color"
    }), content_type="application/json")

    assert response.status_code == 400
    assert "Invalid background color" in response.json()["error"]
