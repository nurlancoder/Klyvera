#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

PYTHON="${PYTHON3:-python3}"
if [[ -x "$ROOT_DIR/.venv/bin/python" ]]; then
  VENV_BIN="$ROOT_DIR/.venv/bin"
  PYTHON="$VENV_BIN/python"
elif [[ -x "$ROOT_DIR/.venv/Scripts/python.exe" ]]; then
  VENV_BIN="$ROOT_DIR/.venv/Scripts"
  PYTHON="$VENV_BIN/python.exe"
fi
if [[ -n "${VENV_BIN:-}" ]]; then
  PATH="$VENV_BIN:$PATH"
  export PATH
fi

FAST=0
STRICT=0
if [[ "${1:-}" == "--fast" ]]; then
  FAST=1
fi
if [[ "${1:-}" == "--strict" ]]; then
  STRICT=1
fi

FAILURES=0
SKIPPED=0

pass() { printf '  ok    %s\n' "$*"; }
skip() {
  if ((STRICT == 1)); then
    printf '  FAIL  %s (strict mode: no skips allowed)\n' "$*"
    FAILURES=$((FAILURES + 1))
  else
    printf '  skip  %s\n' "$*"
    SKIPPED=$((SKIPPED + 1))
  fi
}
fail() {
  printf '  FAIL  %s\n' "$*"
  FAILURES=$((FAILURES + 1))
}
section() { printf '\n%s\n' "$*"; }
has() { command -v "$1" >/dev/null 2>&1; }

section "Design tokens"
if [[ -f design/generators/generate.py ]]; then
  if has "$PYTHON"; then
    if "$PYTHON" design/generators/generate.py --check; then
      pass "generated tokens in sync"
    else
      fail "generated tokens out of sync"
    fi
    if [[ -f tests/theme_contract.py ]]; then
      if "$PYTHON" tests/theme_contract.py; then
        pass "theme contract"
      else
        fail "theme contract"
      fi
    else
      skip "theme contract test not found"
    fi
    if [[ -f tests/test_token_colors.py ]]; then
      if "$PYTHON" tests/test_token_colors.py; then
        pass "token color formats"
      else
        fail "token color formats"
      fi
    else
      skip "token color test not found"
    fi
  else
    skip "python3 not installed"
  fi
else
  skip "no token generator yet"
fi

section "Shell scripts"
shopt -s nullglob
scripts=(scripts/*.sh .githooks/* packaging/scripts/* packaging/pkgbuild/*.sh packaging/archiso/*.sh packaging/archiso/profile/airootfs/usr/local/bin/klyvera-live-init)
if ((${#scripts[@]} > 0)); then
  if bash -n "${scripts[@]}"; then
    pass "bash syntax"
  else
    fail "bash syntax"
  fi
  if has shellcheck; then
    if shellcheck "${scripts[@]}"; then
      pass "shellcheck"
    else
      fail "shellcheck"
    fi
  else
    skip "shellcheck not installed"
  fi
else
  skip "no shell scripts"
fi

section "Packaging"
pkgbuilds=(packaging/pkgbuild/*/PKGBUILD)
profile_scripts=(packaging/archiso/profile/profiledef.sh packaging/archiso/profile/airootfs/usr/local/bin/klyvera-live-init)
if ((${#pkgbuilds[@]} > 0)); then
  if bash -n "${pkgbuilds[@]}" "${profile_scripts[@]}"; then
    pass "PKGBUILD and profile syntax"
  else
    fail "PKGBUILD and profile syntax"
  fi
else
  skip "no PKGBUILDs yet"
fi

section "Rust core"
if [[ -f core/Cargo.toml ]]; then
  if has cargo; then
    if (cd core && cargo fmt --all --check); then
      pass "cargo fmt"
    else
      fail "cargo fmt"
    fi
    if ((FAST == 0)); then
      if (cd core && cargo clippy --all-targets -- -D warnings); then
        pass "cargo clippy"
      else
        fail "cargo clippy"
      fi
      if (cd core && cargo test --all); then
        pass "cargo test"
      else
        fail "cargo test"
      fi
    else
      skip "cargo clippy and test (fast mode)"
    fi
  else
    skip "cargo not installed"
  fi
else
  skip "no Rust workspace yet"
fi

section "QML"
qml_files=()
if [[ -d shell ]]; then
  while IFS= read -r file; do
    qml_files+=("$file")
  done < <(find shell preview tests/qml -type f -name '*.qml' ! -path 'shell/integration/quickshell/*' 2>/dev/null | sort)
fi
if ((${#qml_files[@]} > 0)); then
  qml_linter=""
  if [[ -f .venv/bin/pyside6-qmllint ]]; then
    qml_linter=".venv/bin/pyside6-qmllint"
  elif [[ -f .venv/Scripts/pyside6-qmllint.exe ]]; then
    qml_linter=".venv/Scripts/pyside6-qmllint.exe"
  elif [[ -f .venv/Scripts/pyside6-qmllint ]]; then
    qml_linter=".venv/Scripts/pyside6-qmllint"
  elif has qmllint; then
    qml_linter="qmllint"
  elif has pyside6-qmllint; then
    qml_linter="pyside6-qmllint"
  fi
  if [[ -n "$qml_linter" ]]; then
    if "$qml_linter" -I shell/ui -I shell/styles "${qml_files[@]}"; then
      pass "qmllint"
    else
      fail "qmllint"
    fi
  else
    skip "qmllint not installed"
  fi
else
  skip "no QML files yet"
fi

section "QML behaviour"
behaviour_tests=(tests/qml/*.py)
if ((${#behaviour_tests[@]} > 0)); then
  if has "$PYTHON" && "$PYTHON" -c 'import PySide6.QtCore' >/dev/null 2>&1; then
    for test in "${behaviour_tests[@]}"; do
      name="$(basename "$test" .py)"
      if "$PYTHON" "$test"; then
        pass "$name"
      else
        fail "$name"
      fi
    done
  else
    skip "PySide6 not installed"
  fi
else
  skip "no QML behaviour tests"
fi

section "JSON Schema"
if ((FAST == 0)); then
  if [[ -f tests/validate_schemas.py ]]; then
    if has "$PYTHON"; then
      if "$PYTHON" -c 'import jsonschema' >/dev/null 2>&1; then
        if "$PYTHON" tests/validate_schemas.py; then
          pass "schema examples valid"
        else
          fail "schema examples invalid"
        fi
      else
        skip "python jsonschema not installed"
      fi
    else
      skip "python3 not installed"
    fi
  else
    skip "no schema validation tests yet"
  fi
else
  skip "schema validation (fast mode)"
fi

section "Documentation"
if [[ -f tests/check_docs.py ]]; then
  if has "$PYTHON"; then
    if "$PYTHON" tests/check_docs.py; then
      pass "Markdown structure and links"
    else
      fail "Markdown structure and links"
    fi
  else
    skip "python3 not installed for documentation checks"
  fi
else
  skip "no documentation checker"
fi

section "Website"
if ((FAST == 0)); then
  if [[ -f web/package.json ]]; then
    if has npm; then
      if [[ -d web/node_modules ]]; then
        if (cd web && npm run build --silent); then
          pass "web build"
          if has "$PYTHON"; then
            if (cd web && npm run check --silent); then
              pass "web static checks"
            else
              fail "web static checks"
            fi
          else
            skip "python3 not installed for web checks"
          fi
          if has node && has curl && [[ -x web/node_modules/.bin/vite ]]; then
            preview_pid=""
            stop_preview() {
              if [[ -n "$preview_pid" ]] && kill -0 "$preview_pid"; then
                if ! kill "$preview_pid"; then
                  fail "could not stop the web preview"
                  return 1
                fi
                if wait "$preview_pid"; then
                  return 0
                else
                  preview_status=$?
                  if ((preview_status != 143)); then
                    fail "web preview stopped with status $preview_status"
                    return "$preview_status"
                  fi
                fi
              fi
            }
            (
              cd web
              exec ./node_modules/.bin/vite preview --host 127.0.0.1 --port 4173 --strictPort
            ) &
            preview_pid=$!
            trap stop_preview EXIT
            preview_ready=0
            for _ in {1..30}; do
              if ! kill -0 "$preview_pid"; then
                break
              fi
              if curl --fail --silent --show-error http://127.0.0.1:4173/ >/dev/null; then
                preview_ready=1
                break
              fi
              sleep 1
            done
            if ((preview_ready == 1)); then
              if (cd web && BASE_URL=http://127.0.0.1:4173 npm run test:browser --silent); then
                pass "web browser tests"
              else
                fail "web browser tests"
              fi
            else
              fail "web preview did not become ready"
            fi
            stop_preview
            trap - EXIT
          else
            skip "node, curl or Vite missing for web browser tests"
          fi
        else
          fail "web build"
        fi
      else
        skip "web/node_modules missing (run npm ci)"
      fi
    else
      skip "npm not installed"
    fi
  else
    skip "no website yet"
  fi
else
  skip "web build (fast mode)"
fi

printf '\n%d failure(s), %d skipped\n' "$FAILURES" "$SKIPPED"
if ((FAILURES > 0)); then
  exit 1
fi
