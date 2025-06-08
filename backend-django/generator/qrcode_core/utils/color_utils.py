import re

HEX_COLOR_PATTERN = re.compile(r"^#([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$")

def is_valid_hex_color(color: str) -> bool:
    return isinstance(color, str) and HEX_COLOR_PATTERN.fullmatch(color) is not None
