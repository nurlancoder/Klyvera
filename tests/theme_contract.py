#!/usr/bin/env python3
"""Theme contract test - verifies all Theme.* properties used in QML exist in generated Theme.qml"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
THEME_QML = ROOT / "shell" / "styles" / "Theme.qml"
QML_DIRS = [ROOT / "shell", ROOT / "preview", ROOT / "tests" / "qml"]

# Pattern to match Theme.propertyAccess
THEME_PATTERN = re.compile(r'Theme\.([a-zA-Z][a-zA-Z0-9_.]*)')

def extract_theme_refs_from_qml(qml_file):
    """Extract all Theme.* references from a QML file"""
    content = qml_file.read_text(encoding="utf-8")
    matches = THEME_PATTERN.findall(content)
    return set(matches)

def extract_defined_properties(theme_qml):
    """Extract all defined properties from Theme.qml, including nested QtObject properties"""
    content = theme_qml.read_text(encoding="utf-8")
    properties = set()

    # Track the current QtObject nesting path
    stack = []
    current_path = ""

    for line in content.split('\n'):
        stripped = line.strip()

        # Detect QtObject opening: readonly property QtObject name: QtObject {
        qtobject_match = re.match(r'readonly\s+property\s+QtObject\s+(\w+):\s+QtObject\s*\{', stripped)
        if qtobject_match:
            obj_name = qtobject_match.group(1)
            stack.append(obj_name)
            current_path = ".".join(stack)
            # Add the object itself as a property
            properties.add(current_path)
            continue

        # Detect property inside QtObject: readonly property <type> <name>
        prop_match = re.match(r'readonly\s+property\s+\w+\s+(\w+)', stripped)
        if prop_match and current_path:
            prop_name = prop_match.group(1)
            properties.add(f"{current_path}.{prop_name}")
            continue

        # Detect function declarations: function <name>(...)
        func_match = re.match(r'function\s+(\w+)\s*\(', stripped)
        if func_match:
            properties.add(func_match.group(1))
            continue

        # Detect closing brace to pop from stack
        if stripped == "}" and stack:
            stack.pop()
            current_path = ".".join(stack)

    # Also add top-level properties
    prop_pattern = re.compile(r'(?:readonly\s+)?property\s+\w+\s+(\w+)')
    for match in prop_pattern.finditer(content):
        prop_name = match.group(1)
        if prop_name and prop_name not in ["QtObject"]:
            properties.add(prop_name)

    return properties

def main():
    print("Theme contract test")
    print("=" * 60)

    # Extract all Theme.* references from QML files
    all_refs = set()
    for qml_dir in QML_DIRS:
        if not qml_dir.exists():
            continue
        for qml_file in qml_dir.rglob("*.qml"):
            # Skip quickshell integration (target-only)
            if "quickshell" in str(qml_file):
                continue
            refs = extract_theme_refs_from_qml(qml_file)
            if refs:
                all_refs.update(refs)
                print(f"  {qml_file.relative_to(ROOT)}: {len(refs)} refs")

    print(f"\nTotal unique Theme.* references: {len(all_refs)}")

    # Extract defined properties from Theme.qml
    if not THEME_QML.exists():
        print(f"ERROR: Theme.qml not found at {THEME_QML}")
        return 1

    defined_props = extract_defined_properties(THEME_QML)
    print(f"Total defined properties in Theme.qml: {len(defined_props)}")

    # Check for missing properties
    missing = all_refs - defined_props

    if missing:
        print(f"\nFAIL: {len(missing)} missing properties:")
        for prop in sorted(missing):
            print(f"  - Theme.{prop}")
        return 1
    else:
        print("\nPASS: All Theme.* references are defined in Theme.qml")
        return 0

if __name__ == "__main__":
    sys.exit(main())
