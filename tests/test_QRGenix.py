import pytest
from app.QRify import generate_qr
from PIL import Image

def test_generate_qr_without_logo():
    result = generate_qr("https://example.com", logo_choice=0)
    assert isinstance(result, Image.Image)
    assert result.size[0] > 100  # Sanity check that it's not empty

def test_generate_qr_with_logo():
    result = generate_qr("https://example.com", logo_choice=1)
    assert isinstance(result, Image.Image)
    assert result.size == (360, 360)  # Because embed_logo resizes

def test_generate_qr_raises_error_for_missing_logo():
    with pytest.raises(FileNotFoundError):
        generate_qr("https://example.com", logo_choice=999)

def test_generate_qr_raises_on_empty_input():
    with pytest.raises(ValueError):
        generate_qr("")