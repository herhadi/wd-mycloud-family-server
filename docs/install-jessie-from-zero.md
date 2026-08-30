# Install Debian Jessie from Zero

This is the **Stage 2 clean-install path** for a WD My Cloud Gen1 when the device is still recoverable or a clean rebuild is intentionally required.

It is separated from `docs/recovery-from-brick.md`: if the NAS is already booting normally and SSH works, do not overwrite working partitions merely to follow the brick-recovery procedure.

## Stage 2 goals

Build a minimal, reproducible Jessie system first. Only after the base system is verified should Samba, Syncthing, private users, DLNA, and remote access be added.

Target baseline:

```text
WD My Cloud Gen1
ARMv7l / armhf
Debian 8.2 Jessie
Linux 3.2.68
root filesystem on md0 (sda1+sda2 RAID1)
sda3 swap
sda4 data mounted at /data
```

## 1. Identify the disk before doing anything destructive

Start with read-only inspection:

```bash
uname -a
uname -m
cat /etc/debian_version
lsblk
blkid
cat /proc/mdstat
mount
```

Expected recovered layout:

```text
sda1 + sda2 -> md0 -> /
sda3        -> swap
sda4        -> /data
sda5/sda6   -> kernel slots
sda7/sda8   -> config/boot slots
```

**STOP** if the device does not match the expected WD My Cloud Gen1 layout. Do not run `dd` until the target partitions are confirmed.

## 2. Prepare the Jessie images

The clean Jessie archive used during recovery contained at least:

```text
rootfs.img
kernel.img
config.img
```

Inspect before extraction:

```bash
tar -tzf /path/to/clean-debian-jessie.tgz | head -50
```

If `/mnt/data/debian-jessie` is read-only, extract small boot files to `/tmp` instead:

```bash
cd /tmp
rm -f kernel.img config.img
tar -xzf /path/to/clean-debian-jessie.tgz kernel.img config.img
ls -lh /tmp/kernel.img /tmp/config.img
```

## 3. Restore the root filesystem

Only after confirming the correct target RAID device:

```bash
mdadm --assemble /dev/md0 /dev/sda1 /dev/sda2
```

If creating a root filesystem from a supplied `rootfs.img`, write it to the **assembled root target** only when the recovery environment and image procedure explicitly require that layout:

```bash
dd if=/path/to/rootfs.img of=/dev/md0 bs=64K conv=fsync status=progress
sync
```

This is destructive. Never substitute `/dev/sda` for `/dev/md0` here.

Then, while the filesystem is unmounted:

```bash
e2fsck -fn /dev/md0
```

The `-n` check is intentionally read-only. A normal repair should only be run after a verified backup and only when needed.

## 4. Restore redundant boot/config slots

For the image set used in this project:

```bash
dd if=/tmp/kernel.img of=/dev/sda5 bs=64K conv=fsync status=progress
dd if=/tmp/kernel.img of=/dev/sda6 bs=64K conv=fsync status=progress
dd if=/tmp/config.img of=/dev/sda7 bs=512 conv=fsync status=progress
dd if=/tmp/config.img of=/dev/sda8 bs=512 conv=fsync status=progress
sync
```

A later `cmp` such as:

```bash
cmp /tmp/kernel.img /dev/sda5
```

may report `EOF on /tmp/kernel.img after byte ...` because the partition is larger than the image. That message alone is not proof of a failed write.

## 5. Boot and verify before installing services

After boot:

```bash
uname -a
uname -m
cat /etc/debian_version
free -m
df -h
lsblk
cat /proc/mdstat
```

Do not proceed to application installation if the root filesystem, data partition, or RAID state is not correct.

## 6. Restore/initialize swap

If `/dev/sda3` reports:

```text
swap format pagesize does not match
```

and the Jessie `mkswap` does not support `--fixpgsz`, recreate it with the page size supported by this system:

```bash
mkswap -f -p 4096 /dev/sda3
swapon /dev/sda3
swapon --show
```

Record the **new UUID** printed by `mkswap` and put that UUID in `/etc/fstab`:

```text
UUID=<new-swap-uuid> none swap sw 0 0
```

Verify:

```bash
free -m
swapon --show
```

## 7. Configure Jessie package sources carefully

Jessie is archived. Do not leave the system using the moving `stable` suite.

Use the Debian archive for Jessie and avoid relying on a nonexistent `jessie-updates` suite. Archive signing metadata can also show an expired key warning because Jessie is long out of support.

After changing sources, inspect before installing packages:

```bash
cat /etc/apt/sources.list
apt-get update
apt-cache policy base-files samba
```

The project baseline used archive packages and obtained Samba 4.2.14 for ARMHF.

## 8. Establish SSH and a recovery checkpoint

Before installing optional services, verify SSH from another machine. Keep a copy of important configuration files under `/root` or another local recovery location, and document the same configuration in this repository.

Do not put passwords or SSH private keys in Git.

## 9. Minimal service order

Install and validate services in this order:

1. SSH/base system
2. Samba
3. Syncthing 1.19.2 static ARM binary
4. private family directories and Samba permissions
5. optional DLNA/UPnP
6. remote access/tunnel or VPN

Do not install a heavyweight web cloud platform on this hardware without first measuring memory use. The device has only about 226 MB RAM.

## Troubleshooting index

### `Exec format error`

The command is probably trying to execute an ARM binary from an incompatible recovery environment. `chroot` does not magically translate CPU architecture.

### `target is busy` when unmounting `/mnt/wdroot`

Check for nested mounts:

```bash
mount | grep /mnt/wdroot
```

The recovery environment may have `/dev`, `/proc`, or `/sys` mounted below the root. Unmount nested mounts first, then the root filesystem.

### `e2fsck: Warning! /dev/md0 is mounted`

Stop. Unmount `/dev/md0` before filesystem checking. The check used for verification is:

```bash
e2fsck -fn /dev/md0
```

### `tar: Cannot open: Read-only file system`

The destination filesystem may be read-only. Check:

```bash
df -h /tmp /mnt/data
mount | grep /mnt/data
```

Use a writable temporary filesystem such as `/tmp` for extracting small files if enough space is available.

### `apt-get update` returns 404 for `jessie-updates`

Do not chase the missing suite. Jessie is archived; remove/disable the obsolete `jessie-updates` entry and use the Jessie archive.

### Swap page-size mismatch

Use the Jessie-compatible `mkswap -p 4096` method documented above when `--fixpgsz` is unavailable.

## Recovery principle

A clean install is successful only when the device can boot repeatedly, SSH works, `/data` is mounted correctly, RAID is assembled correctly, and the base system is stable **before** application services are added.
