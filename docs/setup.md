# Setup Notes

This document records the setup sequence verified for the WD My Cloud Gen1.

## Base system

The device runs Debian Jessie 8.2 on ARMv7l with kernel 3.2.68. The data partition is mounted at `/data`.

## Storage layout

The final family storage model is:

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

There is no `/data/Private/` directory. The five directories directly under `/data` are private roots for the corresponding family members.

## Permission model

The private roots are isolated:

- the owner has full read/write/delete access;
- other family users have no access;
- files and directories created inside a user's root must inherit that user's ownership/permissions.

`/data/Family` is shared, with permissions determined by each subdirectory's purpose.

`/data/Family/Documents`, `/data/Family/Shared`, and `/data/Family/Videos` are read/write for family users. `/data/Family/Photos` is read-only for family users while the `syncthing` service account can write new synchronized photos. Android photo folders are configured as Send Only into the corresponding member folder.

## Swap

`/dev/sda3` is a 512 MB swap partition. It was recreated with a 4096-byte page size and added to `/etc/fstab` by UUID.

## Samba

Samba 4.2.14-Debian is installed and running. SMB is the primary local file interface for Finder/Explorer.

Do not expose SMB/TCP 445 directly to the Internet.

## Syncthing

Syncthing v2.1.3 is installed from a static Linux ARM binary because the Jessie repository does not provide a suitable package. It runs as the dedicated `syncthing` user with state under `/var/lib/syncthing`.

Phone photo datasets are synchronized to the corresponding member folders:

```text
/data/Family/Photos/Ayah
/data/Family/Photos/Ibu
/data/Family/Photos/Anak1
/data/Family/Photos/Anak2
/data/Family/Photos/Anak3
```

The phone-side photo folder is configured as Send Only.

## WebDAV

WebDAV v5.15.0 is installed as `/usr/local/bin/webdav` and listens on TCP 6065 through `webdav.service`.

Each WebDAV account is logically presented with its own private root plus the shared `Family` tree:

```text
<member>
├── private  → /data/<member>
└── family   → /data/Family
```

The member mappings are:

```text
Ayah   → /data/Ayah
Ibu    → /data/Ibu
Anak1  → /data/Anak1
Anak2  → /data/Anak2
Anak3  → /data/Anak3
```

`private` is only a logical WebDAV label; there is no physical `/data/Private/` directory and no `/opt/webdav` bind-mount layer.

The global WebDAV permission is `CRUD`, except `/family/Photos` which is `R` through a path-specific rule.

The public hostname is `drive.tripleatech.my.id`, published through the Cloudflare Tunnel service `cloudflared-mycloud.service`.

## Remote access

SMB must not be exposed directly on TCP/445 to the Internet. Remote file access uses the WebDAV service through the Cloudflare Tunnel.

Cloudflare Access must not be placed in front of the WebDAV hostname if it causes redirects that break standard WebDAV methods such as `PROPFIND`.

## Apt safety

Do not use `stable` as a permanent Jessie source. Jessie sources should use the Debian archive and be treated as legacy infrastructure.

Do not perform general distribution upgrades on this device.

## Documentation rule

The canonical family member labels for this project are **Ayah**, **Ibu**, **Anak1**, **Anak2**, and **Anak3**. Use these names consistently in repository documentation, diagrams, storage paths, examples, and configuration templates. Do not use the previous member names `Abi`, `Umi`, `Adzra`, `Adel`, or `Afzal` in current documentation.
