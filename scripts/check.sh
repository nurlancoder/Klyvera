#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

FAST=0
if [[ "${1:-}" == "--fast" ]]; then
  FAST=1
fi

FAILURES=0
SKIPPED=0

pass() { printf '  ok    %s\n' "$*"; }
skip() {
  printf '  skip  %s\n' "$*"
  SKIPPED=$((SKIPPED + 1))
}
fail() {
  printf '  FAIL  %s\n' "$*"
  FAILURES=$((FAILURES + 1))
}
section() { printf '\n%s\n' "$*"; }
has() { command -v "$1" >/dev/null 2>&1; }

section "Design tokens"
if [[ -f design/generators/generate.py ]]; then
  if has python3; then
    if python3 design/generators/generate.py --check; then
      pass "generated tokens in sync"
    else
      fail "generated tokens out of sync"
    fi
  else
    skip "python3 not installed"
  fi
else
  skip "no token generator yet"
fi

section "Shell scripts"
shopt -s nullglob
scripts=(scripts/*.sh .githooks/*)
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
  done < <(find shell preview -type f -name '*.qml' 2>/dev/null | sort)
fi
if ((${#qml_files[@]} > 0)); then
  if has qmllint; then
    if qmllint -I shell/ui -I shell/styles "${qml_files[@]}"; then
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

section "JSON Schema"
if ((FAST == 0)); then
  if [[ -f tests/validate_schemas.py ]]; then
    if has python3; then
      if python3 -c 'import jsonschema' >/dev/null 2>&1; then
        if python3 tests/validate_schemas.py; then
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

section "Website"
if ((FAST == 0)); then
  if [[ -f web/package.json ]]; then
    if has npm; then
      if [[ -d web/node_modules ]]; then
        if (cd web && npm run build --silent); then
          pass "web build"
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
