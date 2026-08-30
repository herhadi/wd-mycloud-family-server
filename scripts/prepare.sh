#!/bin/bash
set -eu

# Safe baseline check/preparation for WD My Cloud Gen1.
# This script does NOT format disks, create RAID arrays, erase data, or upgrade Debian.

DATA_DIR="/data"
SWAP_DEV="/dev/sda3"

printf '%s\n' '=== WD My Cloud Family Server: prepare ==='

[ "$(uname -m)" = "armv7l" ] || {
  echo "ERROR: expected armv7l, got $(uname -m)" >&2
  exit 1
}

if [ ! -f /etc/debian_version ]; then
  echo 'ERROR: /etc/debian_version not found.' >&2
  exit 1
fi

echo "Debian: $(cat /etc/debian_version)"
echo "Kernel: $(uname -r)"
echo "Architecture: $(uname -m)"

echo
printf '%s\n' '--- Memory ---'
free -m

echo
printf '%s\n' '--- Data mount ---'
if ! mountpoint -q "$DATA_DIR"; then
  echo "ERROR: $DATA_DIR is not mounted." >&2
  exit 1
fi
mount | grep " on $DATA_DIR " || true
df -h "$DATA_DIR"

echo
printf '%s\n' '--- Swap ---'
if swapon --show 2>/dev/null | grep -q .; then
  swapon --show
else
  echo "WARNING: no active swap detected."
fi

if [ -b "$SWAP_DEV" ]; then
  echo "Swap device exists: $SWAP_DEV"
fi

echo
echo '=== Safe prepare checks complete ==='
