import re

def clean_url(url):
    doc_match = re.search(r"(https://docs\.google\.com/document/d/[^/]+)", url)
    drive_match = re.search(r"(https://drive\.google\.com/file/d/[^/]+)", url)

    if doc_match:
        return doc_match.group(1).replace("https://", "")  + "/"
    elif drive_match:
        return drive_match.group(1).replace("https://", "")  + "/"
    else:
        # Remove http:// or https://
        return re.sub(r"^https?://", "", url)