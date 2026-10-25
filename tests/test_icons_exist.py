#!/usr/bin/env python3
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
# Check that common icons exist
required = ["search.svg", "close.svg", "check.svg", "chevron-down.svg", "plus.svg", "folder.svg", "settings.svg"]
missing = []
for r in required:
    if not (ROOT / "shell" / "assets" / "icons" / r).exists():
        missing.append(r)
if missing:
    print("missing icons:", missing)
    sys.exit(1)
print("ok")
