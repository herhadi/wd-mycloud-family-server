# Architecture

The NAS is intentionally lightweight because WD My Cloud Gen1 has limited memory.

## Naming convention

Repository diagrams use generic role labels only:

```text
Ayah  = live Abi
Ibu   = live Umi
Anak1 = live Adzra
Anak2 = live Adel
Anak3 = live Afzal
```

These labels are documentation aliases. The live My Cloud accounts and directories keep the real names.

```text
Android phones
   │
   └── Syncthing
          │
          │ Send Only
          ▼
   /data/Family/Photos/<live-member>
          ▲
          │ Receive Only
          │
   WD My Cloud Syncthing

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
                     logical user roots
                              │
                              ▼
                    /data/<live-member>
                         + /data/Family

Smart TV access via DLNA remains a separate pending service.
```

## Storage layout

Repository-role representation:

```text
/data/
├── Family/
│   ├── Documents/
│   ├── Photos/
│   │   ├── Ayah/       # live: Abi
│   │   ├── Ibu/        # live: Umi
│   │   ├── Anak1/      # live: Adzra
│   │   ├── Anak2/      # live: Adel
│   │   └── Anak3/      # live: Afzal
│   ├── Shared/
│   └── Videos/
├── Ayah/              # live: Abi
├── Ibu/               # live: Umi
├── Anak1/             # live: Adzra
├── Anak2/             # live: Adel
└── Anak3/             # live: Afzal
```

There is no `/data/Private/` directory in the final model.

## Permission model

- Each live member has a private root directly below `/data`.
- The matching member has full read/write/delete access to that root.
- Other family members have no access to another member's root.
- New files and directories created inside a member root inherit the live-server member account ownership/permissions.
- `/data/Family/Documents`, `/data/Family/Shared`, and `/data/Family/Videos` are writable by family WebDAV/Samba users.
- `/data/Family/Photos` is read-only to family WebDAV/Samba users but writable by the `syncthing` service account for photo backup.
- Phone photo folders use **Send Only**.
- MyCloud photo-destination folders use **Receive Only** after initial synchronization is verified.

## Syncthing photo backup

Syncthing is a one-way phone-to-NAS backup path:

```text
Phone photo folder
      │
      │ Send Only
      ▼
Syncthing cluster
      │
      │ Receive Only on MyCloud
      ▼
/data/Family/Photos/<live-member>
      │
      ├── Samba: read-only
      └── WebDAV: read-only
```

Live member mapping:

```text
Ayah  → /data/Family/Photos/Abi
Ibu   → /data/Family/Photos/Umi
Anak1 → /data/Family/Photos/Adzra
Anak2 → /data/Family/Photos/Adel
Anak3 → /data/Family/Photos/Afzal
```

The first live phone is Poco F7 and its target is `/data/Family/Photos/Abi`.

See `docs/syncthing.md` for the operational procedure.

## WebDAV logical roots

Each WebDAV account gets access to its own private root plus the shared `Family` tree:

```text
<member>
├── private  → live /data/<member>
└── family   → /data/Family
```

Documentation-role mappings:

```text
Ayah  → live /data/Abi
Ibu   → live /data/Umi
Anak1 → live /data/Adzra
Anak2 → live /data/Adel
Anak3 → live /data/Afzal
```

`private` is a WebDAV logical label only. There is no physical `/data/Private/` directory and no `/opt/webdav/` bind-mount layer in the final implementation.

The WebDAV global permission is `CRUD`, with the following path rule:

```yaml
permissions: CRUD
rules:
  - regex: ^/family/Photos(/.*)?$
    permissions: R
```

## Service roles

- **Samba** — primary LAN filesystem interface for Finder/Explorer.
- **Syncthing** — phone photo backup into member-specific directories under `/data/Family/Photos/`.
- **WebDAV** — authenticated remote filesystem interface on TCP 6065.
- **Cloudflare Tunnel** — publishes the WebDAV service through `drive.tripleatech.my.id` without exposing SMB/445.
- **DLNA** — not yet promoted; must be selected only after compatibility and memory testing.

## Browser versus WebDAV clients

A standards-compliant WebDAV `PROPFIND` request must continue to return `207 Multi-Status` XML. Therefore a browser can legitimately display raw XML for directory requests.

The next WebDAV development step is to add a human-friendly HTML directory/file listing for ordinary browser `GET` requests while preserving `PROPFIND`, `OPTIONS`, `HEAD`, authentication, and normal WebDAV semantics for Finder and other clients.

## Security boundary

Public traffic reaches only Cloudflare/Tunnel/WebDAV. SMB/TCP 445 and the Syncthing GUI remain LAN-only services.

Credentials, Cloudflare tunnel credential files, API keys, and other secrets must never be committed to this repository.
