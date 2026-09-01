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
- Do not put credentials, private keys, device IDs, private certificates, photos, or documents in Git.
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

## Canonical family identity and storage layout

The canonical family member names are the real names used by this project:

- `Abi`
- `Umi`
- `Adel`
- `Adzra`
- `Afzal`

Do not replace these with generic labels such as `Ayah`, `Ibu`, `Anak1`, `Anak2`, or `Anak3`.

The final storage layout is:

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

There is no `/data/Private/` directory in the final model.

## Permission model

- `/data/Abi`, `/data/Umi`, `/data/Adel`, `/data/Adzra`, and `/data/Afzal` are private roots.
- Each private root is fully accessible by its owner and inaccessible to other family users.
- New files/directories inside a user's root must inherit that user's ownership/permissions.
- `/data/Family` is shared, but its subdirectories may have purpose-specific permissions.
- `/data/Family/Photos` is read-only to family users but writable by the `syncthing` service account for photo backup.
- Android photo folders are configured as Send Only.
- `Family/Shared` may be read/write for family users when configured for collaboration.

## WebDAV logical model

Each WebDAV account gets access to its own private root plus the shared `Family` tree. `Private` may be used as a virtual WebDAV label only; it does not imply a physical `/data/Private` directory.

The physical mapping is:

```text
Abi   -> /data/Abi
Umi   -> /data/Umi
Adel  -> /data/Adel
Adzra -> /data/Adzra
Afzal -> /data/Afzal
```

Implementation-specific bind mounts under `/opt/webdav/` must not be confused with the canonical `/data` layout.

## Validation

Run the non-destructive checker after service changes:

```bash
scripts/health-check.sh
```

The checker verifies platform assumptions, `/data`, RAID, swap, Samba, `testparm`, and Syncthing without modifying the system.

## Recovery discipline

Recovery procedures under `docs/recovery/` are separate from normal service deployment. Always read them completely before any disk-writing step and verify the target disk immediately before each destructive command.
