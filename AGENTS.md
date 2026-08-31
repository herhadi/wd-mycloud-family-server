# AGENTS.md

## Scope

This repository documents and scripts a lightweight family NAS built on WD My Cloud Gen1 hardware.

## Verified environment

- ARMv7l / armhf
- Debian Jessie 8.2
- Linux kernel 3.2.68
- Approximately 226 MB RAM
- 512 MB swap on `/dev/sda3`
- Data volume `/dev/sda4` mounted at `/data`
- Samba 4.2.14-Debian
- Syncthing v2.1.3 static ARM binary

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

## Script rules

Scripts must:

- fail early when assumptions are not met;
- be non-destructive by default;
- validate generated configuration before restarting services;
- use `/data` for user data and avoid writing application state into the data filesystem unless explicitly intended;
- avoid `systemd` assumptions because the target uses Debian Jessie/SysV-style service management.

## Current services

- Samba 4.2.14-Debian
- Syncthing v2.1.3 static ARM binary

## Family layout

The intended Samba layout is:

- `/data/Private/<user>` — mode 0700 and accessible only through the matching SMB account.
- `/data/Shared` — shared read/write area for Unix group `family`.
- `/data/Media` — shared read/write media area for Unix group `family`.

Use `scripts/install-samba-family.sh` to create the layout. Do not manually copy the working baseline over the generated configuration after installation.

## Validation

Run the non-destructive checker after service changes:

```bash
scripts/health-check.sh
```

The checker verifies platform assumptions, `/data`, RAID, swap, Samba, `testparm`, and Syncthing without modifying the system.

## Recovery discipline

Recovery procedures under `docs/recovery/` are separate from normal service deployment. Always read them completely before any disk-writing step and verify the target disk immediately before each destructive command.
