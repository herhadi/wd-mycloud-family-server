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

## Family storage layout

The canonical family storage model is:

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

The family storage is separated into private user roots and purpose-specific shared Family areas.

### Private user roots

| Path | Member | Other family users |
|---|---|---|
| `/data/Ayah` | Ayah | no access |
| `/data/Ibu` | Ibu | no access |
| `/data/Anak1` | Anak1 | no access |
| `/data/Anak2` | Anak2 | no access |
| `/data/Anak3` | Anak3 | no access |

Private roots use filesystem permission mode `700`. Files and directories created inside a member's root are created under that member's account and ownership.

### Family shares

| Share | Path | Family access |
|---|---|---|
| `FamilyDocs` | `/data/Family/Documents` | read/write |
| `FamilyShared` | `/data/Family/Shared` | read/write |
| `FamilyVideos` | `/data/Family/Videos` | read/write |
| `FamilyPhotos` | `/data/Family/Photos` | **read-only** |

`/data/Family/Photos` is a special backup area:

- family users through Samba/WebDAV: **read-only**;
- Syncthing: **write** for photo backup;
- Android photo folders: **Send Only** into the corresponding member folder.

## Samba checkpoint

**Checkpoint: Samba private/family shares — verified 2026-09-01.**

Verified from macOS/Finder after reloading Samba:

- private shares for individual users are visible;
- a family account cannot open another user's private share;
- `FamilyDocs` is read/write;
- `FamilyPhotos` is read-only;
- the Samba service remains active after configuration reload;
- the final share names are `FamilyDocs`, `FamilyShared`, `FamilyVideos`, and `FamilyPhotos`.

The live server configuration is validated with `testparm` before activation. Credentials are never stored in the repository.

## WebDAV

**Checkpoint: WebDAV final mapping — verified 2026-09-01.**

WebDAV v5.15.0 is running as `webdav.service` on TCP 6065 using `/etc/webdav/config.yml`. The final configuration maps each authenticated member directly to the `/data` storage model without `/opt/webdav` bind mounts.

Each account sees two logical WebDAV roots:

```text
<member>
├── private  → /data/<member>
└── family   → /data/Family
```

The five member mappings are:

```text
Ayah   → /data/Ayah
Ibu    → /data/Ibu
Anak1  → /data/Anak1
Anak2  → /data/Anak2
Anak3  → /data/Anak3
```

The `private` WebDAV path is only a logical label. It does not require or imply a physical `/data/Private/` directory.

### WebDAV permission rules

The global WebDAV permission is `CRUD`, with one path-specific exception:

```yaml
permissions: CRUD

rules:
  - regex: ^/family/Photos(/.*)?$
    permissions: R
```

Therefore:

- `/private/` → CRUD for the matching member only;
- `/family/Documents/` → CRUD;
- `/family/Shared/` → CRUD;
- `/family/Videos/` → CRUD;
- `/family/Photos/` → read-only.

### Verified WebDAV tests

The final configuration was tested first on port `6066`, then through the production `webdav.service` on port `6065`.

Verified:

- `Family/Photos` upload returns `403 Forbidden`;
- `Family/Documents` upload returns `201 Created`;
- all five private roots accept uploads for their matching account;
- cross-user private access returns `404 Not Found`;
- WebDAV `DELETE` on a writable Family document succeeds with `204 No Content`;
- `webdav.service` is `active (running)` and `enabled`;
- port `6065` is listening after reboot.

### Legacy WebDAV cleanup

The original implementation used bind mounts under `/opt/webdav` and a legacy `/data/Private` structure. Those mounts have been removed.

Verified:

- ten legacy bind mounts under `/opt/webdav` were unmounted;
- all `/opt/webdav` entries were removed from `/etc/fstab`;
- `/data/Private` was removed;
- `/opt/webdav` was removed;
- the final `/data` layout remains the source of truth.

## Syncthing

Syncthing v2.1.3 backs up phone photos into the corresponding member directory under:

```text
/data/Family/Photos/
├── Ayah/
├── Ibu/
├── Anak1/
├── Anak2/
└── Anak3/
```

The photo source on each Android phone is configured as **Send Only**. WebDAV/Samba family users cannot delete files from the Family Photos area.

## Cloudflare Tunnel

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

The production system uses `cloudflared-mycloud.service`. SMB/TCP 445 is not exposed directly to the Internet.

## Browser and Finder behavior

The WebDAV endpoint keeps standard WebDAV `PROPFIND` behavior and returns `207 Multi-Status` XML. A browser may therefore display raw XML for a directory request; this is normal WebDAV behavior.

The next development goal is a custom WebDAV binary that adds an HTML directory/file listing for ordinary browser `GET` requests while preserving standards-compatible WebDAV behavior for Finder and other WebDAV clients.

## Recovery and safety

The repository documents recovery of the Gen1 platform. The repository is configuration/documentation source-of-truth and is not a backup of `/data`.

- Keep Debian Jessie stable; do not perform accidental distribution upgrades.
- Avoid Docker and heavyweight applications on the 256 MB-class device.
- Keep user data on `/data`.
- Never store passwords, Cloudflare credentials, SSH keys, private certificates, photos, or documents in this repository.
- Preserve existing configuration before replacement.
- Treat `dd`, `mkfs`, `mdadm --create`, and partitioning as destructive until the target device has been verified.
- Do not expose SMB/TCP 445 or the Syncthing GUI directly to the public Internet.
- Test service changes locally before testing through Cloudflare.

## Status

### Verified

- Debian Jessie boots on the WD Gen1 HDD.
- SSH access works.
- 512 MB swap is active.
- Samba 4.2.14 works from Mac/Finder.
- Private user share isolation and Family share permissions are verified from Mac/Finder.
- `FamilyPhotos` is read-only through Samba while remaining writable by Syncthing.
- Final family storage model is deployed without `/data/Private/`.
- Syncthing v2.1.3 starts at boot and backs up phone photos into the family photo area.
- Legacy WebDAV bind mounts and `/data/Private` development structure have been removed.
- WebDAV v5.15.0 multi-directory mapping and path-specific read-only rules are verified.
- Production `webdav.service` is enabled and running on TCP 6065.
- WebDAV private isolation and Family CRUD/read-only behavior are verified.

### Next

- Re-test WebDAV/Finder/Cloudflare after future service changes.
- Build and test a custom WebDAV v5.15.0-based binary with HTML directory listing for browser `GET` requests.
- Remove Gossa only after the custom WebDAV browser UI is verified.
- Select and verify a lightweight DLNA implementation suitable for Jessie and the 256 MB-class device.
- Add and verify remaining family Syncthing devices.

## Source of truth

After every verified workflow on the physical My Cloud:

1. update the relevant repository documentation/configuration;
2. commit it to `main`;
3. only then start the next workflow.

The repository is configuration/documentation source-of-truth, not a backup of `/data`.
