s = open('/root/Desktop/klyvera/design/generators/generate.py').read()
idx = s.find('        raise SystemExit(0 if ok else 1)')
if idx >= 0:
    pass

start = s.find('def build_outputs')
if start == -1:
    raise SystemExit('bad')
end_marker = s.find('\n        raise SystemExit(0 if ok else 1)')
if end_marker >= 0:
    s2 = s[:start]
    s2 += '''def build_outputs(tokens):
    return {
        THEME_QML: build_theme_qml(tokens),
        QMLDIR: build_qmldir(),
        TOKENS_CSS: build_tokens_css(tokens),
        CONTRAST_DOC: build_contrast_report(tokens)[0],
    }, build_contrast_report(tokens)[1]

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
            current = path.read_text(encoding="utf-8")
            if current != content:
                print(f"stale generated file: {path}", file=sys.stderr); ok=False
        if failures:
            print(f"contrast failures: {len(failures)}", file=sys.stderr); ok=False
        raise SystemExit(0 if ok else 1)
    for path, content in outputs.items():
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
    if failures:
        raise SystemExit(1)
    print("generated tokens artifacts")

if __name__=="__main__":
    main()
'''
    open('/root/Desktop/klyvera/design/generators/generate.py','w').write(s2)
    print('fixed')
else:
    print('nope')
