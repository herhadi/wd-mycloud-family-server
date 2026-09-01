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

The real deployed family names are used throughout this repository. Do not replace them with generic labels such as `Ayah`, `Ibu`, `Anak1`, `Anak2`, or `Anak3`.

```text
/data/
├── Family/
│   ├── Documents/
│   ├── Photos/
│   │   ├── Abi/
│   │   ├── Umi/
│   │   ├── Adel/
│   │   ├── Adzra/
│   │   └── Afzal/
│   ├── Shared/
│   └── Videos/
├── Abi/
├── Umi/
├── Adel/
├── Adzra/
└── Afzal/
```

There is **no `/data/Private/` directory** in the final storage model.

## Permission model

`Family` is the shared family area. User roots outside `Family` are private:

| Path | Owner | Other family users |
|---|---|---|
| `/data/Abi` | Abi: full access | no access |
| `/data/Umi` | Umi: full access | no access |
| `/data/Adel` | Adel: full access | no access |
| `/data/Adzra` | Adzra: full access | no access |
| `/data/Afzal` | Afzal: full access | no access |

Files and directories newly created inside a user's root must inherit that user's ownership/permissions.

`/data/Family/Photos` is a special shared area:

- family users: **read-only**;
- Syncthing: **write** for photo backup;
- Android photo folders are configured as **Send Only** on the phone.

Other `Family` subdirectories may have their own purpose-specific permissions. For example, `Family/Shared` may be read/write for family users. Do not assume every `Family` subdirectory has the same permission policy.

## Syncthing

Verified deployment:

```text
Binary : /usr/local/bin/syncthing
User   : syncthing
State  : /var/lib/syncthing
Folder : Poco F7
Path   : /data/Family/Photos/Abi
```

The binary was independently verified as Syncthing v2.1.3; an older extracted directory name containing `v1.19.2` was misleading.

## WebDAV

Verified deployment:

```text
Binary : /usr/local/bin/webdav
Version: 5.15.0
Config : /etc/webdav/config.yml
Port   : 6065
Service: webdav.service
```

Each WebDAV login gets a virtual root containing only `Private` and `Family` in the WebDAV view. These are virtual labels: the underlying filesystem no longer has `/data/Private`.

Current mapping:

```text
abi   -> /data/Abi
umi   -> /data/Umi
adel  -> /data/Adel
adzra  -> /data/Adzra
afzal  -> /data/Afzal
```

The implementation may expose these through `/opt/webdav/<login>` bind mounts on the device. The exact production mount/configuration must remain documented separately from this logical storage model.

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

The repository documents recovery of the Gen1 platform and clean Debian Jessie restoration. Recovery artifacts are not committed.

- Keep Debian Jessie stable; do not perform accidental distribution upgrades.
- Avoid Docker and heavyweight applications on the 256 MB-class device.
- Keep user data on `/data`.
- Never store passwords, Cloudflare credentials, SSH keys, private certificates, device IDs, photos, or documents in this repository.
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
- Final family/private storage model is deployed without `/data/Private/`.
- Syncthing v2.1.3 starts at boot and backs up the Poco F7 photo dataset to `/data/Family/Photos/Abi`.
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