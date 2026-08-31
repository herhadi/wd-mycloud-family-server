# Family Server Deployment

This is the normal-service deployment path after Debian Jessie recovery is complete.

## 1. Preconditions

On the WD itself, verify:

```bash
uname -m
cat /etc/debian_version
mountpoint /data
cat /proc/mdstat
swapon --show
```

Expected platform is ARMv7l on Debian 8.x (Jessie), with `/data` mounted and the Gen1 root RAID available. Do not proceed with service installation if `/data` is not mounted.

Run the baseline checker first:

```bash
/path/to/prepare.sh
```

## 2. Samba family layout

Copy `scripts/install-samba-family.sh` to the WD and run it as root. Example:

```bash
chmod +x install-samba-family.sh
./install-samba-family.sh --user ayah --user ibu --user anak
```

Set each SMB password interactively:

```bash
smbpasswd ayah
smbpasswd ibu
smbpasswd anak
```

The generated layout is:

```text
/data/Private/<user>  0700, user-owned
/data/Shared           2770, group family
/data/Media            2770, group family
```

The script automatically backs up the old `/etc/samba/smb.conf` before replacing it and validates the new configuration with `testparm`.

## 3. Syncthing

The verified deployment uses:

```text
/usr/local/bin/syncthing
user: syncthing
state: /var/lib/syncthing
GUI:   0.0.0.0:8384 (LAN only in the verified setup)
```

The service is managed through SysV-style commands:

```bash
service syncthing start
service syncthing status
service syncthing restart
```

Do not replace the verified binary with an archive merely because the archive directory name says `v1.19.2`; the repository's verified runtime binary reports **v2.1.3**.

For phone backup, configure Syncthing-Fork to synchronize camera/photo data into a user-specific destination under `/data/Photos/` rather than into the Samba private directory unless that identity model has been intentionally designed.

## 4. Health validation

After service changes:

```bash
chmod +x health-check.sh
./health-check.sh
```

The check is non-destructive and covers platform, storage, swap, Samba, Samba configuration validity, and Syncthing.

## 5. Remote access

Do not publish TCP/445. Do not publish the Syncthing GUI directly either.

Remote access should terminate at a secure tunnel or VPN and enforce authentication. The NAS-facing side should remain on the trusted LAN.

The cloudflared troubleshooting notes in `docs/troubleshooting/` record the legacy-Jessie `wget` redirect problem encountered during testing. A downloaded binary must be checked with `file`, `sha256sum`, and `--version` before installation.

## 6. DLNA

DLNA is intentionally not installed by this baseline yet. The device has only ~226 MB RAM, so the final DLNA daemon must be selected and verified for memory footprint, Jessie compatibility, indexing behavior, and read-only media scanning before it is promoted into the standard install path.

## 7. Backup and recovery boundary

The Git repository is configuration/documentation only. It does not replace a backup of `/data`.

Before recovery or any destructive disk operation:

1. identify the actual WD disk;
2. verify `/data` and the root RAID layout;
3. preserve the clean-Jessie artifact and its recorded checksum;
4. execute each disk-writing operation only after verifying its source and target.
