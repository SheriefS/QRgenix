import pytest
from generator.qrcode_core.generate_QR import generate_qr
from PIL import Image

def test_generate_qr_without_logo():
    result = generate_qr("https://example.com", logo_name= None, color = "#000000")
    assert isinstance(result, Image.Image)
    assert result.size[0] > 100  # Sanity check that it's not empty

def test_generate_qr_with_logo():
    result = generate_qr("https://example.com", logo_name= "4747499_github_icon.png", color = "#000000")
    assert isinstance(result, Image.Image)
    assert result.size == (360, 360)  # Because embed_logo resizes

def test_generate_qr_raises_error_for_missing_logo():
    with pytest.raises(FileNotFoundError):
        generate_qr("https://example.com", logo_name="git.png")

def test_generate_qr_raises_on_empty_input():
    with pytest.raises(ValueError):
        generate_qr("")