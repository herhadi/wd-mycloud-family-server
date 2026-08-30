# Hardware Baseline

## Device

WD My Cloud Gen1 with one 3 TB-class HDD.

## Verified runtime

| Item | Value |
|---|---|
| Architecture | ARMv7l / armhf |
| Debian | 8.2 (Jessie) |
| Kernel | 3.2.68 |
| RAM | 226 MB total |
| Swap | 512 MB, `/dev/sda3` |
| Data | `/dev/sda4` mounted at `/data` |
| Network | `eth0`, `192.168.11.125/24` |
| Root filesystem | `/dev/md0`, RAID1 from `sda1` + `sda2` |
| Data capacity | ~2.7 TB |

## Current disk layout

```text
sda
├── sda1  2G   ┐
├── sda2  2G   ├── md0 RAID1 → /
├── sda3 512M  └── swap
├── sda4  2.7T      → /data
├── sda5 100M       kernel slot
├── sda6 100M       kernel slot
├── sda7   2M       boot/config slot
└── sda8   2M       boot/config slot
```

The boot/kernel/config layout is specific to the WD My Cloud Gen1 platform.

## Verified memory state

At the latest baseline check:

- RAM: 226 MB total
- RAM used: 121 MB
- RAM available/free reported: 104 MB free, 197 MB in the `-/+ buffers/cache` view
- Swap: 511 MB available, approximately 40 MB used

## Storage state

`/data` is an ext4 filesystem on `/dev/sda4` with approximately 2.7 TB capacity. At the latest check it used approximately 13 GB.

## Installed services verified

- Samba: `4.2.14-Debian`
- Syncthing: `1.19.2` static ARM binary
- Syncthing-Fork: used on Android for photo backup

## Recovery history

The root filesystem was restored to `/dev/md0` from a clean Debian Jessie rootfs image. Kernel and config images were restored to both redundant boot slots. The filesystem was checked with `e2fsck` after unmounting `/mnt/wdroot`.

## Notes

- Do not perform a distribution upgrade as part of routine setup.
- Do not expose SMB/port 445 directly to the Internet.
- Verify the device and mounted filesystems before any destructive disk operation.
- Keep credentials and private configuration outside this repository.
