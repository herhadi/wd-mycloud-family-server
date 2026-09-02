# WebDAV + Cloudflare verified deployment

## Scope

This document records the WebDAV and Cloudflare Tunnel state verified on the physical WD My Cloud Gen1.

The canonical family member labels are **Ayah**, **Ibu**, **Anak1**, **Anak2**, and **Anak3**.

## WebDAV

```text
Binary  : /usr/local/bin/webdav
Version : WebDAV v5.15.0
Config  : /etc/webdav/config.yml
Service : webdav.service
Listen  : 0.0.0.0:6065
```

The binary is a static ARM executable from the `github.com/hacdias/webdav/v5` project family.

The production configuration contains credentials and remains on the WD. Do not commit `/etc/webdav/config.yml`, `/etc/webdav/webdav.env`, or real passwords to Git.

## Final filesystem model

The final storage model is:

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

There is no `/data/Private/` directory and no `/opt/webdav/` bind-mount layer in the final implementation.

The five roots outside `Family` are private user areas. The matching account has full access; other family users have no access.

## WebDAV direct-root mapping

Each account uses its private root directly as the WebDAV root. Shared Family directories are exposed inside that root through filesystem bind mounts:

```text
<member> WebDAV root
├── FamilyDocs     → /data/Family/Documents
├── FamilyPhotos   → /data/Family/Photos
├── FamilyShared   → /data/Family/Shared
├── FamilyVideos   → /data/Family/Videos
├── private files/folders
└── ...
```

Canonical member mappings:

```text
Ayah   → /data/Ayah
Ibu    → /data/Ibu
Anak1  → /data/Anak1
Anak2  → /data/Anak2
Anak3  → /data/Anak3
```

There are no `private/` or `family/` virtual directories in the final WebDAV view. The user-facing structure therefore matches the Samba `[homes]` share.

## WebDAV configuration model

The production configuration uses one direct `directory` per account rather than the multi-directory virtual-root feature:

```yaml
users:
  - username: <member>
    password: "{env}WD_<MEMBER>_PASSWORD"
    directory: /data/<member>
```

Production passwords are stored outside Git in:

```text
/etc/webdav/webdav.env
```

The systemd service loads them with:

```ini
EnvironmentFile=/etc/webdav/webdav.env
```

The environment file must remain root-readable only (mode `600`). Do not publish its contents.

## WebDAV permission model

The production configuration uses a global `CRUD` permission with one path-specific read-only exception:

```yaml
permissions: CRUD

rules:
  - regex: ^/FamilyPhotos(/.*)?$
    permissions: R
```

Therefore:

```text
/FamilyDocs/       CRUD
/FamilyShared/     CRUD
/FamilyVideos/     CRUD
/FamilyPhotos/     R only
```

The `FamilyPhotos` rule protects the phone-backup area from normal family-client writes/deletes while allowing Syncthing to write new photos at the filesystem level.

## Verification checkpoint

**Checkpoint: WebDAV direct-root production deployment — verified 2026-09-02.**

The configuration was tested on port `6066` before activation and then tested through `webdav.service` on port `6065`.

Verified:

- Basic Authentication succeeds using the environment-backed password;
- root `PROPFIND` returns `207 Multi-Status`;
- the root exposes `FamilyDocs`, `FamilyPhotos`, `FamilyShared`, and `FamilyVideos` directly;
- there are no `private/` or `family/` virtual directories;
- write to `/FamilyPhotos/` returns `403 Forbidden`;
- write to `/FamilyShared/` returns `201 Created`;
- the WebDAV write-test file was removed after verification;
- `webdav.service` is `active (running)` and `enabled`;
- port `6065` is listening.

## Legacy cleanup checkpoint

The previous WebDAV design used ten bind mounts below `/opt/webdav` and a legacy `/data/Private` structure. These have been removed.

Verified:

```text
/etc/fstab      → no /opt/webdav bind-mount entries
/opt/webdav     → removed
/data/Private   → removed
```

The final `/data` hierarchy is the source of truth.

## Family Photos backup boundary

`/data/Family/Photos` is intentionally different from the other Family directories:

- family users through WebDAV/Samba: **read-only**;
- Syncthing: **write** for photo backup;
- Android photo folders: **Send Only** into the corresponding member folder.

This prevents deletion through normal family file clients while allowing new phone photos to arrive.

## Cloudflare Tunnel

Public hostname:

```text
drive.tripleatech.my.id
```

Tunnel configuration:

```text
/root/.cloudflared/config.yml
```

The Cloudflare tunnel forwards the hostname to local WebDAV on TCP 6065. Tunnel credentials remain on the WD and are never committed to Git.

The active service is:

```text
/etc/systemd/system/cloudflared-mycloud.service
```

Its important dependency is:

```text
network-online.target
        ↓
webdav.service
        ↓
cloudflared-mycloud.service
```

The older `/etc/init.d/cloudflared` implementation is retained only as backup/history and must not be treated as the active startup mechanism.

## Authentication and Cloudflare Access

The WebDAV endpoint uses HTTP Basic Authentication at the WebDAV layer.

Cloudflare Access must not be placed in front of this hostname if it causes redirects that break standard WebDAV methods such as `PROPFIND`.

The verified public test is:

```bash
curl -X PROPFIND \
  -H 'Depth: 0' \
  -u '<WEBDAV_USER>:<WEBDAV_PASSWORD>' \
  https://drive.tripleatech.my.id/
```

Expected result:

```text
HTTP/2 207
Www-Authenticate: Basic realm="Restricted"
```

## Finder verification

macOS Finder has been verified against:

```text
https://drive.tripleatech.my.id
```

Multiple WebDAV accounts were tested successfully through the public hostname.

## Browser behavior

A browser directory request may display raw WebDAV XML beginning with:

```xml
<D:multistatus xmlns:D="DAV:">
```

This is expected. `PROPFIND` must remain a standards-compatible `207 Multi-Status` response because Finder and other WebDAV clients depend on it.

The next implementation step is deliberately narrow:

- ordinary browser `GET` for a directory should render an HTML file/folder listing;
- WebDAV methods such as `PROPFIND`, `OPTIONS`, `HEAD`, and write operations must continue to behave normally.

## Verification commands

On the WD:

```bash
systemctl status webdav.service
systemctl status cloudflared-mycloud.service
ss -lntp | grep ':6065'
mount | grep '/opt/webdav'
```

The final `mount` check should return no `/opt/webdav` entries.

Public endpoint:

```bash
curl -i -X PROPFIND \
  -H 'Depth: 0' \
  -u '<WEBDAV_USER>:<WEBDAV_PASSWORD>' \
  https://drive.tripleatech.my.id/
```

Direct LAN endpoint:

```bash
curl -i -X PROPFIND \
  -H 'Depth: 0' \
  -u '<WEBDAV_USER>:<WEBDAV_PASSWORD>' \
  http://<MYCLOUD_LAN_IP>:6065/
```

Do not publish real passwords, family names, Cloudflare credentials JSON, certificates, or other secrets to Git.
