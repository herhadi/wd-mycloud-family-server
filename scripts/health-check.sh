#!/bin/bash
set -eu

# Non-destructive health check for the WD My Cloud Family Server.
# Exits non-zero if a required baseline condition is missing.

fail=0
check() {
  NAME="$1"; shift
  if "$@" >/dev/null 2>&1; then
    printf 'OK   %s\n' "$NAME"
  else
    printf 'FAIL %s\n' "$NAME"
    fail=1
  fi
}

echo '=== WD My Cloud Family Server health check ==='

echo
printf '%s\n' '--- Platform ---'
printf 'Arch:   %s\n' "$(uname -m)"
printf 'Kernel: %s\n' "$(uname -r)"
printf 'Debian: %s\n' "$(cat /etc/debian_version 2>/dev/null || echo unknown)"

check '/data mounted' mountpoint -q /data
check 'root RAID device exists' test -b /dev/md0
check 'swap active' sh -c 'swapon --show 2>/dev/null | grep -q .'
check 'Samba installed' command -v smbd
check 'Samba service running' service smbd status
check 'Samba configuration valid' sh -c 'testparm -s >/dev/null 2>&1'
check 'Syncthing binary exists' test -x /usr/local/bin/syncthing
check 'Syncthing service running' service syncthing status

if command -v /usr/local/bin/syncthing >/dev/null 2>&1; then
  printf 'Syncthing: %s\n' "$('/usr/local/bin/syncthing' --version 2>/dev/null || true)"
fi

if mountpoint -q /data; then
  echo
  printf '%s\n' '--- Storage ---'
  df -h /data
fi

echo
printf '%s\n' '--- Memory ---'
free -m

echo
if [ "$fail" -eq 0 ]; then
  echo '=== HEALTHY ==='
else
  echo '=== ATTENTION REQUIRED ==='
fi
exit "$fail"
