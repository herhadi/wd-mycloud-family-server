# WD My Cloud Family Server

Lightweight private family NAS/server for WD My Cloud Gen1 running Debian Jessie on ARMv7.

## Verified baseline

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
- WebDAV: **v5.15.0**, static ARM binary
- WebDAV listener: `0.0.0.0:6065`
- Public WebDAV hostname: `drive.tripleatech.my.id`
- Cloudflare Tunnel: `cloudflared-mycloud.service`

## Verified services

### Samba

Samba provides local SMB access from macOS Finder and Windows Explorer.

Family storage layout:

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
└── Private/
    ├── Ayah/
    ├── Ibu/
    ├── Anak1/
    ├── Anak2/
    └── Anak3/
```

### Syncthing

Verified deployment:

```text
Binary : /usr/local/bin/syncthing
User   : syncthing
State  : /var/lib/syncthing
Folder : Poco F7
Path   : /data/Family/Photos/Ayah
```

The binary was independently verified as Syncthing v2.1.3; an older extracted directory name containing `v1.19.2` was misleading.

### WebDAV

Verified deployment:

```text
Binary : /usr/local/bin/webdav
Version: 5.15.0
Config : /etc/webdav/config.yml
Port   : 6065
Service: webdav.service
```

WebDAV users are exposed through isolated virtual roots containing only:

```text
Private
Family
```

Current login-to-directory mapping:

```text
ayah  -> /opt/webdav/ayah
ibu   -> /opt/webdav/ibu
anak1 -> /opt/webdav/anak1
anak2 -> /opt/webdav/anak2
anak3 -> /opt/webdav/anak3
```

The virtual roots are backed by bind mounts from `/data/Private/<name>` and `/data/Family`, recorded in `/etc/fstab`.

### Cloudflare Tunnel

Remote WebDAV is published through:

```text
drive.tripleatech.my.id
        |
        v
Cloudflare Tunnel
        |
        v
127.0.0.1:6065
        |
        v
WebDAV
```

The production system uses the systemd service:

```text
cloudflared-mycloud.service
```

The older `/etc/init.d/cloudflared` implementation is retained only as historical/backup material and must not be treated as the active service.

SMB/TCP 445 is not exposed directly to the Internet.

## Browser and Finder behavior

The WebDAV endpoint must keep standard WebDAV `PROPFIND` behavior and return `207 Multi-Status` XML. A browser may therefore display raw XML for a directory request; this is normal WebDAV behavior.

The next development goal is a custom WebDAV binary that adds an HTML directory/file listing for ordinary browser `GET` requests while preserving standards-compatible WebDAV behavior for Finder and other WebDAV clients.

## Recovery

The repository documents both:

1. Recovery of an existing Gen1 disk without intentionally formatting `/data`.
2. Clean Debian Jessie restore using the known Gen1 GPT/RAID/kernel/config layout.

The large clean-Jessie recovery archive is deliberately not committed to Git. Its recorded SHA256 and contents are documented under `installer/jessie/`.

## Safety principles

- Keep Debian Jessie stable; do not perform accidental distribution upgrades.
- Avoid Docker and heavyweight web applications on the 256 MB-class device.
- Keep user data on `/data`.
- Never store passwords, Cloudflare credentials, SSH keys, private certificates, device IDs, photos, or documents in this repository.
- Preserve existing configuration before replacement.
- Treat `dd`, `mkfs`, `mdadm --create`, and partitioning as destructive until the target device has been verified.
- Do not expose SMB/TCP 445 or the Syncthing GUI directly to the public Internet.
- Test service changes locally before testing through Cloudflare.

## Repository layout

```text
.
├── AGENTS.md
├── README.md
├── .gitignore
├── config/
│   ├── samba/
│   └── syncthing/
├── docs/
│   ├── architecture.md
│   ├── deployment/
│   ├── hardware.md
│   ├── recovery/
│   ├── setup.md
│   └── troubleshooting/
├── installer/
│   └── jessie/
└── scripts/
    ├── health-check.sh
    ├── install-samba-family.sh
    ├── prepare.sh
    └── shellcheck.sh
```

## Status

### Verified

- Debian Jessie boots on the WD Gen1 HDD.
- SSH access works.
- 512 MB swap is active.
- Samba 4.2.14 works from Mac/Finder.
- Family/private storage layout is deployed.
- Syncthing v2.1.3 starts at boot and backs up the Poco F7 photo dataset to `/data/Family/Photos/Ayah`.
- WebDAV v5.15.0 is active on port 6065.
- Five WebDAV virtual roots are deployed with 10 bind mounts total.
- Cloudflare Tunnel is active through `cloudflared-mycloud.service`.
- `drive.tripleatech.my.id` returns `207 Multi-Status` for authenticated WebDAV `PROPFIND` requests.
- Finder/macOS access through the public WebDAV hostname has been verified.

### Next

- Build and test a custom WebDAV v5.15.0-based binary with HTML directory listing for browser `GET` requests.
- Re-test WebDAV/Finder/Cloudflare after replacing the binary.
- Remove Gossa only after the custom WebDAV browser UI is verified.
- Select and verify a lightweight DLNA implementation suitable for Jessie and the 256 MB-class device.
- Add and verify remaining family Syncthing devices.

## Source of truth

After every verified workflow on the physical My Cloud:

1. update the relevant repository documentation/configuration;
2. commit it to `main`;
3. only then start the next workflow.

The repository is configuration/documentation source-of-truth, not a backup of `/data`.