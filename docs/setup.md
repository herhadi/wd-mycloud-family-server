# Setup Notes

This document records the setup sequence that has been verified on the WD My Cloud Gen1.

## Base system

The device is running Debian Jessie 8.2 on ARMv7l with kernel 3.2.68. The data partition is mounted at `/data`.

## Swap

`/dev/sda3` is a 512 MB swap partition. It was recreated with a 4096-byte page size and added to `/etc/fstab` by UUID.

## Samba

Samba 4.2.14-Debian is installed and running. The initial working configuration exposed a `Family` share mapped to `/data`. The configuration was backed up before changes.

The final design should use separate private shares/directories per family member and shared media areas.

## Syncthing

Syncthing 1.19.2 is installed from a static Linux ARM binary because the Jessie repository does not provide a suitable package. It runs as the dedicated `syncthing` user with state under `/var/lib/syncthing`.

An Android phone using Syncthing-Fork has successfully synchronized photos to the NAS.

## Apt safety

Do not use `stable` as a permanent Jessie source. Debian `stable` changes over time. Jessie sources should use the Debian archive and be treated as legacy infrastructure.

Do not perform general distribution upgrades on this device.

## Remote access

Planned remote access uses the existing domain `tripleatech.my.id`. SMB must not be exposed directly on TCP/445 to the Internet. A secure tunnel or VPN should be used.
