#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ ! -d .git ]]; then
  echo "error: run this script inside the Klyvera git repository" >&2
  exit 1
fi

chmod +x .githooks/pre-commit scripts/*.sh
git config core.hooksPath .githooks
echo "Git hooks installed. Pre-commit runs: scripts/check.sh --fast"
