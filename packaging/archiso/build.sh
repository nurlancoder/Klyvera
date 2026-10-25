#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly ROOT_DIR
readonly PROFILE_DIR="$ROOT_DIR/packaging/archiso/profile"
readonly PACKAGE_DIR="${KLYVERA_PACKAGE_OUT:-$ROOT_DIR/packaging/pkgbuild/out}"
readonly REPO_DIR="${KLYVERA_LOCAL_REPO:-/var/cache/klyvera/localrepo}"
readonly ISO_REPO_DIR="$PROFILE_DIR/airootfs/usr/share/klyvera/repo"
readonly OUTPUT_DIR="$ROOT_DIR/packaging/archiso/out"
readonly WORK_DIR="$ROOT_DIR/packaging/archiso/work"

if [[ "${EUID}" -ne 0 ]]; then
  printf 'build-iso: mkarchiso must run as root on an Arch host\n' >&2
  exit 1
fi

for command in mkarchiso repo-add sha256sum; do
  if ! command -v "$command" >/dev/null 2>&1; then
    printf 'build-iso: %s is required (install archiso)\n' "$command" >&2
    exit 1
  fi
done

if ! compgen -G "$PACKAGE_DIR/*.pkg.tar.zst" >/dev/null; then
  printf 'build-iso: no packages in %s; run packaging/pkgbuild/build-packages.sh first\n' \
    "$PACKAGE_DIR" >&2
  exit 1
fi

mkdir -p "$REPO_DIR/x86_64" "$OUTPUT_DIR" "$WORK_DIR"
find "$REPO_DIR/x86_64" -maxdepth 1 -type f -delete
cp "$PACKAGE_DIR"/*.pkg.tar.zst "$REPO_DIR/x86_64/"
repo-add --quiet "$REPO_DIR/x86_64/klyvera-local.db.tar.gz" \
  "$REPO_DIR/x86_64"/*.pkg.tar.zst

rm -rf "$ISO_REPO_DIR"
mkdir -p "$ISO_REPO_DIR/x86_64"
cp "$PACKAGE_DIR"/*.pkg.tar.zst "$ISO_REPO_DIR/x86_64/"
repo-add --quiet "$ISO_REPO_DIR/x86_64/klyvera-local.db.tar.gz" \
  "$ISO_REPO_DIR/x86_64"/*.pkg.tar.zst

rm -rf "$WORK_DIR"
mkarchiso -v -w "$WORK_DIR" -o "$OUTPUT_DIR" "$PROFILE_DIR"

shopt -s nullglob
isos=("$OUTPUT_DIR"/*.iso)
if ((${#isos[@]} == 0)); then
  printf 'build-iso: mkarchiso finished but no ISO was found\n' >&2
  exit 1
fi

for iso in "${isos[@]}"; do
  sha256sum "$iso" > "$iso.sha256"
  printf 'ISO: %s\nSHA-256: %s\n' "$iso" "$iso.sha256"
done
