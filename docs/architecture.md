# Architecture

The NAS is intentionally lightweight because WD My Cloud Gen1 has limited memory.

Repository documentation uses generic family labels only. Real family names, usernames, and device-specific identities are configured on the live server and must not be recorded here.

```text
Android phones
   │
   └── Syncthing-Fork
          │
          ▼
   /data/Family/Photos/<member-N>

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
                              │
                              ▼
                    /data/<member-N>
                         + /data/Family

Smart TV access via DLNA remains a separate pending service.
```

## Storage layout

```text
/data/
├── Family/
│   ├── Documents/
│   ├── Photos/
│   │   ├── <member-1>/
│   │   ├── <member-2>/
│   │   ├── <member-3>/
│   │   ├── <member-4>/
│   │   └── <member-5>/
│   ├── Shared/
│   └── Videos/
├── <member-1>/
├── <member-2>/
├── <member-3>/
├── <member-4>/
└── <member-5>/
```

There is no `/data/Private/` directory in the final storage model.

## Permission model

- Each member has a private root directly below `/data/`.
- The matching member has full read/write/delete access to that root.
- Other family members have no access to another member's root.
- New files and directories created inside a member root inherit the live-server member account ownership/permissions.
- `Family/` is shared.
- `Family/Photos/` is read-only to family users through the file-sharing/WebDAV layer, while Syncthing is allowed to write photo backups.
- Phone photo folders use Send Only on the phone side.

## WebDAV virtual roots

Each WebDAV account is confined to its own logical root containing `Private` and `Family` views. These are virtual labels only; `Private` does not represent a physical `/data/Private/` directory.

```text
<member-1> -> /opt/webdav/<login-1>
<member-2> -> /opt/webdav/<login-2>
<member-3> -> /opt/webdav/<login-3>
<member-4> -> /opt/webdav/<login-4>
<member-5> -> /opt/webdav/<login-5>
```

The live server maps each login to its matching `/data/<member-N>` root plus `/data/Family`. Real login names are intentionally excluded from this repository.

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

Credentials, real family identities, and Cloudflare tunnel credential files are never committed to this repository.
