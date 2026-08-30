# AGENTS.md

## Scope

This repository documents and scripts a lightweight family NAS built on WD My Cloud Gen1 hardware.

## Environment constraints

- ARMv7l / armhf
- Debian Jessie 8.2
- Linux kernel 3.2.68
- Approximately 226 MB RAM available
- 512 MB swap
- Data volume mounted at `/data`

## Safety rules

- Never assume `/dev/sda` is disposable.
- Never run `mkfs`, `wipefs`, `mdadm --create`, or destructive `dd` operations unless the task explicitly requires them and the target has been verified.
- Do not put credentials or private data in Git.
- Do not switch Debian sources from Jessie to a newer Debian release.
- Do not use `stable` in long-lived Jessie configuration because `stable` moves over time; use the Jessie archive when Jessie packages are required.
- Prefer small, reversible changes.
- Preserve the working boot/kernel configuration unless a documented recovery step is being performed.

## Repository content

Scripts should be safe to inspect before execution and should fail early when assumptions are not met.

Configuration examples must use placeholders for usernames, domains, passwords, device IDs, and certificates.

## Current services

- Samba 4.2.14-Debian
- Syncthing 1.19.2 static ARM binary

## Future services

- Private per-user SMB shares
- Family shared media
- DLNA/UPnP
- Secure remote access via Cloudflare/VPN
