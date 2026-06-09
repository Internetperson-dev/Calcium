#!/bin/sh
# Recombine split binary files (created by `split -d -b 30M`)
# Usage: scripts/recombine.sh [directory]

set -eu

base_dir="${1:-.}"
total=0

for first_chunk in $(find "$base_dir" -name '*.00' -type f 2>/dev/null | sort); do
  base="${first_chunk%.00}"
  [ ! -f "$base" ] || continue

  # Collect chunks in sorted order
  chunks=""
  for c in $(ls "${base}".?? 2>/dev/null | sort); do
    chunks="$chunks $c"
  done
  [ -n "$chunks" ] || continue

  # Count chunks
  set -- $chunks
  count=$#

  echo "Recombining: ${base##*/} (${count} chunks)"

  # Recombine
  cat $chunks > "$base"

  # Verify size
  orig_size=$(wc -c < "$base")
  chunk_sum=0
  for c in $chunks; do
    cs=$(wc -c < "$c")
    chunk_sum=$((chunk_sum + cs))
  done

  if [ "$orig_size" -eq "$chunk_sum" ]; then
    echo "  Verified ($orig_size bytes)"
    rm -f $chunks
    total=$((total + 1))
  else
    echo "  MISMATCH: expected $chunk_sum, got $orig_size - keeping chunks"
    rm -f "$base"
  fi
done

echo "Recombined $total files"
