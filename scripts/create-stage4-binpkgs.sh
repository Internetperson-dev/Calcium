#!/bin/bash
set -euo pipefail

# Creates a binary-package tarball from ALL installed packages on the
# current system.  All temp/cache paths live in the repo (NVMe) so the
# host drive is never touched.
#
# Upload the result to the "calcium-binpkgs" GitHub Release so CI can
# install via --usepkgonly instead of compiling from source.
#
# Usage:  sudo scripts/create-stage4-binpkgs.sh
# Output: <repo>/calcium-binpkgs.tar.zst

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PKGDIR="${PKGDIR:-${REPO_DIR}/.stage4-cache}"
OUTPUT="${OUTPUT:-${REPO_DIR}/calcium-binpkgs.tar.zst}"

# Keep EVERYTHING off the host drive
export PKGDIR
export PORTAGE_TMPDIR="${PORTAGE_TMPDIR:-${REPO_DIR}/.stage4-tmp}"
export DISTDIR="${DISTDIR:-${REPO_DIR}/.stage4-dist}"

command -v qlist &>/dev/null || { echo "FATAL: install app-portage/gentoolkit"; exit 1; }

rm -rf "$PKGDIR" "$PORTAGE_TMPDIR"
mkdir -p "$PKGDIR" "$PORTAGE_TMPDIR" "$DISTDIR"

export FEATURES="${FEATURES:-} -binpkg-request-signature"

total=$(qlist -IC | wc -l)
echo "=== Binary-packaging ${total} installed packages ==="
echo "  PKGDIR:       ${PKGDIR}"
echo "  TMPDIR:       ${PORTAGE_TMPDIR}"
echo "  OUTPUT:       ${OUTPUT}"

qlist -IC | sort -u | xargs -r -n 200 \
  quickpkg --include-config=y 2>/dev/null || true

found=$(find "$PKGDIR" -name '*.gpkg.tar*' 2>/dev/null | wc -l)
echo "  ${found} binary packages created"

echo ""
echo "=== Creating stage4 tarball ==="
tar -I 'zstd -1' -cf "$OUTPUT" -C "$PKGDIR" .
echo "Done: $(stat --format=%s "$OUTPUT" 2>/dev/null | numfmt --to=iec)"

echo ""
echo "=== Cleaning up ==="
rm -rf "$PKGDIR" "$PORTAGE_TMPDIR"
echo "Removed ${PKGDIR} and ${PORTAGE_TMPDIR}"
