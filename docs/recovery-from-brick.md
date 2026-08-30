# Recovery from a Bricked WD My Cloud Gen1

This document records the recovery path that was actually used on the WD My Cloud Gen1. It is intended as a field recovery guide, not a generic WD installer.

> **WARNING:** The commands below can destroy partitions or boot data if applied to the wrong disk. Verify the device and partition layout before every destructive `dd` command.

## 1. Decide which path applies

- If the WD is already booting normally and SSH works, **do not perform brick recovery**. Continue to the Jessie baseline/install path in `docs/install-jessie-from-zero.md` only if a clean rebuild is actually desired.
- If the device is bricked but the HDD is accessible from a recovery environment, use this recovery path.

## 2. Assemble the root RAID

The recovered disk used this layout:

```text
sda1 + sda2 -> /dev/md0 (RAID1 root)
sda3        -> swap
sda4        -> /data
sda5/sda6   -> kernel slots
sda7/sda8   -> config/boot slots
```

Example:

```bash
mdadm --assemble /dev/md0 /dev/sda1 /dev/sda2
mkdir -p /mnt/wdroot
mount /dev/md0 /mnt/wdroot
```

Verify the filesystem before changing anything:

```bash
mount | grep -E 'wdroot|md0'
e2fsck -fn /dev/md0
```

The `e2fsck -fn` check must be performed while `/dev/md0` is **not mounted**. During the actual recovery an initial check produced a warning because the filesystem was still mounted; after unmounting, the warning disappeared.

## 3. Locate the Jessie recovery archive

The recovery archive contained:

```text
rootfs.img
kernel.img
config.img
```

The archive was inspected without extracting into `/mnt/data/debian-jessie`, because that location was temporarily read-only. Extracting to `/tmp` worked:

```bash
cd /tmp
rm -f kernel.img config.img

tar -xzf /mnt/data/clean-debian-jessie.tgz kernel.img config.img
ls -lh /tmp/kernel.img /tmp/config.img
```

## 4. Restore kernel and config slots

The verified recovery used the same kernel image in both kernel slots and the same config image in both config slots:

```bash
dd if=/tmp/kernel.img of=/dev/sda5 bs=64K conv=fsync status=progress
dd if=/tmp/kernel.img of=/dev/sda6 bs=64K conv=fsync status=progress
dd if=/tmp/config.img of=/dev/sda7 bs=512 conv=fsync status=progress
dd if=/tmp/config.img of=/dev/sda8 bs=512 conv=fsync status=progress
sync
```

Do not interpret `cmp` reporting EOF after the image length as a mismatch by itself: the partition is larger than the image, so `cmp /tmp/kernel.img /dev/sda5` can report EOF when the image has been completely consumed.

## 5. Root password / architecture trap

The recovered root filesystem was ARMv7. Running its ARM binaries from another architecture can fail with:

```text
Exec format error
```

For example, `chroot /mnt/wdroot /usr/sbin/chpasswd` from an incompatible recovery environment cannot execute an ARM binary. Do not assume this means the binary is corrupt.

If password recovery is required, use an architecture-compatible environment or modify the password database using an appropriate offline method. Never put the resulting password in this repository.

## 6. First boot verification

After restoring the boot slots and booting the WD, verify:

```bash
uname -a
uname -m
cat /etc/debian_version
```

The recovered baseline was:

```text
Debian 8.2 (Jessie)
Linux 3.2.68
armv7l
```

Then verify storage:

```bash
df -h
lsblk
```

Expected data layout:

```text
/dev/sda4 -> /data
```

## 7. Swap recovery

The original `/dev/sda3` swap signature had an incompatible page size for the running kernel. `swapon /dev/sda3` reported:

```text
swap format pagesize does not match
```

The Jessie `mkswap` in this environment did **not** support `--fixpgsz`. The working recovery was:

```bash
mkswap -f -p 4096 /dev/sda3
swapon /dev/sda3
swapon --show
```

This recreated a 512 MiB swap area. The resulting UUID was recorded in `/etc/fstab`:

```text
UUID=<new-swap-uuid> none swap sw 0 0
```

Do not copy the old UUID blindly; use the UUID printed by `mkswap` on the actual device.

## 8. Package repository trap on Jessie

Modern `stable` repositories must not be used for a Jessie recovery. Jessie is archived. During setup, `apt-get update` against the archive can still show two expected problems:

- expired Jessie archive signing key
- `jessie-updates` returning 404 because that suite is no longer available there

The useful Jessie package index itself was available from `archive.debian.org/debian/dists/jessie`.

For example, the archive package index exposed Samba 4.2.14 for ARMHF. The final repository configuration should be kept explicitly pinned to Jessie archive content rather than the moving `stable` suite.

## 9. Important lessons from this recovery

1. Never run `e2fsck` on a mounted root filesystem.
2. A busy mount can be caused by bind mounts such as `/dev`, `/proc`, and `/sys`; verify all mounts before unmounting.
3. A read-only `/mnt/data` does not mean the source archive is unusable; `/tmp` was writable and worked for extraction.
4. `cmp` against a larger block device can report EOF at the image length even when the written image is correct.
5. Do not run ARM binaries with `chroot` from an incompatible architecture.
6. Jessie package repositories require archive handling; do not accidentally upgrade the distribution.
7. Keep a working Samba configuration before changing it.
8. Never expose SMB/445 directly to the Internet.
