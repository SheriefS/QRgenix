# tests/test_link_utils.py

from generator.qrcode_core.utils.link_utils import clean_url

def test_clean_google_doc_url():
    input_url = "https://docs.google.com/document/d/abc123/edit?usp=sharing"
    expected = "docs.google.com/document/d/abc123/"
    assert clean_url(input_url) == expected

def test_clean_google_drive_url():
    input_url = "https://drive.google.com/file/d/xyz789/view?usp=drive_link"
    expected = "drive.google.com/file/d/xyz789/"
    assert clean_url(input_url) == expected

def test_clean_non_matching_url():
    input_url = "https://example.com/page"
    expected = "example.com/page"
    assert clean_url(input_url) == expected

def test_clean_http_url():
    input_url = "http://example.com/page"
    expected = "example.com/page"
    assert clean_url(input_url) == expected