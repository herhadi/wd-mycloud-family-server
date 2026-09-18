#!/bin/sh
set -eu

# Safe Browser Gateway upgrade for the verified WD My Cloud deployment.
# Usage:
#   webdav-gw-upgrade.sh /path/to/webdav-gw
#
# The script never touches /data. It keeps a local rollback copy outside the
# data filesystem and automatically restores the previous binary if restart
# or the post-restart service check fails.

TARGET="/usr/local/bin/webdav-gw"
SERVICE="webdav-gw.service"
BACKUP_ROOT="/usr/local/lib/webdav-gw/backups"

usage() {
  echo "Usage: $0 /path/to/webdav-gw" >&2
  exit 2
}

[ "$#" -eq 1 ] || usage
SOURCE="$1"

[ "$(id -u)" -eq 0 ] || {
  echo "ERROR: run as root." >&2
  exit 1
}

[ -f "$SOURCE" ] || {
  echo "ERROR: source binary not found: $SOURCE" >&2
  exit 1
}

[ -x "$SOURCE" ] || {
  echo "ERROR: source is not executable: $SOURCE" >&2
  exit 1
}

command -v systemctl >/dev/null 2>&1 || {
  echo "ERROR: systemctl is required." >&2
  exit 1
}

systemctl cat "$SERVICE" >/dev/null 2>&1 || {
  echo "ERROR: service not found: $SERVICE" >&2
  exit 1
}

mkdir -p "$BACKUP_ROOT"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$BACKUP_ROOT/webdav-gw.$STAMP"

if [ -f "$TARGET" ]; then
  cp -p "$TARGET" "$BACKUP"
else
  echo "ERROR: target binary does not exist: $TARGET" >&2
  exit 1
fi

OLD_SUM="$(sha256sum "$TARGET" | awk '{print $1}')"
NEW_SUM="$(sha256sum "$SOURCE" | awk '{print $1}')"

echo "Current SHA-256: $OLD_SUM"
echo "New SHA-256:     $NEW_SUM"
echo "Backup:          $BACKUP"

TMP="$TARGET.new.$$"
trap 'rm -f "$TMP"' EXIT HUP INT TERM

cp "$SOURCE" "$TMP"
chmod 755 "$TMP"
mv "$TMP" "$TARGET"
trap - EXIT HUP INT TERM

if systemctl restart "$SERVICE" && systemctl is-active --quiet "$SERVICE"; then
  echo "Upgrade successful."
  echo "Service: $SERVICE"
  echo "Binary:  $TARGET"
  echo "SHA-256: $NEW_SUM"
  exit 0
fi

echo "ERROR: service failed after upgrade; rolling back." >&2
cp -p "$BACKUP" "$TARGET"
systemctl restart "$SERVICE" || true

if systemctl is-active --quiet "$SERVICE"; then
  echo "Rollback successful. Restored: $BACKUP" >&2
else
  echo "ERROR: rollback binary restored but service is still not active." >&2
fi

exit 1
