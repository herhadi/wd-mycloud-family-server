# WD My Cloud Family Server

Lightweight family NAS/server setup for WD My Cloud Gen1 running Debian Jessie on ARMv7.

## Current baseline

- Hardware: WD My Cloud Gen1
- Architecture: ARMv7l / armhf
- Debian: 8.2 (Jessie)
- Kernel: 3.2.68
- RAM: ~226 MB available to userspace
- Swap: 512 MB on `/dev/sda3`
- Data disk: `/dev/sda4` mounted at `/data`
- Storage: ~2.7 TB
- Samba: 4.2.14-Debian
- Syncthing: 1.19.2 (static ARM binary)
- Network: DHCP on `eth0`

## Goals

This project documents a lightweight private family cloud built around the original WD My Cloud Gen1 hardware:

1. SMB access from Finder/Windows Explorer.
2. Automatic phone photo backup with Syncthing-Fork.
3. Private folders per family member.
4. Shared folders for common files and media.
5. DLNA/UPnP media access for Smart TV.
6. Secure remote access through a domain and tunnel/VPN without exposing SMB directly to the Internet.

## Design principles

- Keep Debian Jessie stable; do not perform accidental distribution upgrades.
- Avoid Docker and heavyweight web applications on the 256 MB-class device.
- Keep user data on `/data`.
- Never store passwords, SSH keys, device IDs, private certificates, photos, or documents in this repository.
- Prefer reversible, documented changes.
- Keep recovery instructions for the WD Gen1 boot layout.

## Repository layout

```text
.
├── AGENTS.md
├── README.md
├── .gitignore
├── docs/
│   ├── architecture.md
│   ├── hardware.md
│   └── setup.md
└── scripts/
    └── prepare.sh
```

## Status

### Working

- Debian Jessie booting from the WD Gen1 HDD.
- SSH access.
- 512 MB swap enabled.
- Samba share working from Mac.
- Syncthing 1.19.2 running.
- One Android phone successfully backing up photos to the NAS.

### Planned

- Per-user/private Samba shares.
- Family/shared media shares.
- DLNA server.
- Secure remote access using `tripleatech.my.id`.
- Additional family phones.

## Warning

This repository contains configuration and scripts only. It is **not** a backup of the NAS data disk.

Before running any script against the WD, verify the target device and read the script comments.