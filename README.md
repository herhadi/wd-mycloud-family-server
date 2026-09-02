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
- Browser Gateway: **webdav-gw**, static ARMv7 binary
- Browser Gateway listener: `127.0.0.1:6066`
- Browser Gateway service: `webdav-gw.service`, enabled and running
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

Remote access uses the Browser Gateway behind the Cloudflare Tunnel. SMB and Syncthing GUI remain LAN-only.

## Browser Gateway

The custom `webdav-gw` service provides a human-friendly HTML directory listing for ordinary browser `GET` requests while preserving WebDAV behavior for other clients and methods.

```text
Browser / WebDAV client
          |
          v
Browser Gateway :6066
          |
          v
WebDAV :6065
          |
          v
/data/<member>
```

The gateway is a lightweight static ARMv7 binary installed at `/usr/local/bin/webdav-gw` and managed by `webdav-gw.service`. It listens only on `127.0.0.1:6066`.

For browser `GET` requests to directories, the gateway authenticates through WebDAV, performs an authenticated `PROPFIND`, parses the XML response, and renders an HTML listing. Non-GET WebDAV methods and file requests are passed through to the WebDAV service.

The UI hides common macOS/Syncthing internal files and displays basic file-type icons, directory-first sorting, breadcrumbs, Home/Back controls, and file sizes. This filtering affects only the browser presentation; it does not delete or modify files.

The gateway has been verified on both x86_64 Ubuntu and the ARMv7 My Cloud. The ARMv7 binary starts successfully as a systemd service and returns the expected HTML page after WebDAV authentication.

Cloudflare routes the public hostname to the gateway. Do not expose TCP 6066 directly to the Internet.

## Browser and Finder behavior

A standards-compliant WebDAV `PROPFIND` request may return `207 Multi-Status` XML. Raw XML in a browser is therefore normal when accessing WebDAV directly.

Through the Browser Gateway, an ordinary browser `GET` of a directory receives a human-friendly HTML listing. Finder and other WebDAV clients continue to use the underlying WebDAV protocol.

## Release checkpoints

Stable/verified deployment checkpoints are maintained as GitHub release/tag checkpoints. The release notes record the physical-device verification state and known issues at each checkpoint.

Current checkpoint:

- **v1.1.0** — Browser Gateway enabled, ARMv7 service verified, Cloudflare routed to gateway, with WebDAV `PROPFIND` filtering for Windows remaining as a known issue.

See [`docs/releases/v1.1.0.md`](docs/releases/v1.1.0.md).

## Recovery and safety

This repository is configuration/documentation source-of-truth, not a backup of `/data`.

- Keep Debian Jessie stable; do not perform accidental distribution upgrades.
- Keep user data on `/data`.
- Preserve existing configuration before replacement.
- Treat disk-writing commands as destructive until the target has been verified.
- Do not expose SMB/TCP 445 or Syncthing GUI TCP 8384 publicly.
- Keep the Browser Gateway bound to `127.0.0.1`; do not expose TCP 6066 directly.
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
- Browser Gateway binary runs natively on ARMv7.
- `webdav-gw.service` is enabled and running.
- Browser Gateway authentication and HTML directory rendering are verified locally on TCP 6066.
- Cloudflare ingress configuration validates successfully with the WD-specific command syntax.

### Next

- Finish verification of the current phone photo synchronization and confirm the MyCloud destination is Receive Only.
- Add and verify remaining family Syncthing devices.
- Re-test WebDAV/Finder/Cloudflare after future service changes.
- Filter internal files from WebDAV `PROPFIND` responses so Windows WebDAV does not display Syncthing/macOS internal entries.
- Select and verify a lightweight DLNA implementation suitable for Jessie and the 256 MB-class device.

## Repository documents

- `AGENTS.md` — repository safety and operating rules.
- `docs/setup.md` — base platform and service setup.
- `docs/architecture.md` — system architecture and permission boundaries.
- `docs/syncthing.md` — phone Send Only and MyCloud Receive Only procedure.
- `docs/deployment/syncthing-verified.md` — verified Syncthing runtime notes.
- `docs/deployment/webdav-cloudflare-verified.md` — verified WebDAV/Cloudflare deployment.
- `docs/browser-gateway.md` — Browser Gateway design, deployment and verification.
- `docs/releases/v1.1.0.md` — v1.1.0 release checkpoint and known issue.
- `docs/recovery/` — destructive recovery procedures; read completely before disk-writing steps.

## Source of truth

After every verified workflow on the physical My Cloud:

1. update the relevant repository documentation/configuration;
2. commit it to `main`;
3. create/update the corresponding release checkpoint when the state is stable;
4. only then start the next workflow.
