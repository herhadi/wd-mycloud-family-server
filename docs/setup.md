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
- do not expose SMB/445 or Syncthing GUI/8384 to the public Internet;
- keep credentials, API keys, device secrets, family names, and family data outside Git.

## Naming and portability

Repository documentation uses generic family-role labels only:

```text
Ayah
Ibu
Anak1
Anak2
Anak3
```

These labels are aliases representing roles. They are not fixed personal names. A deployment may use any private family names or directory names locally. Private names must not be added to the public repository.

## Base system

The device runs Debian Jessie 8.2 on ARMv7l with kernel 3.2.68. The data partition is mounted at `/data`.

## Storage layout

The generic family model is:

```text
/data/
├── Family/
│   ├── Documents/
│   ├── Photos/
│   │   ├── Ayah/
│   │   ├── Ibu/
│   │   ├── Anak1/
│   │   ├── Anak2/
│   │   └── Anak3/
│   ├── Shared/
│   └── Videos/
├── Ayah/
├── Ibu/
├── Anak1/
├── Anak2/
└── Anak3/
```

There is no `/data/Private/` directory in the final model.

## Permission model

The private roots are isolated:

- the matching member has full read/write/delete access;
- other family users have no access to another member's root;
- files and directories created inside a user's root must inherit that user's ownership/permissions.

`/data/Family` is shared, with permissions determined by each subdirectory's purpose.

`/data/Family/Documents`, `/data/Family/Shared`, and `/data/Family/Videos` are read/write for family users. `/data/Family/Photos` is read-only for family users while the `syncthing` service account can write synchronized photos.

## Swap

`/dev/sda3` is a 512 MB swap partition. It was recreated with a 4096-byte page size and added to `/etc/fstab` by UUID.

## Samba

Samba 4.2.14-Debian is installed and running. SMB is the primary local file interface for Finder/Explorer.

The verified private-user model uses `[homes]` so an authenticated user opens the matching private root directly. Family virtual folders are presented according to the live Samba configuration.

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
                         /data/Family/Photos/<member>
```

The generic destinations are:

```text
/data/Family/Photos/Ayah
/data/Family/Photos/Ibu
/data/Family/Photos/Anak1
/data/Family/Photos/Anak2
/data/Family/Photos/Anak3
```

The phone-side photo folder is configured as **Send Only**. The MyCloud destination is configured as **Receive Only** after initial synchronization is verified.

See `docs/syncthing.md` for the complete Android and MyCloud Web-GUI procedure.

## WebDAV

WebDAV v5.15.0 is installed as `/usr/local/bin/webdav` and listens on TCP 6065 through `webdav.service`.

Each WebDAV account is logically presented with its own private root plus the shared `Family` tree:

```text
<member>
├── private  → /data/<member>
└── family   → /data/Family
```

`private` is only a logical WebDAV label; there is no physical `/data/Private/` directory and no `/opt/webdav` bind-mount layer in the final model.

The global WebDAV permission is `CRUD`, except `/family/Photos` which is `R` through a path-specific rule.

The public hostname is `drive.tripleatech.my.id`, published through the Cloudflare Tunnel service `cloudflared-mycloud.service`.

## Remote access

SMB must not be exposed directly on TCP/445 to the Internet. Remote file access uses the WebDAV service through the Cloudflare Tunnel.

Cloudflare Access must not be placed in front of the WebDAV hostname if it causes redirects that break standard WebDAV methods such as `PROPFIND`.

## Apt safety

Do not use `stable` as a permanent Jessie source. Jessie sources should use the Debian archive and be treated as legacy infrastructure.

Do not perform general distribution upgrades on this device.

## Documentation rule

Use only the generic family-role aliases `Ayah`, `Ibu`, `Anak1`, `Anak2`, and `Anak3` in repository documentation, diagrams, examples, and templates. Never publish real family names or other personal identifiers. A different family may freely replace these aliases in its own private/local configuration.
