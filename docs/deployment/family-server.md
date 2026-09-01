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

## 2. Canonical family storage layout

The final storage model is:

```text
/data/
├── Family/
│   ├── Documents/
│   ├── Photos/
│   │   ├── Ayah/
│   │   ├── Ibu/
│   │   ├── Anak1/
│   │   ├── Anak2/
│   │   └── Anak3/
│   ├── Shared/
│   └── Videos/
├── Ayah/
├── Ibu/
├── Anak1/
├── Anak2/
└── Anak3/
```

There is no `/data/Private`, `/data/Shared`, or `/data/Media` layout in the final model.

The five directories directly under `/data` are private member roots and must use mode `700` with matching member ownership.

## 3. Samba family layout

The final Samba shares are:

```text
Private-Ayah
Private-Ibu
Private-Anak1
Private-Anak2
Private-Anak3
FamilyDocs
FamilyShared
FamilyVideos
FamilyPhotos
```

The private shares are isolated to their matching member. `FamilyDocs`, `FamilyShared`, and `FamilyVideos` are read/write. `FamilyPhotos` is read-only to family Samba users.

The script in `scripts/install-samba-family.sh` is a deployment aid and must be kept aligned with this final `/data` layout before being used for a fresh rebuild.

Set each SMB password interactively:

```bash
smbpasswd ayah
smbpasswd ibu
smbpasswd anak1
smbpasswd anak2
smbpasswd anak3
```

The live configuration must be validated with `testparm` before activation.

## 4. Syncthing

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

Phone photo backup destinations are:

```text
/data/Family/Photos/Ayah
/data/Family/Photos/Ibu
/data/Family/Photos/Anak1
/data/Family/Photos/Anak2
/data/Family/Photos/Anak3
```

The phone-side photo folder is configured as Send Only.

## 5. WebDAV

WebDAV v5.15.0 runs through `webdav.service` on TCP 6065. The service uses `/etc/webdav/config.yml` and maps each account directly to `/data` without `/opt/webdav` bind mounts.

Logical view:

```text
<member>
├── private  → /data/<member>
└── family   → /data/Family
```

The global WebDAV permission is `CRUD`, with `/family/Photos` restricted to `R` by a path-specific rule. Private roots are isolated by the per-user directory mapping and filesystem ownership.

## 6. Health validation

After service changes:

```bash
chmod +x health-check.sh
./health-check.sh
```

The check is non-destructive and covers platform, storage, swap, Samba, Samba configuration validity, and Syncthing.

## 7. Remote access

Do not publish TCP/445. Do not publish the Syncthing GUI directly either.

Remote access should terminate at a secure tunnel or VPN and enforce authentication. The NAS-facing side should remain on the trusted LAN.

The cloudflared troubleshooting notes in `docs/troubleshooting/` record the legacy-Jessie `wget` redirect problem encountered during testing. A downloaded binary must be checked with `file`, `sha256sum`, and `--version` before installation.

## 8. DLNA

DLNA is intentionally not installed by this baseline yet. The device has only ~226 MB RAM, so the final DLNA daemon must be selected and verified for memory footprint, Jessie compatibility, indexing behavior, and read-only media scanning before it is promoted into the standard install path.

## 9. Backup and recovery boundary

The Git repository is configuration/documentation only. It does not replace a backup of `/data`.

Before recovery or any destructive disk operation:

1. identify the actual WD disk;
2. verify `/data` and the root RAID layout;
3. preserve the clean-Jessie artifact and its recorded checksum;
4. execute each disk-writing operation only after verifying its source and target.
