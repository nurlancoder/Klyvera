#!/usr/bin/env python3
"""Regression tests for the SVG icon catalog and generated QML."""
import json
import sys
import unittest
from xml.etree import ElementTree
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "design" / "generators"))

import icons


class IconCatalogTests(unittest.TestCase):
    def test_manifest_covers_every_svg_with_provisional_license(self):
        entries = icons.load_manifest()
        source_files = {path.stem for path in (ROOT / "shell" / "assets" / "icons").glob("*.svg")}
        self.assertEqual({entry["name"] for entry in entries}, source_files)
        self.assertTrue(
            all(entry["license"] == "project-license-pending" for entry in entries)
        )

    def test_generated_catalog_and_components_are_in_sync(self):
        outputs = icons.build_outputs(icons.load_manifest())
        for path, expected in outputs.items():
            self.assertTrue(path.is_file(), f"missing generated file: {path}")
            self.assertEqual(path.read_text(encoding="utf-8"), expected)
        for path in outputs:
            if path.parent == ROOT / "shell" / "ui" / "icons" / "generated":
                self.assertIn("PathSvg { path:", outputs[path])

    def test_manifest_rejects_path_traversal(self):
        manifest = json.loads(
            (ROOT / "design" / "icons" / "manifest.json").read_text(encoding="utf-8")
        )
        manifest["icons"][0]["file"] = "../outside.svg"
        with self.assertRaises(icons.IconManifestError):
            icons.validate_manifest(manifest)

    def test_source_icons_share_the_accessible_stroke_system(self):
        icon_files = sorted((ROOT / "shell" / "assets" / "icons").glob("*.svg"))
        self.assertEqual(len(icon_files), 50)
        for path in icon_files:
            with self.subTest(icon=path.name):
                root = ElementTree.parse(path).getroot()
                self.assertEqual(root.get("viewBox"), "0 0 24 24")
                self.assertEqual(root.get("fill"), "none")
                shapes = [
                    element
                    for element in root.iter()
                    if element.tag.rsplit("}", 1)[-1]
                    in {"circle", "ellipse", "line", "path", "polyline", "polygon", "rect"}
                ]
                self.assertTrue(shapes)
                for shape in shapes:
                    self.assertEqual(shape.get("stroke"), "currentColor")
                    self.assertEqual(shape.get("stroke-width"), "1.75")
                    self.assertEqual(shape.get("stroke-linecap"), "round")
                    self.assertEqual(shape.get("stroke-linejoin"), "round")

    def test_qml_icon_uses_catalog_and_keeps_dynamic_battery(self):
        source = (ROOT / "shell" / "ui" / "Icon.qml").read_text(encoding="utf-8")
        self.assertIn("IconCatalog.hasIcon(name)", source)
        self.assertIn('name !== "battery"', source)
        self.assertIn("IconCatalog.component(root.name)", source)
        self.assertIn("Loader {", source)

    def test_qmldir_declares_the_catalog_singleton(self):
        qmldir = (ROOT / "shell" / "ui" / "qmldir").read_text(encoding="utf-8")
        self.assertIn("singleton IconCatalog 1.0 IconCatalog.qml", qmldir)


if __name__ == "__main__":
    unittest.main()
