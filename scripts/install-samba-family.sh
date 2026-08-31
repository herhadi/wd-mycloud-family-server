#!/bin/bash
set -eu

# Install the family Samba layout on WD My Cloud Gen1.
# This script is intentionally conservative:
# - never formats disks
# - never modifies /etc/fstab
# - preserves the active smb.conf as a timestamped backup
# - creates only directories/users/groups explicitly requested via arguments
#
# Usage (example):
#   ./install-samba-family.sh --user ayah --user ibu --user anak
#
# Run as root on the WD, after verifying /data is mounted.

DATA_DIR=/data
SAMBA_CONF=/etc/samba/smb.conf
BACKUP_DIR=/etc/samba/backup

usage() {
  echo "Usage: $0 --user NAME [--user NAME ...]"
  exit 1
}

[ "$(id -u)" -eq 0 ] || { echo 'ERROR: run as root.' >&2; exit 1; }
command -v smbd >/dev/null 2>&1 || { echo 'ERROR: smbd is not installed.' >&2; exit 1; }
command -v smbpasswd >/dev/null 2>&1 || { echo 'ERROR: smbpasswd is not installed.' >&2; exit 1; }
mountpoint -q "$DATA_DIR" || { echo "ERROR: $DATA_DIR is not mounted." >&2; exit 1; }

USERS=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --user)
      [ "$#" -ge 2 ] || usage
      case "$2" in
        ''|*[!a-zA-Z0-9._-]*) echo "ERROR: invalid username: $2" >&2; exit 1 ;;
      esac
      USERS="$USERS $2"
      shift 2
      ;;
    *) usage ;;
  esac
done

[ -n "$USERS" ] || usage

mkdir -p /data/Private /data/Shared /data/Media
chmod 0755 /data/Private /data/Shared /data/Media

# One Unix group owns the common area. Private directories are owned by
# the corresponding user and are not traversable by other family users.
if ! getent group family >/dev/null 2>&1; then
  groupadd family
fi

for USER in $USERS; do
  if ! id "$USER" >/dev/null 2>&1; then
    useradd -m -s /bin/false -G family "$USER"
  else
    usermod -a -G family "$USER"
  fi

  mkdir -p "/data/Private/$USER"
  chown "$USER:family" "/data/Private/$USER"
  chmod 0700 "/data/Private/$USER"

done

chown root:family /data/Shared /data/Media
chmod 2770 /data/Shared /data/Media

mkdir -p "$BACKUP_DIR"
TS=$(date +%Y%m%d-%H%M%S)
if [ -f "$SAMBA_CONF" ]; then
  cp -p "$SAMBA_CONF" "$BACKUP_DIR/smb.conf.$TS"
fi

cat > "$SAMBA_CONF" <<'EOF'
[global]
   workgroup = WORKGROUP
   server string = MyCloud Family
   security = user
   map to guest = Bad User
   log level = 1
   max log size = 1000
   unix extensions = yes
   load printers = no
   disable spoolss = yes

[Shared]
   path = /data/Shared
   browseable = yes
   read only = no
   guest ok = no
   force group = family
   create mask = 0660
   directory mask = 2770

[Media]
   path = /data/Media
   browseable = yes
   read only = no
   guest ok = no
   force group = family
   create mask = 0660
   directory mask = 2770
EOF

for USER in $USERS; do
  cat >> "$SAMBA_CONF" <<EOF

[Private-$USER]
   path = /data/Private/$USER
   browseable = yes
   read only = no
   guest ok = no
   valid users = $USER
   force user = $USER
   create mask = 0600
   directory mask = 0700
EOF
done

if ! testparm -s >/tmp/smb-testparm.$$ 2>&1; then
  cat /tmp/smb-testparm.$$ >&2
  rm -f /tmp/smb-testparm.$$
  echo 'ERROR: generated Samba configuration is invalid; restoring previous configuration.' >&2
  if [ -f "$BACKUP_DIR/smb.conf.$TS" ]; then
    cp -p "$BACKUP_DIR/smb.conf.$TS" "$SAMBA_CONF"
  fi
  exit 1
fi
rm -f /tmp/smb-testparm.$$

service smbd restart

echo
printf '%s\n' 'Samba family layout installed.'
echo 'Set an SMB password for each family user with:'
echo '  smbpasswd USER'
echo
echo 'Shares:'
for USER in $USERS; do echo "  Private-$USER"; done
echo '  Shared'
echo '  Media'
