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

Repository documentation uses **generic family role labels only**. Real family names, usernames, and device-specific identities are configured on the live server and must not be recorded in this repository.

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

| Path | Owner | Other family users |
|---|---|---|
| `/data/Ayah` | matching member account | no access |
| `/data/Ibu` | matching member account | no access |
| `/data/Anak1` | matching member account | no access |
| `/data/Anak2` | matching member account | no access |
| `/data/Anak3` | matching member account | no access |

Private roots use filesystem permission mode `700`. Files and directories created inside a member's root are created under that member's account and ownership.

### Family shares

Samba exposes the Family areas as separate shares so that `Photos` can remain read-only while the other shared areas remain writable:

| Share | Path | Family access |
|---|---|---|
| `FamilyDocs` | `/data/Family/Documents` | read/write |
| `FamilyShared` | `/data/Family/Shared` | read/write |
| `FamilyVideos` | `/data/Family/Videos` | read/write |
| `FamilyPhotos` | `/data/Family/Photos` | **read-only** |

`/data/Family/Photos` is a special backup area:

- family users through Samba: **read-only**;
- Syncthing: **write** for photo backup;
- Android photo folders: **Send Only** on the phone.

The `FamilyPhotos` read-only policy has been verified from macOS/Finder: files can be read/copied but deletion is rejected. `FamilyDocs` read/write access has also been verified by creating and deleting a test file.

Other Family subdirectories may have purpose-specific permissions. Do not assume every Family subdirectory has the same policy.

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

## Syncthing

Verified deployment:

```text
Binary : /usr/local/bin/syncthing
User   : syncthing
State  : /var/lib/syncthing
Folder : <phone-folder-label>
Path   : /data/Family/Photos/<member-role>
```

The binary was independently verified as Syncthing v2.1.3.

## WebDAV

Verified deployment:

```text
Binary : /usr/local/bin/webdav
Version: 5.15.0
Config : /etc/webdav/config.yml
Port   : 6065
Service: webdav.service
```

Each WebDAV login gets a virtual root containing only the generic `Private` and `Family` labels in the WebDAV view. These are virtual labels; the underlying filesystem does not have `/data/Private/`.

The live server maps each login to its corresponding `/data/<member-role>` root. Real login names and mappings are intentionally excluded from this repository.

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

The WebDAV endpoint must keep standard WebDAV `PROPFIND` behavior and return `207 Multi-Status` XML. A browser may therefore display raw XML for a directory request; this is normal WebDAV behavior.

The next development goal is a custom WebDAV binary that adds an HTML directory/file listing for ordinary browser `GET` requests while preserving standards-compatible WebDAV behavior for Finder and other WebDAV clients.

## Recovery and safety

The repository documents recovery of the Gen1 platform and clean Debian Jessie restoration. Device-specific identities and credentials are intentionally excluded.

- Keep Debian Jessie stable; do not perform accidental distribution upgrades.
- Avoid Docker and heavyweight applications on the 256 MB-class device.
- Keep user data on `/data`.
- Never store passwords, Cloudflare credentials, SSH keys, private certificates, device IDs, real family names, photos, or documents in this repository.
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
- WebDAV v5.15.0 is active on port 6065.
- Five WebDAV virtual roots are deployed.
- Cloudflare Tunnel is active through `cloudflared-mycloud.service`.
- Authenticated WebDAV `PROPFIND` returns `207 Multi-Status`.
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
