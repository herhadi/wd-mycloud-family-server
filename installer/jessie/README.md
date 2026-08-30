# Clean Debian Jessie recovery artifact

This directory documents the Clean Debian Jessie artifact used during recovery of the WD My Cloud Gen1 in this project.

## Master artifact

The recovery archive is stored locally on the WD data volume and is intentionally not committed to the Git repository because it is approximately 498 MB.

Local path:

    /data/clean-debian-jessie.tgz

SHA256 verified on 2026-08-30:

    2abbd7db6f903a93c29bb235b4130cf1a62792f00c51bf0d1fb6b24ea8e1df2e  clean-debian-jessie.tgz

## Archive contents

The archive contains:

    config.img
    kernel.img
    rootfs.img
    rootfs.md5
    rootfs.txt

## Root filesystem metadata included by the artifact

`rootfs.md5` contains:

    8d8f1009725cbb731adb8d02bec37faf  -

`rootfs.txt` records the following checks:

    md5sum -b /dev/md0
    md5sum -b rootfs.img
    MD5: 9cfc7989e14bddaf5563a504572b2287

    dd if=rootfs.img bs=64k count=31247 2> /tmp/dderror | md5sum
    MD5: 8d8f1009725cbb731adb8d02bec37faf

These values are recorded exactly as supplied by the artifact. Do not reinterpret them as a generic Debian checksum.

## Intended use

The artifact is used for two recovery paths:

1. Recovery of a bricked existing WD My Cloud Gen1 disk.
2. Clean Debian Jessie installation from scratch using the documented WD partition layout.

See `docs/recovery/install-jessie.md` for the full procedure and troubleshooting notes.

## Safety

- Never run `dd` against a device until the device and intended target partition have been verified.
- `/dev/sda4` contains the large data filesystem in the documented layout. Formatting it destroys data.
- Do not use a Debian APT repository named `stable` when installing Jessie. Jessie must use the archived Jessie repositories documented by this project.
- Keep the master archive unchanged so its SHA256 remains reproducible.
