#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly ROOT_DIR
readonly OUT_DIR="${KLYVERA_PACKAGE_OUT:-$ROOT_DIR/packaging/pkgbuild/out}"
readonly SOURCE_DIR="$ROOT_DIR/packaging/pkgbuild/sources"
readonly INPUT_ARCHIVE="${KLYVERA_PACKAGE_SOURCE_ARCHIVE:-}"
readonly INPUT_EPOCH="${KLYVERA_PACKAGE_SOURCE_DATE_EPOCH:-}"
VERSION="$(sed -n 's/^version = "\(.*\)"/\1/p' "$ROOT_DIR/core/Cargo.toml" | head -n 1)"
readonly VERSION

if [[ -z "$VERSION" ]]; then
  printf 'build-packages: could not read the workspace version\n' >&2
  exit 1
fi

required_commands=(makepkg repo-add)
if [[ -z "$INPUT_ARCHIVE" ]]; then
  required_commands+=(git)
elif [[ ! -f "$INPUT_ARCHIVE" ]]; then
  printf 'build-packages: source archive not found: %s\n' "$INPUT_ARCHIVE" >&2
  exit 1
fi

for command in "${required_commands[@]}"; do
  if ! command -v "$command" >/dev/null 2>&1; then
    printf 'build-packages: %s is required on an Arch host\n' "$command" >&2
    exit 1
  fi
done

if [[ -z "$INPUT_ARCHIVE" ]]; then
  if [[ "$(git -C "$ROOT_DIR" status --porcelain)" != "" ]]; then
    printf 'build-packages: commit changes before building release packages\n' >&2
    exit 1
  fi
fi

for package in klyvera-core klyvera-shell klyvera-meta; do
  pkgbuild="$ROOT_DIR/packaging/pkgbuild/$package/PKGBUILD"
  pkgver="$(sed -n "s/^pkgver=//p" "$pkgbuild")"
  if [[ "$pkgver" != "$VERSION" ]]; then
    printf 'build-packages: %s has pkgver %s, expected %s\n' \
      "$package" "$pkgver" "$VERSION" >&2
    exit 1
  fi
done

mkdir -p "$OUT_DIR" "$SOURCE_DIR"
find "$OUT_DIR" -maxdepth 1 -type f -delete
find "$SOURCE_DIR" -maxdepth 1 -type f -name 'klyvera-*.tar.gz' -delete

export SOURCE_DATE_EPOCH
if [[ -n "$INPUT_EPOCH" ]]; then
  if [[ ! "$INPUT_EPOCH" =~ ^[0-9]+$ ]]; then
    printf 'build-packages: source date epoch must be an integer\n' >&2
    exit 1
  fi
  SOURCE_DATE_EPOCH="$INPUT_EPOCH"
elif [[ -z "$INPUT_ARCHIVE" ]]; then
  SOURCE_DATE_EPOCH="$(git -C "$ROOT_DIR" log -1 --format=%ct)"
else
  printf 'build-packages: source date epoch is required with an external archive\n' >&2
  exit 1
fi
export SRCDEST="$SOURCE_DIR"
export PKGDEST="$OUT_DIR"

if [[ -n "$INPUT_ARCHIVE" ]]; then
  cp "$INPUT_ARCHIVE" "$SOURCE_DIR/klyvera-$VERSION.tar.gz"
else
  git -C "$ROOT_DIR" archive --format=tar.gz \
    --prefix="klyvera-$VERSION/" \
    -o "$SOURCE_DIR/klyvera-$VERSION.tar.gz" HEAD
fi

archive="$SOURCE_DIR/klyvera-$VERSION.tar.gz"

for package in klyvera-core klyvera-shell klyvera-meta; do
  printf '\n==> building %s\n' "$package"
  cp "$archive" "$ROOT_DIR/packaging/pkgbuild/$package/klyvera-$VERSION.tar.gz"
  (
    cd "$ROOT_DIR/packaging/pkgbuild/$package"
    makepkg --force --cleanbuild --nodeps --nocheck
  )
done

repo-add --quiet "$OUT_DIR/klyvera-local.db.tar.gz" "$OUT_DIR"/*.pkg.tar.zst
printf '\nPackages and local repository written to %s\n' "$OUT_DIR"
