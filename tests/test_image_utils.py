import pytest
from PIL import Image
from app.utils.image_utils import embed_logo

def test_embed_logo_with_valid_logo_choice(tmp_path):
    # Create dummy QR image
    qr_img = Image.new("RGB", (500, 500), color="white")

    # Run embed_logo with known good logo_choice
    result_img = embed_logo(qr_img, logo_choice=1)

    # Assert image was resized correctly
    assert result_img.size == (360, 360)

    # Optional: check that it's still a valid PIL image object
    assert isinstance(result_img, Image.Image)

import pytest
from PIL import Image
from app.utils.image_utils import embed_logo

def test_embed_logo_raises_error_for_missing_logo():
    qr_img = Image.new("RGB", (500, 500), color="white")

    # Use an invalid logo_choice to simulate missing file
    with pytest.raises(FileNotFoundError):
        embed_logo(qr_img, logo_choice=999)
