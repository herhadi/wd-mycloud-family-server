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

The canonical family member labels are **Ayah**, **Ibu**, **Anak1**, **Anak2**, and **Anak3**. Use these names consistently in current repository documentation, diagrams, storage paths, and configuration templates.

The final storage model is:

```text
/data/
├── Family/
│   ├── Documents/
│   ├── Photos/
│   │   ├── Ayah/
│   │   ├── Ibu/
│   │   ├── Anak1/
│   │   ├── Anak2/
│   │   ├── Anak3/
│   │   └── (no other member roots)
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

- Each member has a private root directly below `/data/`.
- The matching member has full read/write/delete access to that root.
- Other family members have no access to another member's root.
- New files and directories inside a member root must inherit the live-server member account ownership/permissions.
- `/data/Family/Documents`, `/data/Family/Shared`, and `/data/Family/Videos` are writable by family users.
- `/data/Family/Photos` is read-only to family users but writable by the `syncthing` service account for photo backup.
- Android photo folders are configured as Send Only.
- Other Family subdirectories may have purpose-specific permissions.

## WebDAV logical model

Each WebDAV account gets access to its own private root plus the shared `Family` tree:

```text
<member>
├── private  → /data/<member>
└── family   → /data/Family
```

Canonical member mappings:

```text
Ayah   → /data/Ayah
Ibu    → /data/Ibu
Anak1  → /data/Anak1
Anak2  → /data/Anak2
Anak3  → /data/Anak3
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
