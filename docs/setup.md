# Setup Notes

This document records the setup sequence verified on the WD My Cloud Gen1.

## Base system

The device is running Debian Jessie 8.2 on ARMv7l with kernel 3.2.68. The data partition is mounted at `/data`.

## Swap

`/dev/sda3` is a 512 MB swap partition. It was recreated with a 4096-byte page size and added to `/etc/fstab` by UUID.

## Family storage

The final family layout is:

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

Private directories are user-specific. The `Family` tree is shared according to the configured service permissions.

## Samba

Samba 4.2.14-Debian is installed and working from macOS Finder/Windows Explorer. The final Samba configuration provides family/private access according to the deployed account and directory mapping.

## Syncthing

Syncthing v2.1.3 is installed as a static ARM binary at `/usr/local/bin/syncthing`. It runs as the dedicated `syncthing` user with state under `/var/lib/syncthing`.

The verified Poco F7 photo folder is:

```text
/data/Family/Photos/Ayah
```

An Android phone using Syncthing-Fork has successfully synchronized photos to the NAS.

## WebDAV

WebDAV v5.15.0 is installed at `/usr/local/bin/webdav` and listens on `0.0.0.0:6065`.

Each family account has an isolated WebDAV virtual root containing only `Private` and `Family`:

```text
Ayah  -> /opt/webdav/ayah
Ibu   -> /opt/webdav/ibu
Anak1 -> /opt/webdav/anak1
Anak2 -> /opt/webdav/anak2
Anak3 -> /opt/webdav/anak3
```

The virtual roots are backed by bind mounts recorded in `/etc/fstab`.

## Cloudflare Tunnel

Remote WebDAV is published at:

```text
drive.tripleatech.my.id
```

Traffic is forwarded by the active `cloudflared-mycloud.service` to the local WebDAV listener on port 6065. SMB/TCP 445 and the Syncthing GUI are not exposed directly to the public Internet.

## Browser and Finder

A WebDAV `PROPFIND` request returns standard `207 Multi-Status` XML. This is required for WebDAV clients such as Finder. A human-friendly HTML directory listing for ordinary browser `GET` requests is the next custom WebDAV development step.

## Apt safety

Do not use `stable` as a permanent Jessie source. Jessie sources should use the Debian archive and be treated as legacy infrastructure.

Do not perform general distribution upgrades on this device.

## Validation

After service changes, run the repository's non-destructive health check before proceeding to further work:

```bash
scripts/health-check.sh
```
