# Architecture

The NAS is intentionally lightweight because WD My Cloud Gen1 has limited memory.

```text
Android phones
   │
   └── Syncthing-Fork (photo backup)
              │
              ▼
        WD My Cloud Gen1
        Debian Jessie
              │
       ┌──────┴──────┐
       │             │
     Samba        Media/DLNA
       │             │
 Finder/Explorer   Smart TV

Remote access is planned through a secure tunnel/VPN.
SMB port 445 should not be exposed directly to the Internet.
```

## Storage layout

```text
/data/
├── Photos/
├── Documents/
├── Movies/
└── Shared/
```

Planned private-user layout:

```text
/data/Photos/<user>/
/data/Documents/<user>/
```

Common media and collaboration areas can remain shared.

## Service philosophy

- SMB is the primary file-system interface for Finder/Explorer.
- Syncthing handles phone photo backup rather than acting as the primary file server.
- Web applications are avoided unless they provide clear value within the 256 MB-class memory budget.
- Remote access should use authentication and a secure tunnel/VPN rather than exposing SMB directly.
