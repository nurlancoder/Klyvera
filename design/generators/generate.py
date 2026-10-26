#!/usr/bin/env python3
"""Generate Klyvera theme artifacts from design/tokens.json."""
from __future__ import annotations
import argparse, json, sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
TOKENS_PATH = ROOT / "design" / "tokens.json"
THEME_QML = ROOT / "shell" / "styles" / "Theme.qml"
QMLDIR = ROOT / "shell" / "styles" / "qmldir"
TOKENS_CSS = ROOT / "web" / "src" / "styles" / "tokens.css"
CONTRAST_DOC = ROOT / "docs" / "contrast-report.md"
REQUIRED_TOP_LEVEL = ["version","themes","spacing","radius","borders","elevation","typography","motion","icon","layout","accessibility"]
REQUIRED_COLORS = ["background","surface","surfaceRaised","surfaceHover","surfaceActive","surfaceSunken","overlay","textPrimary","textSecondary","textDisabled","accentPurple","accentBlue","accentMint","success","danger","warning","info","onAccent","borderSubtle","borderStrong","focusRing","selection","shadow"]
TEXT_FOREGROUNDS = ["textPrimary","textSecondary","accentPurple","accentBlue","accentMint","success","danger","warning","info"]
TEXT_BACKGROUNDS = ["background","surface","surfaceRaised","surfaceHover"]
ON_ACCENTS = ["accentPurple","accentBlue","accentMint","success","danger","warning","info"]
FOCUS_BACKGROUNDS = ["background","surface","surfaceRaised","surfaceHover"]
NORMAL_TEXT_MIN = 4.5
UI_COMPONENT_MIN = 3.0

def fail(msg:str):
    print(f"error: {msg}", file=sys.stderr)
    raise SystemExit(1)

def load_tokens():
    try:
        with TOKENS_PATH.open(encoding="utf-8") as f: tokens = json.load(f)
    except Exception as e: fail(str(e))
    missing = [k for k in REQUIRED_TOP_LEVEL if k not in tokens]
    if missing: fail(f"tokens.json is missing top-level keys: {', '.join(missing)}")
    if not tokens["themes"]: fail("tokens.json defines no themes")
    for name, theme in tokens["themes"].items():
        colors = theme.get("colors", {})
        absent = [k for k in REQUIRED_COLORS if k not in colors]
        if absent: fail(f"theme '{name}' is missing colors: {', '.join(absent)}")
        if theme.get("colorScheme") not in {"dark","light"}: fail(f"theme '{name}' needs colorScheme 'dark' or 'light'")
        if 'label' not in theme: theme['label']=name
    return tokens

def parse_color(value):
    if isinstance(value, str):
        hex_value = value.strip(); alpha = 1.0
        if hex_value.startswith('#') and len(hex_value)==9:
            alpha = int(hex_value[7:9],16)/255.0; hex_value = hex_value[:7]
        elif hex_value.startswith('#') and len(hex_value)==7: alpha=1.0
        elif hex_value.startswith('#') and len(hex_value)==6: hex_value='#'+hex_value[1:]; alpha=1.0
        else: fail(f"color must be #RRGGBB: {value!r}")
        int(hex_value[1:],16)
        if not 0.0<=alpha<=1.0: fail(f"color alpha must be between 0 and 1: {value!r}")
        return hex_value.upper(), alpha
    elif isinstance(value,dict) and "hex" in value and "alpha" in value:
        hex_value=str(value["hex"]).strip(); alpha=float(value["alpha"])
        if not hex_value.startswith("#") or len(hex_value)!=7: fail(f"color must be #RRGGBB: {value!r}")
        int(hex_value[1:],16)
        if not 0.0<=alpha<=1.0: fail(f"color alpha must be between 0 and 1: {value!r}")
        return hex_value.upper(),alpha
    else: fail(f"unsupported color value: {value!r}")

def to_qml(value):
    hexv,alpha=parse_color(value)
    if alpha>=1.0: return hexv
    return f"#{round(alpha*255):02X}{hexv[1:]}"

def to_css(value):
    hexv,alpha=parse_color(value)
    if alpha>=1.0: return hexv.lower()
    r=int(hexv[1:3],16); g=int(hexv[3:5],16); b=int(hexv[5:7],16)
    return f"rgba({r}, {g}, {b}, {alpha:g})"

def kebab(name:str):
    out=[]
    for c in name:
        if c.isupper(): out.append('-'+c.lower())
        else: out.append(c)
    return ''.join(out)

def qml_identifier(name:str):
    return f"size{name}" if name[:1].isdigit() else name

def qml_font_family(value:str):
    return value.split(",",1)[0].strip().strip("\"'")

def rgb(value):
    hexv,alpha=parse_color(value)
    if alpha < 1.0: fail(f"contrast checks require opaque colors, got {value!r}")
    return (int(hexv[1:3],16)/255.0,int(hexv[3:5],16)/255.0,int(hexv[5:7],16)/255.0)

def relative_luminance(value):
    def linear(ch): return ch/12.92 if ch<=0.04045 else ((ch+0.055)/1.055)**2.4
    r,g,b=(linear(c) for c in rgb(value))
    return 0.2126*r+0.7152*g+0.0722*b

def contrast_ratio(fg,bg):
    f=relative_luminance(fg); b=relative_luminance(bg)
    l1,l2=max(f,b),min(f,b)
    return (l1+0.05)/(l2+0.05)

def build_theme_qml(tokens):
    lines=[]
    lines.append("pragma Singleton")
    lines.append("import QtQuick")
    lines.append("")
    lines.append("QtObject {")
    lines.append(f'    readonly property string productName: "{tokens["name"]}"')
    lines.append(f'    readonly property string tokenVersion: "{tokens["version"]}"')
    lines.append('    readonly property var availableThemes: ["' + '","'.join(tokens["themes"].keys()) + '"]')
    lines.append("")
    lines.append('    property string themeName: "dark"')
    lines.append("    property real scale: 1.0")
    lines.append("    property bool reduceMotion: false")
    lines.append("")
    lines.append("    readonly property var palettes: ({")
    themes=list(tokens["themes"].items())
    for ti,(name,theme) in enumerate(themes):
        lines.append(f'        "{name}": {{')
        cols=list(theme["colors"].items())
        for ci,(cn,cv) in enumerate(cols):
            comma="," if ci<len(cols)-1 else ""
            lines.append(f'            "{cn}": "{to_qml(cv)}"{comma}')
        comma2="," if ti<len(themes)-1 else ""
        lines.append(f"        }}{comma2}")
    lines.append("    })")
    lines.append('    readonly property var palette: palettes[themeName] ? palettes[themeName] : palettes["dark"]')
    lines.append("")
    for cn in tokens["themes"]["dark"]["colors"]:
        lines.append(f'    readonly property color {cn}: palette["{cn}"]')
    lines.append("")
    lines.append("    readonly property QtObject spacing: QtObject {")
    for k,v in tokens["spacing"].items():
        if isinstance(v,int): lines.append(f'        readonly property int {qml_identifier(k)}: {v}')
    lines.append("    }")
    lines.append("    readonly property QtObject radius: QtObject {")
    for k,v in tokens["radius"].items():
        if isinstance(v,int): lines.append(f'        readonly property int {qml_identifier(k)}: {v}')
    lines.append("    }")
    lines.append("    readonly property QtObject borders: QtObject {")
    for k,v in tokens["borders"].items():
        if isinstance(v,int): lines.append(f'        readonly property int {qml_identifier(k)}: {v}')
    lines.append("    }")
    lines.append("    readonly property QtObject typography: QtObject {")
    lines.append('        readonly property string fontHeading: ' + json.dumps(qml_font_family(tokens["typography"]["fontFamily"]["heading"])))
    lines.append('        readonly property string fontBody: ' + json.dumps(qml_font_family(tokens["typography"]["fontFamily"]["body"])))
    lines.append('        readonly property string fontMono: ' + json.dumps(qml_font_family(tokens["typography"]["fontFamily"]["mono"])))
    for fk, fv in tokens["typography"]["fontFamily"].items():
        if fk not in {"heading", "body", "mono"}:
            lines.append(f'        readonly property string {fk}: ' + json.dumps(qml_font_family(fv)))
    lines.append("        readonly property QtObject scale: QtObject {")
    for k,v in tokens["typography"]["scale"].items():
        if isinstance(v,int): lines.append(f'            readonly property int {qml_identifier(k)}: {v}')
    lines.append("        }")
    lines.append("        readonly property QtObject weight: QtObject {")
    for k,v in tokens["typography"]["weight"].items():
        if isinstance(v,int): lines.append(f'            readonly property int {qml_identifier(k)}: {v}')
    lines.append("        }")
    lines.append("        readonly property QtObject lineHeight: QtObject {")
    for k,v in tokens["typography"]["lineHeight"].items():
        if isinstance(v,(int,float)): lines.append(f'            readonly property real {qml_identifier(k)}: {v}')
    lines.append("        }")
    lines.append("        readonly property QtObject tracking: QtObject {")
    for k,v in tokens["typography"]["tracking"].items():
        lines.append(f'            readonly property string {qml_identifier(k)}: "{v}"')
    lines.append("        }")
    typography = tokens["typography"]
    nested_styles = {
        "body": {
            "size": typography["scale"].get("body", 14),
            "lineHeight": typography["lineHeight"].get("body", 1.5),
        },
        "caption": {
            "size": typography["scale"].get("caption", 12),
            "weight": typography["weight"].get("caption", 400),
            "lineHeight": typography["lineHeight"].get("caption", 1.4),
        },
        "display": {
            "size": typography["scale"].get("display", 48),
            "weight": typography["weight"].get("bold", 700),
            "letterSpacing": typography["tracking"].get("tight", "-0.02em"),
        },
        "heading1": {
            "size": typography["scale"].get("heading1", 36),
            "weight": typography["weight"].get("bold", 700),
            "letterSpacing": typography["tracking"].get("tight", "-0.02em"),
        },
        "heading2": {
            "size": typography["scale"].get("2xl", 20),
            "weight": typography["weight"].get("semibold", 600),
        },
        "heading3": {
            "size": typography["scale"].get("heading3", 24),
            "weight": typography["weight"].get("semibold", 600),
        },
        "label": {
            "size": typography["scale"].get("label", 14),
            "weight": typography["weight"].get("label", 500),
        },
        "title": {
            "size": typography["scale"].get("title", 18),
            "weight": typography["weight"].get("title", 600),
        },
        "bodyStrong": {
            "size": typography["scale"].get("bodyStrong", 15),
            "weight": typography["weight"].get("medium", 500),
        },
    }
    for name, style in nested_styles.items():
        lines.append(f'        readonly property QtObject {name}: QtObject {{')
        for prop, value in style.items():
            qml_type = "real" if isinstance(value, float) else "int" if isinstance(value, int) else "string"
            qml_value = json.dumps(value) if isinstance(value, str) else value
            lines.append(f'            readonly property {qml_type} {prop}: {qml_value}')
        lines.append("        }")
    for alias, weight_name in [
        ("weightSemibold", "semibold"),
        ("weightMedium", "medium"),
        ("weightBold", "bold"),
    ]:
        if weight_name in tokens["typography"]["weight"]:
            lines.append(f'        readonly property int {alias}: {tokens["typography"]["weight"][weight_name]}')
    lines.append("    }")
    lines.append("    readonly property QtObject motion: QtObject {")
    lines.append("        readonly property QtObject duration: QtObject {")
    for k,v in tokens["motion"]["duration"].items():
        if isinstance(v,int): lines.append(f'            readonly property int {qml_identifier(k)}: {v}')
    lines.append("        }")
    lines.append("        readonly property QtObject easing: QtObject {")
    for k,v in tokens["motion"]["easing"].items():
        lines.append(f'            readonly property string {qml_identifier(k)}: "{v}"')
    lines.append("        }")
    lines.append(f'        readonly property bool reduceMotion: {str(bool(tokens["motion"].get("reduceMotion",True))).lower()}')
    for alias in ["durationFast", "durationNormal", "durationSlow"]:
        if alias in tokens["motion"]["duration"]:
            lines.append(f'        readonly property int {alias}: {tokens["motion"]["duration"][alias]}')
    lines.append("    }")
    lines.append("    readonly property QtObject icon: QtObject {")
    for k,v in tokens["icon"]["size"].items():
        if isinstance(v,int): lines.append(f'        readonly property int {qml_identifier(k)}: {v}')
    if "sizes" in tokens["icon"]:
        lines.append("        readonly property QtObject sizes: QtObject {")
        for k,v in tokens["icon"]["sizes"].items():
            if isinstance(v,int):
                lines.append(f'            readonly property int {qml_identifier(k)}: {v}')
        lines.append("        }")
    lines.append(f'        readonly property real stroke: {tokens["icon"].get("stroke",1.75)}')
    if "strokeWidth" in tokens["icon"]:
        lines.append(f'        readonly property real strokeWidth: {tokens["icon"]["strokeWidth"]}')
    lines.append("    }")
    lines.append("    readonly property QtObject layout: QtObject {")
    lines.append(f'        readonly property int touchTarget: {tokens["layout"].get("touchTarget",40)}')
    for name in ["panel", "spaces", "launcher", "controlCenter"]:
        if name in tokens["layout"]:
            lines.append(f'        readonly property QtObject {name}: QtObject {{')
            for prop, value in tokens["layout"][name].items():
                qml_type = "real" if isinstance(value, float) else "int" if isinstance(value, int) else "string"
                qml_value = json.dumps(value) if isinstance(value, str) else value
                lines.append(f'            readonly property {qml_type} {qml_identifier(prop)}: {qml_value}')
            lines.append("        }")
    lines.append("        readonly property QtObject classes: QtObject {")
    for cname,cvals in tokens["layout"]["classes"].items():
        lines.append(f'            readonly property QtObject {cname}: QtObject {{')
        for ck,cv in cvals.items():
            if isinstance(cv,int): lines.append(f'                readonly property int {qml_identifier(ck)}: {cv}')
        lines.append("            }")
    lines.append("        }")
    lines.append("    }")
    lines.append("    readonly property QtObject accessibility: QtObject {")
    for k,v in tokens["accessibility"].items():
        if isinstance(v,(int,float)) and not isinstance(v,bool): lines.append(f'        readonly property real {qml_identifier(k)}: {v}')
    lines.append("    }")
    lines.append("")
    lines.append("    function scaled(value) { return Math.round(value * scale) }")
    lines.append("    function scaledInt(value) { return Math.round(value * scale) }")
    lines.append("    function motionDuration(ms) { return reduceMotion ? 0 : ms; }")
    lines.append("    function layoutClass(width) { if (width < 1280) return 'compact'; if (width < 1920) return 'regular'; if (width < 2560) return 'wide'; return 'ultrawide'; }")
    lines.append("}")
    return "\n".join(lines)+"\n"

def build_qmldir():
    return "module Klyvera.Styles\nsingleton Theme 1.0 Theme.qml\n"

def build_tokens_css(tokens):
    lines=[]
    lines.append(":root {")
    dark=tokens["themes"]["dark"]["colors"]
    for cn,cv in dark.items(): lines.append(f"  --kly-{kebab(cn)}: {to_css(cv)};")
    lines.append(f"  --kly-font-heading: {tokens['typography']['fontFamily']['heading']};")
    lines.append(f"  --kly-font-body: {tokens['typography']['fontFamily']['body']};")
    lines.append(f"  --kly-font-mono: {tokens['typography']['fontFamily']['mono']};")
    for k,v in tokens["motion"]["duration"].items(): lines.append(f"  --kly-motion-{kebab(k)}: {v}ms;")
    lines.append("}")
    lines.append("[data-theme='light'] {")
    light=tokens["themes"]["light"]["colors"]
    for cn,cv in light.items(): lines.append(f"  --kly-{kebab(cn)}: {to_css(cv)};")
    lines.append("}")
    lines.append("[data-theme='high-contrast'] {")
    hc=tokens["themes"]["high-contrast"]["colors"]
    for cn,cv in hc.items(): lines.append(f"  --kly-{kebab(cn)}: {to_css(cv)};")
    lines.append("}")
    lines.append("@media (prefers-color-scheme: light) {")
    lines.append("  :root:not([data-theme]) {")
    for cn,cv in light.items(): lines.append(f"    --kly-{kebab(cn)}: {to_css(cv)};")
    lines.append("  }")
    lines.append("}")
    lines.append("@media (prefers-reduced-motion: reduce) {")
    lines.append("  :root { --kly-motion-fast: 0ms; --kly-motion-base: 0ms; --kly-motion-slow: 0ms; }")
    lines.append("}")
    return "\n".join(lines)+"\n"

def build_contrast_report(tokens):
    failures=[]
    lines=[]
    lines.append("# Contrast report")
    lines.append("")
    lines.append(f"Generated by design/generators/generate.py from design/tokens.json (version {tokens['version']}).")
    lines.append("")
    for theme_name, theme in tokens["themes"].items():
        label=theme.get("label", theme_name)
        colors=theme["colors"]
        lines.append(f"## {label} (`{theme_name}`)")
        lines.append("")
        for fg in TEXT_FOREGROUNDS:
            for bg in TEXT_BACKGROUNDS:
                if fg in colors and bg in colors:
                    ratio=contrast_ratio(colors[fg], colors[bg])
                    ok = ratio>=NORMAL_TEXT_MIN
                    if not ok: failures.append((theme_name,fg,bg,ratio))
                    lines.append(f"- {fg} on {bg}: {ratio:.2f}:1 {'PASS' if ok else 'FAIL'}")
        for fg in ["onAccent"]:
            for bg in ON_ACCENTS:
                if fg in colors and bg in colors:
                    ratio=contrast_ratio(colors[fg], colors[bg])
                    ok = ratio>=UI_COMPONENT_MIN
                    if not ok: failures.append((theme_name,fg,bg,ratio))
                    lines.append(f"- {fg} on {bg}: {ratio:.2f}:1 {'PASS' if ok else 'FAIL'}")
        lines.append("")
    if failures:
        lines.append("## Failures"); lines.append("")
        for f in failures: lines.append(f"- {f[0]} {f[1]} on {f[2]}: {f[3]:.2f}:1")
        lines.append("")
    else:
        lines.append("All required pairs pass WCAG AA."); lines.append("")
    return "\n".join(lines)+"\n", failures

def build_outputs(tokens):
    rep, fails = build_contrast_report(tokens)
    return {
        THEME_QML: build_theme_qml(tokens),
        QMLDIR: build_qmldir(),
        TOKENS_CSS: build_tokens_css(tokens),
        CONTRAST_DOC: rep,
    }, fails

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args=parser.parse_args()
    tokens=load_tokens()
    outputs, failures = build_outputs(tokens)
    if failures and not args.check:
        print(f"contrast failures: {len(failures)}", file=sys.stderr)
    if args.check:
        ok=True
        for path, content in outputs.items():
            if not path.exists():
                print(f"missing generated file: {path}", file=sys.stderr); ok=False; continue
            if path.read_text(encoding="utf-8") != content:
                print(f"stale generated file: {path}", file=sys.stderr); ok=False
        if failures:
            print(f"contrast failures: {len(failures)}", file=sys.stderr); ok=False
        raise SystemExit(0 if ok else 1)
    for path, content in outputs.items():
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
    if failures: raise SystemExit(1)
    print("generated tokens artifacts")

if __name__=="__main__":
    main()
