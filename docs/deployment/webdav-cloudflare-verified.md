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

The production configuration contains credentials and remains on the WD. Do not commit `/etc/webdav/config.yml` or real passwords to Git.

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

## WebDAV logical mapping

Each account receives two logical roots:

```text
<member>
├── private  → /data/<member>
└── family   → /data/Family
```

Canonical member mappings:

```text
Ayah   → /data/Ayah
Ibu    → /data/Ibu
Anak1  → /data/Anak1
Anak2  → /data/Anak2
Anak3  → /data/Anak3
```

`private` is only a WebDAV logical label. It does not correspond to a physical `/data/Private` directory.

## WebDAV permission model

The production configuration uses a global `CRUD` permission with one path-specific read-only exception:

```yaml
permissions: CRUD

rules:
  - regex: ^/family/Photos(/.*)?$
    permissions: R
```

Therefore:

```text
/private/              CRUD, matching member only
/family/Documents/     CRUD
/family/Shared/        CRUD
/family/Videos/        CRUD
/family/Photos/        R only
```

## Verification checkpoint

**Checkpoint: WebDAV production service — verified 2026-09-01.**

The configuration was tested on port `6066` before activation and then tested through `webdav.service` on port `6065`.

Verified:

- upload to `/family/Photos/` returns `403 Forbidden`;
- upload to `/family/Documents/` returns `201 Created`;
- all five private roots accept uploads for their matching account;
- cross-user private access returns `404 Not Found`;
- deletion from a writable Family document returns `204 No Content`;
- `webdav.service` is `active (running)` and `enabled`;
- port `6065` listens after reboot.

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
