# AGENTS.md

## Scope

This repository documents and scripts a lightweight private family NAS built on WD My Cloud Gen1 hardware.

## Privacy and portability rule

The repository is intended to be reusable by other families. Use only these generic role aliases in public documentation:

```text
Ayah
Ibu
Anak1
Anak2
Anak3
```

They represent family roles, not fixed personal identities. Never add real family names, private usernames, phone labels, or other personal identifiers to repository documentation, diagrams, examples, commit messages, or configuration templates.

A deploying family may replace the generic aliases with its own private names in local configuration outside Git.

## Verified environment

- ARMv7l / armhf
- Debian Jessie 8.2
- Linux kernel 3.2.68
- Approximately 226 MB RAM
- 512 MB swap on `/dev/sda3`
- Data volume `/dev/sda4` mounted at `/data`
- Samba 4.2.14-Debian
- Syncthing v2.1.3 static ARM binary
- WebDAV v5.15.0 static ARM binary
- WebDAV listener on TCP 6065
- Browser Gateway `webdav-gw` on TCP 6066, bound to localhost
- Cloudflare Tunnel via `cloudflared-mycloud.service`

## Safety rules

- Never assume `/dev/sda` is disposable.
- Never run `mkfs`, `wipefs`, `mdadm --create`, partitioning, or destructive `dd` operations unless the task explicitly requires it and the target has been verified.
- Do not format `/dev/sda4` during routine service setup.
- Do not switch Debian Jessie sources to a newer Debian release.
- Do not use `stable` in long-lived Jessie configuration; Jessie is legacy infrastructure and must use archived Jessie repositories when packages are required.
- Prefer small, reversible changes with backups before configuration replacement.
- Preserve the working boot/kernel configuration unless a documented recovery step is being performed.
- Do not expose SMB/TCP 445 or the Syncthing GUI directly to the public Internet.
- Do not run filesystem commands merely to make documentation match the repository; documentation changes must not alter the physical NAS.

## Script rules

Scripts must:

- fail early when assumptions are not met;
- be non-destructive by default;
- validate generated configuration before restarting services;
- use `/data` for user data and avoid writing application state into the data filesystem unless explicitly intended;
- avoid `systemd` assumptions for legacy SysV-managed services, except for the verified WebDAV, Browser Gateway, and Cloudflare systemd units already present on the device.

## Current services

- Samba 4.2.14-Debian
- Syncthing v2.1.3 static ARM binary
- WebDAV v5.15.0 static ARM binary
- Browser Gateway `webdav-gw` static ARMv7 binary
- Cloudflare Tunnel via `cloudflared-mycloud.service`

## Canonical storage layout

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
- `/data/Family/Documents`, `/data/Family/Shared`, and `/data/Family/Videos` are writable by family users.
- `/data/Family/Photos` is read-only to family users but writable by the `syncthing` service account for photo backup.
- Android photo folders are configured as **Send Only**.
- MyCloud photo-destination folders are configured as **Receive Only** after initial synchronization is verified.

The protocol boundary is intentional:

- Samba provides normal CRUD according to filesystem permissions.
- WebDAV provides CRUD for private roots, `FamilyDocs`, `FamilyShared`, and `FamilyVideos`.
- WebDAV `FamilyPhotos` is read-only.
- The WebDAV `FamilyPhotos` rule must not restrict Samba CRUD.

## Syncthing photo-backup model

```text
Android phone
   │ Send Only
   ▼
Syncthing
   │
   ▼
MyCloud /data/Family/Photos/<member>
   │ Receive Only
   ▼
FamilyPhotos
```

See `docs/syncthing.md` before changing Syncthing configuration. Do not reset the global Syncthing database for a folder problem without first checking the folder path, `.stfolder`, mount state, permissions, and source-phone data.

## WebDAV logical model

Each authenticated WebDAV account uses its own `/data/<member>` directory directly as the WebDAV root. Family directories are exposed inside that root through filesystem bind mounts:

```text
<member>
├── FamilyDocs
├── FamilyPhotos
├── FamilyShared
├── FamilyVideos
├── private files/folders
└── ...
```

Production WebDAV permissions are:

```yaml
permissions: CRUD
rules:
  - regex: ^/FamilyPhotos(/.*)?$
    permissions: R
```

The read-only rule applies to WebDAV requests only. Samba uses the underlying filesystem permissions independently.

Implementation-specific bind mounts under `/opt/webdav/` used by the legacy design have been removed. They are not part of the canonical or production storage model.

## Browser Gateway

The Browser Gateway is a thin reverse proxy/interceptor in `gateway/`.

- Browser directory `GET` requests are rendered as HTML.
- WebDAV methods are passed through to the WebDAV service, with `PROPFIND`
  responses filtered to hide common internal entries.
- File requests are passed through unchanged.
- The gateway listens on `127.0.0.1:6066` and must not be exposed directly.
- Cloudflare is the intended public ingress for browser access.

## Validation

Run the non-destructive checker after service changes:

```bash
scripts/health-check.sh
```

The checker verifies platform assumptions, `/data`, RAID, swap, Samba, `testparm`, and Syncthing without modifying the system.

For WebDAV changes, also verify `webdav.service`, port 6065, private-user isolation, Family CRUD paths, and the read-only Family Photos rule.

For Browser Gateway changes, run the Go tests and verify the binary on the physical ARMv7 target before creating a release checkpoint.

## Recovery discipline

Recovery procedures under `docs/recovery/` are separate from normal service deployment. Always read them completely before any disk-writing step and verify the target disk immediately before each destructive command.
