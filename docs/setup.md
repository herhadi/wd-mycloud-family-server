# Setup Notes

This document records the setup sequence verified for the WD My Cloud Gen1.

## Prerequisites

Read `README.md` first. This project targets WD My Cloud Gen1 / Debian Jessie and is intentionally lightweight.

Before service installation:

- confirm SSH/root access;
- confirm `/dev/sda4` is the intended data disk and is mounted at `/data`;
- confirm 512 MB swap on `/dev/sda3`;
- preserve existing service configuration before replacement;
- do not perform a Debian distribution upgrade;
- do not expose SMB/445 or the Syncthing GUI/8384 to the public Internet;
- keep credentials, API keys, device secrets and family data outside Git.

## Naming rule

Repository documentation uses generic family-role labels only:

```text
Ayah  = live Abi
Ibu   = live Umi
Anak1 = live Adzra
Anak2 = live Adel
Anak3 = live Afzal
```

These are documentation aliases. The live My Cloud accounts and directories retain the real names `Abi`, `Umi`, `Adzra`, `Adel`, and `Afzal`.

## Base system

The device runs Debian Jessie 8.2 on ARMv7l with kernel 3.2.68. The data partition is mounted at `/data`.

## Storage layout

The repository/documentation model is:

```text
/data/
├── Family/
│   ├── Documents/
│   ├── Photos/
│   │   ├── Ayah/       # live: Abi
│   │   ├── Ibu/        # live: Umi
│   │   ├── Anak1/      # live: Adzra
│   │   ├── Anak2/      # live: Adel
│   │   └── Anak3/      # live: Afzal
│   ├── Shared/
│   └── Videos/
├── Ayah/              # live: Abi
├── Ibu/               # live: Umi
├── Anak1/             # live: Adzra
├── Anak2/             # live: Adel
└── Anak3/             # live: Afzal
```

There is no `/data/Private/` directory. The five live directories directly under `/data` are private roots for the corresponding family members.

## Permission model

The private roots are isolated:

- the owner has full read/write/delete access;
- other family users have no access;
- files and directories created inside a user's root must inherit that user's ownership/permissions.

`/data/Family` is shared, with permissions determined by each subdirectory's purpose.

`/data/Family/Documents`, `/data/Family/Shared`, and `/data/Family/Videos` are read/write for family users. `/data/Family/Photos` is read-only for family users while the `syncthing` service account can write synchronized photos.

## Swap

`/dev/sda3` is a 512 MB swap partition. It was recreated with a 4096-byte page size and added to `/etc/fstab` by UUID.

## Samba

Samba 4.2.14-Debian is installed and running. SMB is the primary local file interface for Finder/Explorer.

The verified private-user model uses `[homes]` so an authenticated user opens the matching live private root directly. Family virtual folders are presented inside the private root through the verified filesystem bind mounts.

Do not expose SMB/TCP 445 directly to the Internet.

## Syncthing

Syncthing v2.1.3 is installed from a static Linux ARM binary because the Jessie repository does not provide a suitable package. It runs as the dedicated `syncthing` user with state under `/var/lib/syncthing`.

### Photo backup model

The intended model is explicitly one-way:

```text
Android phone                 WD My Cloud
Send Only  ────────────────>  Receive Only
                                  |
                                  v
                         /data/Family/Photos/<live member>
```

The live paths are:

```text
Ayah  → /data/Family/Photos/Abi
Ibu   → /data/Family/Photos/Umi
Anak1 → /data/Family/Photos/Adzra
Anak2 → /data/Family/Photos/Adel
Anak3 → /data/Family/Photos/Afzal
```

The first configured phone is Poco F7 and its live target is `/data/Family/Photos/Abi`.

### Android configuration

On the phone:

1. Add/edit the folder containing the photos.
2. Select the real Android photo directory.
3. Share it with the MyCloud device.
4. Set the folder type to **Send Only**.
5. Keep the original photos on the phone until the server copy has been verified.

### MyCloud web-GUI configuration

On the MyCloud Syncthing GUI at LAN TCP 8384:

1. Accept/add the shared phone folder.
2. Set the local path to the corresponding live `/data/Family/Photos/<member>` directory.
3. Confirm the phone device is shared.
4. Initialize the folder and verify `.stfolder` is created by Syncthing.
5. After the initial transfer is confirmed, set the MyCloud folder type to **Receive Only**.

The `syncthing` service account must be able to write to the receive directory. Do not create `.stfolder` manually.

### Verification

```bash
find /data/Family/Photos/Abi -type f | wc -l
du -sh /data/Family/Photos/Abi
```

The Syncthing GUI should report the folder as up to date after the transfer completes.

For detailed phone and web-GUI instructions, recovery rules, and troubleshooting, see `docs/syncthing.md`.

## WebDAV

WebDAV v5.15.0 is installed as `/usr/local/bin/webdav` and listens on TCP 6065 through `webdav.service`.

Each WebDAV account is logically presented with its own private root plus the shared `Family` tree:

```text
<member>
├── private  → live /data/<member>
└── family   → /data/Family
```

Documentation-role mappings:

```text
Ayah  → live /data/Abi
Ibu   → live /data/Umi
Anak1 → live /data/Adzra
Anak2 → live /data/Adel
Anak3 → live /data/Afzal
```

`private` is only a logical WebDAV label; there is no physical `/data/Private/` directory and no `/opt/webdav` bind-mount layer.

The global WebDAV permission is `CRUD`, except `/family/Photos` which is `R` through a path-specific rule.

The public hostname is `drive.tripleatech.my.id`, published through the Cloudflare Tunnel service `cloudflared-mycloud.service`.

## Remote access

SMB must not be exposed directly on TCP/445 to the Internet. Remote file access uses the WebDAV service through the Cloudflare Tunnel.

Cloudflare Access must not be placed in front of the WebDAV hostname if it causes redirects that break standard WebDAV methods such as `PROPFIND`.

## Apt safety

Do not use `stable` as a permanent Jessie source. Jessie sources should use the Debian archive and be treated as legacy infrastructure.

Do not perform general distribution upgrades on this device.

## Documentation rule

Use `Ayah`, `Ibu`, `Anak1`, `Anak2`, and `Anak3` in repository documentation as role aliases. Never infer that those aliases are the real live account/directory names. The live names remain `Abi`, `Umi`, `Adzra`, `Adel`, and `Afzal`.
