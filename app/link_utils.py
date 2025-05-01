import re

def clean_google_doc_url(url):
    match = re.search(r"(https://docs\.google\.com/document/d/[^/]+)", url)
    match = re.search(r"(https://drive\.google\.com/file/d/[^/]+)", url)
    return match.group(1) + "/" if match else url