#!/bin/sh
set -eu

# Restore a previously backed-up Browser Gateway binary.
# Usage:
#   webdav-gw-rollback.sh /usr/local/lib/webdav-gw/backups/webdav-gw.TIMESTAMP

TARGET="/usr/local/bin/webdav-gw"
SERVICE="webdav-gw.service"

[ "$#" -eq 1 ] || {
  echo "Usage: $0 /path/to/webdav-gw.backup" >&2
  exit 2
}

BACKUP="$1"

[ "$(id -u)" -eq 0 ] || {
  echo "ERROR: run as root." >&2
  exit 1
}

[ -f "$BACKUP" ] || {
  echo "ERROR: backup not found: $BACKUP" >&2
  exit 1
}

command -v systemctl >/dev/null 2>&1 || {
  echo "ERROR: systemctl is required." >&2
  exit 1
}

cp -p "$BACKUP" "$TARGET"
systemctl restart "$SERVICE"

if systemctl is-active --quiet "$SERVICE"; then
  echo "Rollback successful."
  echo "Restored SHA-256: $(sha256sum "$TARGET" | awk '{print $1}')"
else
  echo "ERROR: service is not active after rollback." >&2
  exit 1
fi
