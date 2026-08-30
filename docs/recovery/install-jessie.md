# WD My Cloud Gen1: Recovery and Clean Debian Jessie

This document records the recovery path that was actually used to bring a bricked WD My Cloud Gen1 back to a booting Debian Jessie system, then turns it into a repeatable clean-install procedure.

> **Warning:** This procedure writes directly to disk partitions. Verify the disk device before every `dd`, `parted`, `mkfs`, `mkswap`, or RAID command. A wrong device can destroy another disk.

## Scope

Target platform:

- WD My Cloud Gen1
- ARMv7 / armhf
- GPT disk layout used by the Gen1 platform
- Debian Jessie 8.x clean root filesystem

The working device currently has:

```text
sda1 + sda2  -> md0 RAID1 -> /
sda3         -> swap
sda4         -> /data
sda5 + sda6  -> kernel slots
sda7 + sda8  -> config slots
```

The public reference procedure uses the same Gen1 image layout and writes `kernel.img` to partitions 5/6, `config.img` to 7/8, and `rootfs.img` to `/dev/md0`. See the external references at the end of this document.

---

# Stage 1 — Recover a Bricked Existing Disk

Use this stage when the HDD already has the correct Gen1 partition layout and the goal is to restore bootable Debian Jessie without repartitioning the whole disk.

## 1. Boot a Linux rescue environment

Connect the WD HDD to another Linux system. Do **not** assume the disk is `/dev/sda` or `/dev/sdb`.

Identify it first:

```bash
lsblk
sudo fdisk -l
```

For the recovery performed in this project, the WD disk was `/dev/sda` on the rescue environment.

## 2. Assemble the Gen1 root RAID

If no `/dev/md0` exists:

```bash
mdadm --assemble /dev/md0 /dev/sda1 /dev/sda2
```

Expected result:

```text
mdadm: /dev/md0 has been started with 2 drives.
```

Verify:

```bash
cat /proc/mdstat
```

Expected healthy state:

```text
md0 : active raid1 sda1[0] sda2[1]
      ... blocks [2/2] [UU]
```

If the system auto-assembled a different md device (for example `/dev/md127`), stop the wrong automatic assembly and explicitly assemble `/dev/md0` before continuing.

## 3. Mount the root filesystem only when needed

```bash
mkdir -p /mnt/wdroot
mount /dev/md0 /mnt/wdroot
```

Check that it is the expected Debian filesystem:

```bash
cat /mnt/wdroot/etc/passwd | head
```

The expected root entry looks like:

```text
root:x:0:0:root:/root:/bin/bash
```

## 4. Unmount before filesystem checks

Before running `e2fsck`, make sure `/dev/md0` is not mounted:

```bash
umount /mnt/wdroot
```

If `umount` says `target is busy`, inspect mounts:

```bash
mount | grep -E 'wdroot|md0'
```

The recovery encountered additional mounts under the root filesystem:

```text
devtmpfs on /mnt/wdroot/dev
none on /mnt/wdroot/proc
none on /mnt/wdroot/sys
```

Unmount those first, or use the appropriate recursive/lazy unmount only after confirming the target is the temporary rescue mount:

```bash
umount /mnt/wdroot/dev
umount /mnt/wdroot/proc
umount /mnt/wdroot/sys
umount /mnt/wdroot
```

Then verify:

```bash
mount | grep -E 'wdroot|md0'
```

No output means the filesystem is unmounted.

## 5. Check the filesystem

Read-only check:

```bash
e2fsck -fn /dev/md0
```

Do not ignore the warning if it says the device is mounted. Unmount it first and repeat the check.

The recovered system reported clean filesystem checks through all five passes.

---

# Stage 2 — Install Clean Debian Jessie From Zero

Use this stage when the existing root filesystem is unusable and you want to restore the Gen1 disk from a clean Debian Jessie image.

## 1. Preserve `/data` if it contains user data

The Gen1 layout normally puts user data on partition 4. If the existing `/dev/sda4` is healthy and contains important files, **do not format it**.

Mount it read-only first when assessing it:

```bash
mkdir -p /mnt/data-check
mount -o ro /dev/sda4 /mnt/data-check
ls -lah /mnt/data-check
umount /mnt/data-check
```

Only format partition 4 if you intentionally want to erase the data disk.

## 2. Verify the partition layout

For a normal Gen1 disk, confirm:

```bash
lsblk
```

The expected arrangement is approximately:

```text
sda1  2G    RAID
sda2  2G    RAID
sda3  512M  swap
sda4  rest  ext4 data
sda5  100M  kernel
sda6  100M  kernel
sda7  2M    config
sda8  2M    config
```

If the layout is missing or badly damaged, use the partitioning procedure for the Gen1 platform before continuing. **Do not blindly copy this table to a different My Cloud generation.**

## 3. Prepare the RAID root

If the partitions are already members of the Gen1 RAID and contain stale/automatic assembly metadata, stop any automatically assembled md device first.

For a new RAID root, the known Gen1 procedure is:

```bash
mdadm --create /dev/md0 --level=1 --metadata=0.9 --raid-devices=2 /dev/sda1 /dev/sda2
```

Check:

```bash
cat /proc/mdstat
```

Wait for the RAID to reach `[UU]`/100% synchronization when performing a fresh array creation, unless you deliberately know that the image-writing procedure is safe for the current state.

If the array already exists and is healthy, use assembly instead:

```bash
mdadm --assemble /dev/md0 /dev/sda1 /dev/sda2
```

Do not create a new array over an existing data-bearing RAID without first confirming what is on it.

## 4. Obtain Clean Debian Jessie

The clean Jessie archive used in this project was:

```text
clean-debian-jessie.tgz
```

The archive contains at least:

```text
kernel.img
config.img
rootfs.img
```

A public historical reference for the Gen1 Clean Debian procedure is linked below. Keep a local copy of the exact archive used for recovery; do not depend on a future mirror remaining unchanged.

## 5. Use `/tmp` for extracted kernel/config files when `/data` is read-only

This was an important practical issue during recovery.

An attempt to extract `kernel.img` and `config.img` directly into `/mnt/data/debian-jessie` failed with:

```text
Read-only file system
```

Even though `/data` had plenty of free space.

The reliable workaround is:

```bash
cd /tmp
rm -f kernel.img config.img rootfs.img
tar -xzf /mnt/data/clean-debian-jessie.tgz kernel.img config.img rootfs.img
ls -lh /tmp/kernel.img /tmp/config.img /tmp/rootfs.img
```

If the archive is on another filesystem, adjust the archive path accordingly.

## 6. Verify image architecture before writing

At minimum:

```bash
file /tmp/kernel.img
```

The image sizes should be plausible for the archive being used. Do not substitute arbitrary kernel/config images from another My Cloud generation.

## 7. Write kernel and config images

For the Gen1 layout:

```bash
dd if=/tmp/kernel.img of=/dev/sda5 bs=64K conv=fsync status=progress
dd if=/tmp/kernel.img of=/dev/sda6 bs=64K conv=fsync status=progress

dd if=/tmp/config.img of=/dev/sda7 bs=512 conv=fsync status=progress
dd if=/tmp/config.img of=/dev/sda8 bs=512 conv=fsync status=progress
```

Then:

```bash
sync
```

### About `cmp`

This is **not** a valid reason to expect an exact-size match:

```bash
cmp /tmp/kernel.img /dev/sda5
```

`/dev/sda5` is a block device larger than the image. `cmp` therefore commonly reports:

```text
cmp: EOF on /tmp/kernel.img after byte ...
```

The important check is that `dd` completed successfully and that the written byte count matches the source image size. Do not interpret the normal EOF message as a failed write by itself.

## 8. Write the root filesystem image

Make sure `/dev/md0` is **not mounted** before writing:

```bash
mount | grep -E 'md0|wdroot'
```

There should be no output for the target.

Then:

```bash
dd if=/mnt/data/debian-jessie/rootfs.img of=/dev/md0 bs=64K conv=fsync status=progress
sync
```

The exact path to `rootfs.img` may differ. Verify it first:

```bash
ls -lh /mnt/data/debian-jessie/rootfs.img
```

**This command overwrites the root RAID filesystem. Never point it at `/dev/sda4`.**

## 9. Verify the new root filesystem

After the write finishes:

```bash
e2fsck -fn /dev/md0
```

Do not run the check while `/dev/md0` is mounted.

## 10. Optional root inspection

If you need to inspect the restored root:

```bash
mkdir -p /mnt/wdroot
mount /dev/md0 /mnt/wdroot
cat /mnt/wdroot/etc/passwd | head
```

Then unmount cleanly before shutting down the rescue environment:

```bash
umount /mnt/wdroot
sync
```

## 11. Shut down the rescue system cleanly

Do not simply remove the HDD while it is mounted or while writes are pending.

```bash
sync
```

Then shut down the rescue computer normally and disconnect the WD HDD only after it has powered down.

## 12. Return the HDD to the My Cloud

Reconnect the HDD to the WD My Cloud Gen1 board, attach Ethernet and power, and wait several minutes.

A successful clean Jessie boot should eventually provide network connectivity and SSH.

Find the assigned IP from the router/DHCP server, then:

```bash
ssh root@<WD-IP>
```

Historical Clean Debian Jessie instructions report the initial root password as:

```text
mycloud
```

Change it immediately after first login. Never put the new password in this repository.

---

# Post-install: First Boot Checklist

Immediately verify:

```bash
uname -a
uname -m
cat /etc/debian_version
free -m
df -h
ip addr
cat /proc/mdstat
```

Then verify `/data`:

```bash
mount | grep /data
df -h /data
ls -lah /data
```

## Swap

The original recovery initially had a swap page-size mismatch. The working fix was to recreate the swap with the kernel's 4096-byte page size:

```bash
mkswap -f -p 4096 /dev/sda3
swapon /dev/sda3
swapon --show
```

Then persist the **new UUID** in `/etc/fstab`:

```bash
blkid /dev/sda3
```

Example format:

```text
UUID=<new-uuid> none swap sw 0 0
```

Do not copy an old UUID after `mkswap` has recreated the filesystem.

---

# Jessie APT: Important

Debian Jessie is end-of-life. Normal current Debian mirrors will not provide Jessie packages reliably.

The working environment therefore uses the Debian archive rather than current `stable` repositories.

Typical archive entries are:

```text
deb http://archive.debian.org/debian jessie main contrib non-free
```

Do not blindly copy modern Debian repository instructions to Jessie.

The archive may also produce an expired signing-key warning. Do not solve that by upgrading the entire system to a newer Debian release; this WD Gen1 installation depends on its old kernel/platform.

Also note that `jessie-updates` is not available at the same archive path in the way a current Debian `*-updates` repository is. A stale `jessie-updates` entry can cause 404 errors during `apt-get update`.

---

# Known Problems Encountered During This Recovery

## `umount: target is busy`

Cause: `/dev/md0` had `/dev`, `/proc`, and `/sys` mounted below `/mnt/wdroot`.

Fix: inspect with:

```bash
mount | grep -E 'wdroot|md0'
```

Unmount the child mounts, then the root mount.

## `e2fsck: Warning! /dev/md0 is mounted`

Cause: the root filesystem was still mounted.

Fix: unmount it first and rerun:

```bash
e2fsck -fn /dev/md0
```

## `tar: Read-only file system`

Cause: extraction was attempted under a read-only `/data` path.

Fix: extract temporary boot/config files under `/tmp` instead.

## `cmp` reports EOF on the image

Cause: comparing a short image file to a larger block device.

Fix: do not use raw `cmp` this way as the primary verification. Compare the image size to the successful `dd` byte count.

## `chroot ... Exec format error`

Cause: a WD root filesystem is ARM and the rescue host may be a different CPU architecture. Running an ARM binary from the mounted root with `chroot` on an x86 host fails without an ARM emulator.

Do not use `chroot` merely to change the root password. A safer recovery method is to modify the target filesystem using tools that run on the rescue host, or boot the WD and change the password from the target system.

## Root password confusion

Clean Debian Jessie has historically used `mycloud` as the initial root password. This is **not necessarily the password used by an existing installation**, and it is not the Samba password. Samba passwords are separate credentials.

## Syncthing certificate errors

The old Jessie CA bundle can be too old for modern TLS certificate chains. A Syncthing log such as:

```text
x509: certificate signed by unknown authority
```

may appear even when `/etc/ssl/certs/ca-certificates.crt` exists. This is a compatibility problem with the old OS trust store, not proof that Syncthing itself is corrupt.

## Syncthing QUIC receive-buffer warning

A warning about UDP receive buffers being smaller than requested does not necessarily prevent synchronization. If Syncthing reaches `Ready to synchronize` and completes the initial scan, continue monitoring actual transfers before changing kernel/network settings.

---

# Recovery Safety Rules

1. **Never assume `/dev/sda` is the WD disk.**
2. Never write `rootfs.img` to `/dev/sda4`.
3. Never format `/dev/sda4` unless you intentionally want to erase user data.
4. Unmount `/dev/md0` before filesystem checks or rootfs replacement.
5. Run `sync` before disconnecting storage.
6. Keep a copy of the exact Clean Debian archive used.
7. Do not put passwords or private keys in Git.
8. Avoid `apt-get upgrade` on this legacy Jessie system unless the exact consequences have been tested.
9. Test recovery commands on a spare disk whenever possible.
10. After recovery, verify `/data` before creating or deleting user folders.

---

# References

- Historical Clean Debian Jessie Gen1 installation notes: https://abskmj.github.io/notes/posts/wd-mycloud/install-debian-wdmycloud/
- WD Community recovery discussion: https://community.wd.com/t/unbrick-mycloud-once-and-for-all-lets-make-a-clear-tutorial-for-everyone/237772
- WD Community Gen1 replacement/recovery discussion: https://community.wd.com/t/replace-hdd-in-mycloud-gen1/260474
- Fox-exe Gen1 recovery notes: https://fox-exe.ru/WDMyCloud/WDMyCloud-Gen1/Unbrick_tftp.html

These references are supporting material. The commands and troubleshooting above also document the actual recovery experience used for this project.
