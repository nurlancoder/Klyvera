#!/usr/bin/env python3
"""Verify CSS-style RGBA token colors are converted consistently for QML and CSS."""
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "design" / "generators"))

import generate


class TokenColorTests(unittest.TestCase):
    def test_eight_digit_hex_uses_trailing_alpha(self):
        self.assertEqual(generate.parse_color("#FFFFFF14"), ("#FFFFFF", 20 / 255))

    def test_rgba_hex_converts_to_qml_argb(self):
        self.assertEqual(generate.to_qml("#FFFFFF14"), "#14FFFFFF")

    def test_rgba_hex_converts_to_css_rgba(self):
        self.assertEqual(
            generate.to_css("#FFFFFF14"),
            "rgba(255, 255, 255, 0.0784314)",
        )

    def test_alpha_object_format_remains_supported(self):
        token = {"hex": "#FFFFFF", "alpha": 0.08}
        self.assertEqual(generate.to_qml(token), "#14FFFFFF")
        self.assertEqual(generate.to_css(token), "rgba(255, 255, 255, 0.08)")

    def test_qml_font_family_uses_first_css_family(self):
        self.assertEqual(
            generate.qml_font_family('"Manrope","Inter",system-ui,sans-serif'),
            "Manrope",
        )


if __name__ == "__main__":
    unittest.main()
