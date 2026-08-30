# Hardware Baseline

## Device

WD My Cloud Gen1 with one 3 TB-class HDD.

## Verified runtime

| Item | Value |
|---|---|
| Architecture | ARMv7l / armhf |
| Debian | 8.2 (Jessie) |
| Kernel | 3.2.68 |
| RAM | ~226 MB available |
| Swap | 512 MB, `/dev/sda3` |
| Data | `/dev/sda4` mounted at `/data` |
| Network | `eth0`, DHCP |

## Disk layout used during recovery

- `sda1` + `sda2`: RAID1 root filesystem (`/dev/md0`)
- `sda3`: swap
- `sda4`: data filesystem
- `sda5` + `sda6`: kernel slots
- `sda7` + `sda8`: boot/config slots

## Notes

The boot layout is specific to the WD My Cloud Gen1 platform. Recovery work must verify the device before any destructive operation.