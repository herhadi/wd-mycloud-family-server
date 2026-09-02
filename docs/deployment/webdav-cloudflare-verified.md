# WebDAV + Cloudflare verified deployment

## Scope

This document records the WebDAV, Browser Gateway, and Cloudflare Tunnel state verified on the physical WD My Cloud Gen1.

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

## WebDAV verification checkpoint

**Checkpoint: WebDAV direct-root production deployment — verified 2026-09-02.**

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

## Browser Gateway

The Browser Gateway is a thin local HTTP gateway in front of WebDAV:

```text
Browser / WebDAV client
          |
          v
Browser Gateway :6066
          |
          v
WebDAV :6065
          |
          v
/data/<member>
```

Runtime:

```text
Binary  : /usr/local/bin/webdav-gw
Service : webdav-gw.service
Listen  : 127.0.0.1:6066
```

The binary is a static ARMv7 executable. It has been tested natively on the My Cloud and is managed by systemd with automatic startup.

For ordinary browser `GET` requests to directories, the gateway performs an authenticated WebDAV `PROPFIND`, parses the response, and renders a human-friendly HTML listing. Non-GET WebDAV methods and file requests continue to the underlying WebDAV service.

The browser UI hides common macOS/Syncthing internal files and provides basic file-type icons, directory-first sorting, breadcrumbs, Home/Back controls, and file sizes. This presentation filtering does not delete or modify files.

Verified locally on the My Cloud:

```text
127.0.0.1:6066 → HTTP 401 on initial unauthenticated request
127.0.0.1:6066 → HTTP 200 after Basic Authentication
response        → HTML Browser UI
```

The gateway must remain bound to `127.0.0.1`; TCP 6066 must not be exposed directly to the Internet.

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

The tunnel configuration is currently prepared to forward the hostname to the Browser Gateway on `127.0.0.1:6066`. The Cloudflare tunnel credentials remain on the WD and are never committed to Git.

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

### Cloudflared ingress validation

For the `cloudflared` version installed on the WD, the `--config` flag must appear before the `ingress validate` subcommand.

Use:

```bash
/usr/local/bin/cloudflared tunnel --config /root/.cloudflared/config.yml ingress validate
```

The following ordering is **not valid for this installed version**:

```bash
/usr/local/bin/cloudflared tunnel ingress validate --config /root/.cloudflared/config.yml
```

Verified result after changing the tunnel upstream to `6066`:

```text
Validating rules from /root/.cloudflared/config.yml
OK
```

Cloudflare's current documentation also describes the ingress command as `cloudflared tunnel [--config FILEPATH] ingress validate`. citeturn0search0turn0search1

### Cloudflare change safety

Before changing `/root/.cloudflared/config.yml`, create a timestamped backup:

```bash
cp /root/.cloudflared/config.yml \
   /root/.cloudflared/config.yml.backup-$(date +%Y%m%d-%H%M%S)
```

Validate the edited configuration before restarting the tunnel:

```bash
/usr/local/bin/cloudflared tunnel --config /root/.cloudflared/config.yml ingress validate
```

Do not expose TCP 6066 directly. The intended public path is:

```text
drive.tripleatech.my.id
        ↓
Cloudflare Tunnel
        ↓
127.0.0.1:6066
        ↓
127.0.0.1:6065
```

## Authentication and Cloudflare Access

The WebDAV endpoint uses HTTP Basic Authentication at the WebDAV layer.

Cloudflare Access must not be placed in front of this hostname if it causes redirects that break standard WebDAV methods such as `PROPFIND`.

The public WebDAV verification command remains:

```bash
curl -X PROPFIND \
  -H 'Depth: 0' \
  -u '<WEBDAV_USER>:<WEBDAV_PASSWORD>' \
  https://drive.tripleatech.my.id/
```

When the public hostname is routed through the Browser Gateway, ordinary browser `GET` directory requests should return HTML while WebDAV clients continue using WebDAV methods through the gateway.

## Finder verification

macOS Finder has been verified against:

```text
https://drive.tripleatech.my.id
```

Multiple WebDAV accounts were tested successfully through the public hostname before the Browser Gateway change.

After switching Cloudflare to the Browser Gateway, Finder must be re-tested because the gateway is intended to preserve WebDAV semantics while adding browser HTML rendering.

## Verification commands

On the WD:

```bash
systemctl status webdav.service
systemctl status webdav-gw.service
systemctl status cloudflared-mycloud.service
ss -lntp | grep -E ':6065|:6066'
```

Expected listeners:

```text
0.0.0.0:6065    WebDAV
127.0.0.1:6066  Browser Gateway
```

Direct local Browser Gateway test:

```bash
wget --user=<WEBDAV_USER> --ask-password \
  -O /tmp/gw-test.html \
  http://127.0.0.1:6066/
```

The response should authenticate and return HTML.

Do not publish real passwords, family names, Cloudflare credentials JSON, certificates, or other secrets to Git.
