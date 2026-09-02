# Architecture

The NAS is intentionally lightweight because WD My Cloud Gen1 has limited memory.

## Naming convention

Repository documentation uses generic family-role aliases only:

- **Ayah**
- **Ibu**
- **Anak1**
- **Anak2**
- **Anak3**

These are roles, not fixed personal names. Each deployment may use different private names locally. Do not publish those names in this repository.

```text
Android phones
   │
   └── Syncthing
          │
          │ Send Only
          ▼
   /data/Family/Photos/<member>
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
                     /data/<member>
                              │
                              ├── FamilyDocs
                              ├── FamilyPhotos
                              ├── FamilyShared
                              └── FamilyVideos

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
├── Ayah/
├── Ibu/
├── Anak1/
├── Anak2/
└── Anak3/
```

There is no `/data/Private/` directory in the final model.

## Permission model

- Each family role has a private root directly below `/data`.
- The matching member has full read/write/delete access to that root.
- Other family members have no access to another member's root.
- New files and directories inside a member root must inherit the local member account ownership/permissions.
- `/data/Family/Documents`, `/data/Family/Shared`, and `/data/Family/Videos` are writable by family WebDAV/Samba users.
- `/data/Family/Photos` is read-only to family WebDAV/Samba users but writable by the `syncthing` service account for photo backup.
- Phone photo folders use **Send Only**.
- MyCloud photo-destination folders use **Receive Only** after initial synchronization is verified.

The shared directories are presented inside each private root through filesystem bind mounts:

```text
/data/Family/Documents → /data/<member>/FamilyDocs
/data/Family/Photos    → /data/<member>/FamilyPhotos
/data/Family/Shared    → /data/<member>/FamilyShared
/data/Family/Videos    → /data/<member>/FamilyVideos
```

This allows Samba and WebDAV to expose the same user-facing tree without giving clients a separate `Family` virtual root.

## Syncthing photo backup

Syncthing is a one-way phone-to-NAS backup path:

```text
Phone photo folder
      │
      │ Send Only
      ▼
Syncthing
      │
      │ Receive Only on MyCloud
      ▼
/data/Family/Photos/<member>
      │
      ├── Samba: read-only
      └── WebDAV: read-only
```

Generic member mapping:

```text
Ayah  → /data/Family/Photos/Ayah
Ibu   → /data/Family/Photos/Ibu
Anak1 → /data/Family/Photos/Anak1
Anak2 → /data/Family/Photos/Anak2
Anak3 → /data/Family/Photos/Anak3
```

See `docs/syncthing.md` for the operational procedure.

## WebDAV root model

Each WebDAV account uses its matching private directory directly as the WebDAV root:

```text
<member> WebDAV root
├── FamilyDocs     → bind mount to /data/Family/Documents
├── FamilyPhotos   → bind mount to /data/Family/Photos
├── FamilyShared   → bind mount to /data/Family/Shared
├── FamilyVideos   → bind mount to /data/Family/Videos
├── private files
└── private folders
```

There are no `private/` or `family/` virtual WebDAV directories in the final implementation. There is also no `/opt/webdav/` bind-mount layer.

The WebDAV configuration uses a single `directory: /data/<member>` entry per account. The global permission is `CRUD`, with the Family Photos path restricted to `R`:

```yaml
permissions: CRUD
rules:
  - regex: ^/FamilyPhotos(/.*)?$
    permissions: R
```

Production passwords are stored outside the repository in `/etc/webdav/webdav.env` and loaded by systemd with `EnvironmentFile`. The YAML uses `{env}...` references instead of plaintext or committed password hashes.

## Service roles

- **Samba** — primary LAN filesystem interface for Finder/Explorer.
- **Syncthing** — phone photo backup into member-specific directories under `/data/Family/Photos/`.
- **WebDAV** — authenticated remote filesystem interface on TCP 6065, rooted at `/data/<member>` per account.
- **Cloudflare Tunnel** — publishes the WebDAV service without exposing SMB/445.
- **DLNA** — not yet promoted; must be selected only after compatibility and memory testing.

## Browser versus WebDAV clients

A standards-compliant WebDAV `PROPFIND` request must continue to return `207 Multi-Status` XML. Therefore a browser can legitimately display raw XML for directory requests.

The next WebDAV development step is to add a human-friendly HTML directory/file listing for ordinary browser `GET` requests while preserving `PROPFIND`, `OPTIONS`, `HEAD`, authentication, and normal WebDAV semantics for Finder and other clients.

## Security boundary

Public traffic reaches only Cloudflare/Tunnel/WebDAV. SMB/TCP 445 and the Syncthing GUI remain LAN-only services.

Credentials, WebDAV environment files, Cloudflare tunnel credential files, API keys, private certificates, and family personal data must never be committed to this repository.
