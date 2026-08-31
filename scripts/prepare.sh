#!/bin/bash
set -eu

# Safe baseline check/preparation for WD My Cloud Gen1.
# This script does NOT format disks, create RAID arrays, erase data,
# modify /etc/fstab, or upgrade Debian.

DATA_DIR="/data"
SWAP_DEV="/dev/sda3"

printf '%s\n' '=== WD My Cloud Family Server: prepare ==='

EXPECTED_ARCH=armv7l
if [ "$(uname -m)" != "$EXPECTED_ARCH" ]; then
  echo "ERROR: expected $EXPECTED_ARCH, got $(uname -m)" >&2
  exit 1
fi

if [ ! -f /etc/debian_version ]; then
  echo 'ERROR: /etc/debian_version not found.' >&2
  exit 1
fi

DEBIAN_VERSION=$(cat /etc/debian_version)
case "$DEBIAN_VERSION" in
  8.*) ;;
  *)
    echo "ERROR: expected Debian Jessie (8.x), got $DEBIAN_VERSION" >&2
    exit 1
    ;;
esac

echo "Debian: $DEBIAN_VERSION"
echo "Kernel: $(uname -r)"
echo "Architecture: $(uname -m)"

echo
printf '%s\n' '--- Memory ---'
free -m

echo
printf '%s\n' '--- Root filesystem ---'
if [ -b /dev/md0 ]; then
  echo 'OK: /dev/md0 exists.'
else
  echo 'WARNING: /dev/md0 does not exist.'
fi

if mountpoint -q /; then
  ROOT_SOURCE=$(findmnt -n -o SOURCE / 2>/dev/null || true)
  echo "Root mount: ${ROOT_SOURCE:-unknown}"
fi

echo
printf '%s\n' '--- Data mount ---'
if ! mountpoint -q "$DATA_DIR"; then
  echo "ERROR: $DATA_DIR is not mounted." >&2
  exit 1
fi
mount | grep " on $DATA_DIR " || true
df -h "$DATA_DIR"

# Never format or alter the data partition here. The check only reports it.
if [ -b "$SWAP_DEV" ]; then
  echo "Swap device exists: $SWAP_DEV"
fi

echo
printf '%s\n' '--- Swap ---'
if swapon --show 2>/dev/null | grep -q .; then
  swapon --show
else
  echo 'WARNING: no active swap detected.'
fi

echo
printf '%s\n' '--- Services ---'
for SERVICE in smbd syncthing; do
  if service "$SERVICE" status >/dev/null 2>&1; then
    echo "OK: $SERVICE is running."
  else
    echo "INFO: $SERVICE is not running or has no service status command."
  fi
done

if command -v testparm >/dev/null 2>&1; then
  if testparm -s >/dev/null 2>&1; then
    echo 'OK: Samba configuration passes testparm.'
  else
    echo 'WARNING: Samba configuration failed testparm.'
  fi
fi

if [ -x /usr/local/bin/syncthing ]; then
  echo "Syncthing binary: $(/usr/local/bin/syncthing --version 2>/dev/null || echo unknown)"
fi

echo
echo '=== Safe prepare checks complete ==='
