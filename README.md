# WD My Cloud Family Server

Lightweight private family NAS/server for WD My Cloud Gen1 running Debian Jessie on ARMv7.

> **Privacy / portability:** This repository intentionally uses generic family-role labels only: **Ayah**, **Ibu**, **Anak1**, **Anak2**, and **Anak3**. These are aliases representing roles, not fixed personal names. Anyone deploying this project may use different names in their own private configuration. Do not add real family names or other personal identifiers to this public repository.

## Prerequisites — read before installation

This repository targets a specific legacy WD My Cloud Gen1 platform. Read this section before running any installation or recovery command.

### Hardware and platform

- WD My Cloud Gen1
- ARMv7l / armhf
- Debian 8.2 (Jessie)
- Linux kernel 3.2.68
- Approximately 226 MB RAM
- 512 MB swap on `/dev/sda3`
- Data disk `/dev/sda4` mounted at `/data`
- Approximately 2.7 TB data storage

### Required access

- Working SSH/root access to the My Cloud
- Known LAN IP address
- Mac/Windows client for Samba/Finder verification
- Android phone for Syncthing photo-backup verification
- LAN access to Syncthing GUI on TCP 8384
- Internet/DNS access only when configuring Cloudflare Tunnel/WebDAV remote access

### Critical safety prerequisites

- Verify `/dev/sda4` before any filesystem or partition operation.
- Do not format `/dev/sda4` during routine setup.
- Do not perform a Debian distribution upgrade.
- Jessie package sources must use the Debian archive, not a current `stable` repository.
- Do not expose SMB/TCP 445 or Syncthing GUI TCP 8384 directly to the public Internet.
- Back up existing configuration before replacement.
- Never put passwords, API keys, Cloudflare credentials, SSH keys, private certificates, photos, documents, or personal names in Git.
- Treat `dd`, `mkfs`, `wipefs`, partitioning, and RAID creation commands as destructive until the target has been verified.
- Prefer lightweight native/static binaries; avoid Docker/heavy services on this ~226 MB RAM device.

## Verified baseline

- Hardware: WD My Cloud Gen1
- Architecture: ARMv7l / armhf
- Debian: 8.2 (Jessie)
- Kernel: 3.2.68
- RAM: ~226 MB
- Swap: 512 MB on `/dev/sda3`
- Data disk: `/dev/sda4` mounted at `/data`
- Samba: 4.2.14-Debian
- Syncthing: **v2.1.3**, static ARM binary
- WebDAV: **v5.15.0**, static ARM binary
- WebDAV listener: `0.0.0.0:6065`
- Cloudflare Tunnel: `cloudflared-mycloud.service`

## Family storage layout

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

There is **no `/data/Private/` directory** in the final storage model.

## Permission model

| Area | Family access |
|---|---|
| `/data/<member>` private root | matching member only, read/write/delete |
| `Family/Documents` | read/write |
| `Family/Shared` | read/write |
| `Family/Videos` | read/write |
| `Family/Photos` | read-only for family users; writable by Syncthing |

Private roots use filesystem mode `700`. Family Photos is the protected backup area.

## Syncthing photo backup

The intended topology is strictly one-way:

```text
Android phone                         WD My Cloud
-------------                         ----------
Photo folder                          Family Photos folder
Send Only      ────────────────────>  Receive Only
                                      |
                                      +-- Samba/WebDAV: read-only
```

Each family role has a corresponding photo directory under `Family/Photos`. A deploying family can map the generic roles to whatever private directory names they use locally.

The phone is the source of truth for the photo folder. The MyCloud destination is the backup target.

See [`docs/syncthing.md`](docs/syncthing.md) for the complete Web-GUI procedure, folder types, permission requirements, verification and recovery.

## Samba

Samba is the primary LAN filesystem interface for Finder/Explorer. Family Photos is read-only through normal family file access.

The verified `[homes]` configuration maps an authenticated username directly to `/data/<user>`, so Finder presents the user's private root as the home share. Family folders are exposed inside that root through filesystem bind mounts.

Validate configuration with:

```bash
testparm
```

Do not expose TCP 445 to the Internet.

## WebDAV

WebDAV v5.15.0 runs through `webdav.service` on TCP 6065. Each authenticated account uses its own `/data/<user>` directory as the **direct WebDAV root**.

The user therefore sees the same logical structure as Samba:

```text
<member> WebDAV root
├── FamilyDocs
├── FamilyPhotos
├── FamilyShared
├── FamilyVideos
├── private files/folders
└── ...
```

There are no `private/` or `family/` virtual WebDAV directories in the final configuration. The shared Family folders are made visible inside each private root by filesystem bind mounts.

The global permission is `CRUD`, with Family Photos restricted to `R`:

```yaml
permissions: CRUD
rules:
  - regex: ^/FamilyPhotos(/.*)?$
    permissions: R
```

Production credentials are kept outside Git in `/etc/webdav/webdav.env`. The systemd service loads that file with:

```ini
EnvironmentFile=/etc/webdav/webdav.env
```

The YAML references environment variables rather than storing passwords directly:

```yaml
users:
  - username: <member>
    password: "{env}WD_<MEMBER>_PASSWORD"
    directory: /data/<member>
```

Remote access uses the Cloudflare Tunnel. SMB and Syncthing GUI remain LAN-only.

## Browser and Finder behavior

A standards-compliant WebDAV `PROPFIND` request may return `207 Multi-Status` XML. Raw XML in a browser is therefore normal WebDAV behavior.

The next WebDAV development goal is a human-friendly HTML directory/file listing for ordinary browser `GET` requests while preserving WebDAV semantics for Finder and other clients.

## Recovery and safety

This repository is configuration/documentation source-of-truth, not a backup of `/data`.

- Keep Debian Jessie stable; do not perform accidental distribution upgrades.
- Keep user data on `/data`.
- Preserve existing configuration before replacement.
- Treat disk-writing commands as destructive until the target has been verified.
- Do not expose SMB/TCP 445 or Syncthing GUI TCP 8384 publicly.
- Test service changes locally before testing through Cloudflare.
- Keep `/etc/webdav/webdav.env` and other credential files out of Git.

## Status

### Verified

- Debian Jessie boots on the WD Gen1 HDD.
- SSH access works.
- 512 MB swap is active.
- Samba 4.2.14 works from Mac/Finder.
- Private user isolation and Family share permissions are verified.
- `FamilyPhotos` is read-only through Samba while remaining writable by Syncthing.
- Final family storage model is deployed without `/data/Private/`.
- Syncthing v2.1.3 starts at boot.
- WebDAV v5.15.0 is enabled and running on TCP 6065.
- WebDAV uses direct per-user roots and no `private/` or `family/` virtual directories.
- WebDAV authentication works with passwords supplied through `EnvironmentFile`.
- WebDAV `FamilyPhotos` write attempts return `403 Forbidden`.
- WebDAV `FamilyShared` write test returned `201 Created` and the test file was removed.

### Next

- Finish verification of the current phone photo synchronization and confirm the MyCloud destination is Receive Only.
- Add and verify remaining family Syncthing devices.
- Re-test WebDAV/Finder/Cloudflare after future service changes.
- Build and test a custom WebDAV binary with HTML directory listing for browser `GET` requests.
- Select and verify a lightweight DLNA implementation suitable for Jessie and the 256 MB-class device.

## Repository documents

- `AGENTS.md` — repository safety and operating rules.
- `docs/setup.md` — base platform and service setup.
- `docs/architecture.md` — system architecture and permission boundaries.
- `docs/syncthing.md` — phone Send Only and MyCloud Receive Only procedure.
- `docs/deployment/syncthing-verified.md` — verified Syncthing runtime notes.
- `docs/deployment/webdav-cloudflare-verified.md` — verified WebDAV/Cloudflare deployment.
- `docs/recovery/` — destructive recovery procedures; read completely before disk-writing steps.

## Source of truth

After every verified workflow on the physical My Cloud:

1. update the relevant repository documentation/configuration;
2. commit it to `main`;
3. only then start the next workflow.

The repository is configuration/documentation source-of-truth, not a backup of `/data`.
