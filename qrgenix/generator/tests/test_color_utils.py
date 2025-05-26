import pytest
from generator.qrcode_core.utils.color_utils import is_valid_hex_color

def test_valid_hex_color_true():
    assert is_valid_hex_color("#000000")

def test_valid_hex_color_false():
    assert not is_valid_hex_color("0")