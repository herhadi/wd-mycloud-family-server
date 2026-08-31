# WD My Cloud Family Server

Lightweight family NAS/server setup for WD My Cloud Gen1 running Debian Jessie on ARMv7.

## Current baseline

- Hardware: WD My Cloud Gen1
- Architecture: ARMv7l / armhf
- Debian: 8.2 (Jessie)
- Kernel: 3.2.68
- RAM: ~226 MB
- Swap: 512 MB on `/dev/sda3`
- Data disk: `/dev/sda4` mounted at `/data`
- Storage: ~2.7 TB
- Samba: 4.2.14-Debian
- Syncthing: **v2.1.3**, static ARM binary
- Network: DHCP on `eth0`

## What is implemented

- SMB access from Finder/Windows Explorer.
- Syncthing-Fork phone photo backup.
- Private per-user Samba shares.
- Shared `Shared` and `Media` areas.
- Non-destructive platform/service health checks.
- Recovery and clean-Jessie documentation for the Gen1 boot layout.
- Safe cloudflared download/recovery notes for old Jessie `wget`.

## Family share layout

```text
/data/
├── Media/                 # family media; group-accessible
├── Shared/                # family documents/files; group-accessible
├── Photos/
│   └── HP-Ayah/           # existing Syncthing photo dataset
└── Private/
    ├── <user-a>/          # 0700, user-owned
    ├── <user-b>/
    └── ...
```

The installer creates the `Private/<user>` directories plus the `Shared` and `Media` directories and generates a complete Samba configuration with:

- `Private-<user>`: only the matching SMB user can access it.
- `Shared`: members of the `family` Unix group can read/write.
- `Media`: members of the `family` Unix group can read/write.

## Installation on the WD

After confirming `/data` is mounted and Samba is already installed:

```bash
chmod +x /path/to/install-samba-family.sh
/path/to/install-samba-family.sh --user ayah --user ibu --user anak
```

Set SMB passwords separately:

```bash
smbpasswd ayah
smbpasswd ibu
smbpasswd anak
```

Run the non-destructive health check afterwards:

```bash
chmod +x /path/to/health-check.sh
/path/to/health-check.sh
```

The Samba installer backs up the current `/etc/samba/smb.conf`, validates the generated configuration with `testparm`, and only then restarts Samba. It never formats disks or edits `/etc/fstab`.

## Current Syncthing deployment

The verified WD deployment runs Syncthing v2.1.3 from `/usr/local/bin/syncthing` as user `syncthing`, with state in `/var/lib/syncthing`. The previously used extracted directory name `syncthing-linux-arm-v1.19.2` was misleading; the binary itself reports v2.1.3.

The current verified phone folder is:

```text
/data/Photos/HP-Ayah
```

See `docs/deployment/syncthing-verified.md` for the recorded verification.

## Remote access

SMB/TCP 445 must not be exposed directly to the public Internet. Remote access should be provided through a secure tunnel or VPN. The repository includes troubleshooting notes for the legacy Jessie `wget` behavior encountered when downloading cloudflared.

## Recovery

The repository documents both:

1. Recovery of an existing Gen1 disk without intentionally formatting `/data`.
2. A clean Debian Jessie restore using the known Gen1 GPT/RAID/kernel/config layout.

The large clean-Jessie recovery archive is deliberately not committed to Git. Its recorded SHA256 and contents are documented under `installer/jessie/`.

## Design principles

- Keep Debian Jessie stable; do not perform accidental distribution upgrades.
- Avoid Docker and heavyweight web applications on this 256 MB-class device.
- Keep user data on `/data`.
- Never store passwords, SSH keys, device IDs, private certificates, photos, or documents in this repository.
- Prefer small, reversible, documented changes.
- Treat recovery commands such as `dd`, `mkfs`, `mdadm --create`, and partitioning as destructive until the target device has been verified.

## Repository layout

```text
.
├── AGENTS.md
├── README.md
├── .gitignore
├── config/
│   ├── samba/smb.conf.working
│   └── syncthing/syncthing.init
├── docs/
│   ├── architecture.md
│   ├── hardware.md
│   ├── setup.md
│   ├── deployment/
│   ├── recovery/
│   └── troubleshooting/
├── installer/
│   └── jessie/
└── scripts/
    ├── health-check.sh
    ├── install-samba-family.sh
    └── prepare.sh
```

## Status

### Verified

- Debian Jessie boots on the WD Gen1 HDD.
- SSH access works.
- 512 MB swap is active.
- Samba 4.2.14 is working from Mac/Finder.
- Syncthing v2.1.3 is installed and starts at boot.
- One Android phone has successfully synchronized photos to the NAS.

### Remaining integration work

- Decide and document the final DLNA implementation suitable for Jessie/256 MB RAM.
- Deploy and verify secure remote access (tunnel/VPN) without exposing SMB.
- Add additional family Syncthing devices and map their destinations.

## Warning

This repository contains configuration, scripts, and recovery documentation only. It is **not** a backup of the NAS data disk.

Before running any script against the WD, verify the target device, mounted filesystems, and current configuration.