#!/usr/bin/env bash
set -euo pipefail


ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

VENV_DIR="$ROOT_DIR/.venv"
PYTHON3="${PYTHON3:-python3}"

echo "Bootstrapping Klyvera development environment..."
echo "Root directory: $ROOT_DIR"
echo "Virtual environment: $VENV_DIR"
echo ""

if [[ ! -d "$VENV_DIR" ]]; then
    echo "Creating virtual environment..."
    "$PYTHON3" -m venv "$VENV_DIR"
else
    echo "Virtual environment already exists"
fi

if [[ -x "$VENV_DIR/bin/python" ]]; then
    VENV_BIN="$VENV_DIR/bin"
    VENV_PYTHON="$VENV_BIN/python"
elif [[ -x "$VENV_DIR/Scripts/python.exe" ]]; then
    VENV_BIN="$VENV_DIR/Scripts"
    VENV_PYTHON="$VENV_BIN/python.exe"
else
    echo "Could not find the virtual environment Python executable" >&2
    exit 1
fi

echo "Upgrading pip..."
"$VENV_PYTHON" -m pip install --upgrade pip

echo "Installing Python dependencies..."
"$VENV_PYTHON" -m pip install PySide6-Essentials shellcheck-py jsonschema playwright

echo "Installing Playwright Chromium..."
"$VENV_PYTHON" -m playwright install chromium

if [[ -f web/package.json ]]; then
    echo "Installing web dependencies (npm ci)..."
    cd web
    npm ci
    cd "$ROOT_DIR"
else
    echo "No web/package.json found, skipping npm install"
fi

echo ""
echo "Bootstrap complete!"
if [[ "$VENV_BIN" == "$VENV_DIR/Scripts" ]]; then
    echo "To activate the environment in PowerShell, run:"
    echo "  .venv\\Scripts\\Activate.ps1"
else
    echo "To activate the environment in your shell, run:"
    echo "  source $VENV_DIR/bin/activate"
fi
echo ""
echo "The environment includes:"
echo "  - PySide6-Essentials (Qt bindings, includes qmllint)"
echo "  - shellcheck-py (shell script linting)"
echo "  - jsonschema (JSON Schema validation)"
echo "  - playwright (browser automation)"
echo "  - Chromium for Playwright"
echo "  - web/node_modules (from npm ci)"
