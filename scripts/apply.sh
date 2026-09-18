#!/bin/sh
# Apply the bc250-r1 kernel patch series onto a pristine Alpine linux-lts 6.18.50 tree.
# Usage: ./apply.sh /path/to/linux-6.18
set -eu
src=${1:?usage: $0 /path/to/pristine-linux-6.18-tree}
d=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
for p in "$d"/kernel-patches/*.patch; do
  echo "== dry-run $p"
  patch -p1 -d "$src" --dry-run < "$p" || {
    echo "dry-run failed for $p, tree untouched" >&2
    exit 1
  }
done
for p in "$d"/kernel-patches/*.patch; do
  echo "== apply $p"
  patch -p1 -d "$src" < "$p"
done
echo APPLY_OK
