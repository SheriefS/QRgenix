from app.utils.output_utils import save_img
from PIL import Image
import os
import shutil
from pathlib import Path

def test_save_img_creates_output_and_saves(tmp_path):
    # Create dummy image
    dummy_img = Image.new("RGB", (100, 100), color="white")
    
    # Patch base_dir() to point to the temporary path
    class FakePath:
        def __init__(self, path): self._p = path
        def __call__(self): return self._p

    # Temporarily override base_dir function
    from app.utils import output_utils
    original_base_dir = output_utils.base_dir
    output_utils.base_dir = FakePath(tmp_path)

    try:
        # Save the image
        result_path = save_img(dummy_img, "test_output.png")

        # Assertions
        assert os.path.exists(result_path)
        assert Path(result_path).name == "test_output.png"
        assert tmp_path.joinpath("output", "test_output.png").exists()
    finally:
        # Restore original base_dir to prevent side effects
        output_utils.base_dir = original_base_dir