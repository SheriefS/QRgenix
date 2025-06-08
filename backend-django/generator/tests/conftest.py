# tests/conftest.py

import os
import django
import sys
from pathlib import Path
sys.path.append(str(Path(__file__).resolve().parent.parent))

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "qrgenix.settings")
django.setup()