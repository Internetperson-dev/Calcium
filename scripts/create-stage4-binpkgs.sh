#!/bin/bash
set -euo pipefail

# Creates a filtered binary package tarball from the current system
# for use in CI.  Only includes packages relevant to the ISO build.
#
# Usage:  sudo scripts/create-stage4-binpkgs.sh
# Output: /tmp/calcium-binpkgs.tar.zst
#
# Upload the output to a GitHub Release named "calcium-binpkgs",
# then CI will pick it up automatically.

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WORLD_FILE="${REPO_DIR}/world"
PKGDIR="${PKGDIR:-/var/cache/binpkgs}"
OUTDIR="${OUTDIR:-/tmp/calcium-stage4}"
OUTPUT="${OUTPUT:-/tmp/calcium-binpkgs.tar.zst}"
NEEDED=""

# ---- collect what we need ----
# 1) packages from the world file
if [ -f "$WORLD_FILE" ]; then
  NEEDED+=" $(grep -v '^#' "$WORLD_FILE" | grep -v '^$' | cut -d: -f1)"
fi

# 2) explicit CI packages
NEEDED+=" net-misc/curl sys-kernel/gentoo-kernel-bin sys-kernel/linux-firmware"
NEEDED+=" sys-kernel/dracut sys-boot/limine dev-libs/libisoburn"
NEEDED+=" app-shells/zsh dev-vcs/git app-arch/7zip sys-auth/elogind"
NEEDED+=" dev-lang/flutter-bin gui-wm/hyprland x11-drivers/nvidia-drivers"
NEEDED+=" sys-devel/gcc"

# 3) LLVM slots — key source of CI pain
NEEDED+=" llvm-core/llvm:21 llvm-core/llvm:22"
NEEDED+=" llvm-core/clang:21 llvm-core/clang:22"
NEEDED+=" llvm-core/lld:21 llvm-core/lld:22"
NEEDED+=" llvm-runtimes/compiler-rt:21 llvm-runtimes/compiler-rt:22"

# ---- deduplicate ----
NEEDED=$(echo "$NEEDED" | tr ' ' '\n' | sort -u | tr '\n' ' ')

echo "=== Packages needed: $(echo $NEEDED | wc -w) unique entries ==="

# ---- locate or create binary packages ----
rm -rf "$OUTDIR"
mkdir -p "$OUTDIR"

missing=0
for atom in $NEEDED; do
  # Strip :slot suffix for matching
  pkg_name="${atom%%:*}"
  pkg_slot="${atom##*:}"
  [ "$pkg_slot" = "$pkg_name" ] && pkg_slot=""

  # Find installed version
  if [ -n "$pkg_slot" ]; then
    inst_ver=$(qlop -nc "$pkg_name" 2>/dev/null | tr ' ' '\n' | grep ":$pkg_slot" | tail -1 || true)
  else
    inst_ver=$(qlist -IV "$pkg_name" 2>/dev/null | tail -1 || true)
  fi

  if [ -z "$inst_ver" ]; then
    echo "  SKIP ${atom} — not installed"
    continue
  fi

  # Strip :slot from the version if present
  pkg_ver="${inst_ver%:*}"

  # Check if binpkg exists
  bpkg_path=$(find "$PKGDIR" -name "${pkg_name//\//-}-${pkg_ver}*.tar.*" 2>/dev/null | head -1)
  if [ -n "$bpkg_path" ]; then
    cp -a "$bpkg_path" "$OUTDIR/"
    echo "  OK   ${atom} → $(basename "$bpkg_path")"
  else
    # Try quickpkg
    echo "  PKG  ${atom} — not in binpkgs, running quickpkg..."
    if quickpkg --include-config=y --include-modules=y "$atom" 2>/dev/null; then
      bpkg_path=$(find "$PKGDIR" -name "${pkg_name//\//-}-${pkg_ver}*.tar.*" 2>/dev/null | head -1)
      if [ -n "$bpkg_path" ]; then
        cp -a "$bpkg_path" "$OUTDIR/"
        echo "  OK   ${atom} (quickpkg'd) → $(basename "$bpkg_path")"
      else
        echo "  FAIL ${atom} — quickpkg failed to produce output"
        ((missing++))
      fi
    else
      echo "  FAIL ${atom} — quickpkg failed"
      ((missing++))
    fi
  fi
done

echo ""
echo "=== Collected $(ls "$OUTDIR" | wc -l) binary packages ==="
if [ "$missing" -gt 0 ]; then
  echo "WARNING: ${missing} packages failed to package"
fi

echo ""
echo "=== Creating tarball: ${OUTPUT} ==="
tar -I 'zstd -1' -cf "$OUTPUT" -C "$OUTDIR" .
echo "Done: $(ls -lh "$OUTPUT" | awk '{print $5}')"
