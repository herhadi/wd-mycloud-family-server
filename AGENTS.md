# AGENTS.md

## Scope

This repository documents and scripts a lightweight private family NAS built on WD My Cloud Gen1 hardware.

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
- Cloudflare Tunnel via `cloudflared-mycloud.service`

## Safety rules

- Never assume `/dev/sda` is disposable.
- Never run `mkfs`, `wipefs`, `mdadm --create`, partitioning, or destructive `dd` operations unless the task explicitly requires it and the target has been verified.
- Do not format `/dev/sda4` during routine service setup.
- Do not put credentials, private keys, API keys, device IDs with secrets, private certificates, photos, or documents in Git.
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
- avoid `systemd` assumptions for legacy SysV-managed services, except for the verified WebDAV and Cloudflare systemd units already present on the device.

## Current services

- Samba 4.2.14-Debian
- Syncthing v2.1.3 static ARM binary
- WebDAV v5.15.0 static ARM binary
- Cloudflare Tunnel via `cloudflared-mycloud.service`

## Canonical family identity and live-name mapping

Repository documentation uses generic role labels:

```text
Ayah  = live Abi
Ibu   = live Umi
Anak1 = live Adzra
Anak2 = live Adel
Anak3 = live Afzal
```

These are documentation aliases only. **Never rename the live accounts/directories to match the repository aliases.**

The live storage model is:

```text
/data/
├── Family/
│   ├── Documents/
│   ├── Photos/
│   │   ├── Abi/
│   │   ├── Umi/
│   │   ├── Adzra/
│   │   ├── Adel/
│   │   └── Afzal/
│   ├── Shared/
│   └── Videos/
├── Abi/
├── Umi/
├── Adzra/
├── Adel/
└── Afzal/
```

There is no `/data/Private/` directory in the final model.

## Permission model

- Each live member has a private root directly below `/data`.
- The matching member has full read/write/delete access to that root.
- Other family members have no access to another member's root.
- New files and directories inside a member root must inherit the live-server member account ownership/permissions.
- `/data/Family/Documents`, `/data/Family/Shared`, and `/data/Family/Videos` are writable by family users.
- `/data/Family/Photos` is read-only to family users but writable by the `syncthing` service account for photo backup.
- Android photo folders are configured as **Send Only**.
- MyCloud photo-destination folders are configured as **Receive Only** after initial synchronization is verified.
- Other Family subdirectories may have purpose-specific permissions.

## Syncthing photo-backup model

The intended direction is one-way:

```text
Android phone
   │ Send Only
   ▼
Syncthing
   │
   ▼
MyCloud /data/Family/Photos/<live-member>
   │ Receive Only
   ▼
Samba/WebDAV read-only FamilyPhotos
```

Live mappings:

```text
Ayah  → /data/Family/Photos/Abi
Ibu   → /data/Family/Photos/Umi
Anak1 → /data/Family/Photos/Adzra
Anak2 → /data/Family/Photos/Adel
Anak3 → /data/Family/Photos/Afzal
```

See `docs/syncthing.md` before changing Syncthing configuration. Do not reset the global Syncthing database for a folder problem without first checking the folder path, `.stfolder`, mount state, permissions, and source-phone data.

## WebDAV logical model

Each WebDAV account gets access to its own private root plus the shared `Family` tree:

```text
<member>
├── private  → /data/<live-member>
└── family   → /data/Family
```

`private` is a logical WebDAV label only; it does not imply a physical `/data/Private` directory.

The production WebDAV permission model is:

```yaml
permissions: CRUD
rules:
  - regex: ^/family/Photos(/.*)?$
    permissions: R
```

Implementation-specific bind mounts under `/opt/webdav/` were used by the legacy design and have been removed. They are not part of the canonical or production storage model.

## Validation

Run the non-destructive checker after service changes:

```bash
scripts/health-check.sh
```

The checker verifies platform assumptions, `/data`, RAID, swap, Samba, `testparm`, and Syncthing without modifying the system.

For WebDAV changes, also verify `webdav.service`, port 6065, private-user isolation, Family CRUD paths, and the read-only Family Photos rule.

## Recovery discipline

Recovery procedures under `docs/recovery/` are separate from normal service deployment. Always read them completely before any disk-writing step and verify the target disk immediately before each destructive command.
