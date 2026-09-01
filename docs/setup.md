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

There is no `/data/Private/` directory. The five directories directly under `/data` are private roots for the corresponding family members.

## Permission model

The private roots are isolated:

- the owner has full read/write/delete access;
- other family users have no access;
- files and directories created inside a user's root must inherit that user's ownership/permissions.

`/data/Family` is shared, with permissions determined by each subdirectory's purpose.

`/data/Family/Photos` is the exception used for phone backup: family users access it read-only, while the `syncthing` service account can write new synchronized photos. Android photo folders are configured as Send Only.

## Swap

`/dev/sda3` is a 512 MB swap partition. It was recreated with a 4096-byte page size and added to `/etc/fstab` by UUID.

## Samba

Samba 4.2.14-Debian is installed and running. SMB is the primary local file interface for Finder/Explorer.

Do not expose SMB/TCP 445 directly to the Internet.

## Syncthing

Syncthing v2.1.3 is installed from a static Linux ARM binary because the Jessie repository does not provide a suitable package. It runs as the dedicated `syncthing` user with state under `/var/lib/syncthing`.

The verified Poco F7 photo dataset is synchronized to:

```text
/data/Family/Photos/Abi
```

The phone-side photo folder is configured as Send Only.

## WebDAV

WebDAV v5.15.0 is installed as `/usr/local/bin/webdav` and listens on TCP 6065 through `webdav.service`.

Each WebDAV account is logically presented with its own private root plus the shared `Family` tree. `Private` can be a virtual WebDAV label only; there is no physical `/data/Private/` directory.

The public hostname is `drive.tripleatech.my.id`, published through the Cloudflare Tunnel service `cloudflared-mycloud.service`.

## Remote access

SMB must not be exposed directly on TCP/445 to the Internet. Remote file access uses the WebDAV service through the Cloudflare Tunnel.

Cloudflare Access must not be placed in front of the WebDAV hostname if it causes redirects that break standard WebDAV methods such as `PROPFIND`.

## Apt safety

Do not use `stable` as a permanent Jessie source. Jessie sources should use the Debian archive and be treated as legacy infrastructure.

Do not perform general distribution upgrades on this device.

## Documentation rule

The names `Abi`, `Umi`, `Adel`, `Adzra`, and `Afzal` are the canonical names for this project. Do not substitute generic names such as `Ayah`, `Ibu`, `Anak1`, `Anak2`, or `Anak3` in repository documentation.