import pytest
from PIL import Image
from generator.qrcode_core.utils.image_utils import embed_logo, open_img

def test_embed_logo_with_valid_logo_choice(tmp_path):
    # Create dummy QR image
    qr_img = Image.new("RGB", (500, 500), color="white")

    # Run embed_logo with known good logo_choice
    result_img = open_img(qr_img, logo_name="4747499_github_icon.png")

    # Assert image was resized correctly
    assert result_img.size == (360, 360)

    # Optional: check that it's still a valid PIL image object
    assert isinstance(result_img, Image.Image)

# import pytest
# from PIL import Image
# from app.utils.image_utils import embed_logo

def test_embed_logo_raises_error_for_missing_logo():
    qr_img = Image.new("RGB", (500, 500), color="white")

    # Use an invalid logo_choice to simulate missing file
    with pytest.raises(FileNotFoundError):
        open_img(qr_img, logo_name="git.png", bg_color="#f9f900")
