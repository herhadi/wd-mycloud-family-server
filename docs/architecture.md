# Architecture

The NAS is intentionally lightweight because WD My Cloud Gen1 has limited memory.

```text
Android phones
   │
   └── Syncthing-Fork
          │
          ▼
   /data/Family/Photos/<user>

                         ┌───────────────┐
macOS/Windows ──────────>│ Samba         │
                         │ LAN / SMB     │
                         └───────────────┘

Browser/Finder ── HTTPS ─> drive.tripleatech.my.id
                              │
                              ▼
                       Cloudflare Tunnel
                              │
                              ▼
                         WebDAV :6065
                              │
                              ▼
                      virtual user roots
                        /opt/webdav/*
                              │
                              ▼
                           /data/*

Smart TV access via DLNA remains a separate pending service.
```

## Storage layout

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

## WebDAV virtual roots

Each WebDAV account is confined to its own virtual root containing only `Private` and `Family`:

```text
Ayah  -> /opt/webdav/ayah
Ibu   -> /opt/webdav/ibu
Anak1 -> /opt/webdav/anak1
Anak2 -> /opt/webdav/anak2
Anak3 -> /opt/webdav/anak3
```

The `Private` directory is user-specific. `Family` is shared and maps to `/data/Family`.

The virtual roots are implemented with bind mounts recorded in `/etc/fstab` and are mounted before the WebDAV service starts.

## Service roles

- **Samba** — primary LAN filesystem interface for Finder/Explorer.
- **Syncthing** — phone photo backup into user-specific directories under `/data/Family/Photos/`.
- **WebDAV** — authenticated remote filesystem interface on TCP 6065.
- **Cloudflare Tunnel** — publishes the WebDAV service through `drive.tripleatech.my.id` without exposing SMB/445.
- **DLNA** — not yet promoted; must be selected only after compatibility and memory testing.

## Browser versus WebDAV clients

A standards-compliant WebDAV `PROPFIND` request must continue to return `207 Multi-Status` XML. Therefore a browser can legitimately display raw XML for directory requests.

The next WebDAV development step is to add a human-friendly HTML directory/file listing for ordinary browser `GET` requests while preserving `PROPFIND`, `OPTIONS`, `HEAD`, authentication, and normal WebDAV semantics for Finder and other clients.

## Security boundary

Public traffic reaches only Cloudflare/Tunnel/WebDAV. SMB/TCP 445 and the Syncthing GUI remain LAN-only services.

Credentials and Cloudflare tunnel credential files are never committed to this repository.
