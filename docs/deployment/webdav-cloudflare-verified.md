# WebDAV + Cloudflare verified deployment

## Scope

This document records the WebDAV and Cloudflare Tunnel state verified on the physical WD My Cloud Gen1 before custom WebDAV binary development.

Repository documentation uses generic member labels only. Real family names and usernames are configured on the live server and must never be committed here.

## WebDAV

```text
Binary  : /usr/local/bin/webdav
Version : WebDAV v5.15.0
Config  : /etc/webdav/config.yml
Service : webdav.service
Listen  : 0.0.0.0:6065
```

The binary is a static ARM executable from the `github.com/hacdias/webdav/v5` project family.

Production configuration must not be committed because it may contain credentials. Keep `/etc/webdav/config.yml` on the device and use placeholders in repository examples.

## Real filesystem model

The final storage model does **not** use `/data/Private/`.

Repository examples use generic member labels only:

```text
/data/
├── Family/
│   ├── Documents/
│   ├── Photos/
│   │   ├── <member-1>/
│   │   ├── <member-2>/
│   │   ├── <member-3>/
│   │   ├── <member-4>/
│   │   └── <member-5>/
│   ├── Shared/
│   └── Videos/
├── <member-1>/
├── <member-2>/
├── <member-3>/
├── <member-4>/
└── <member-5>/
```

The five roots outside `Family` are private user areas. The matching live-server account has full access; other family users have no access. Newly created files/directories inside each user's root must inherit that user's ownership/permissions.

## WebDAV virtual roots

The WebDAV view gives each account access to its own private root plus the shared `Family` tree. `Private` is a **virtual WebDAV label**, not a physical `/data/Private` directory.

Logical mapping in repository documentation:

```text
<member-1> -> /data/<member-1>
<member-2> -> /data/<member-2>
<member-3> -> /data/<member-3>
<member-4> -> /data/<member-4>
<member-5> -> /data/<member-5>
```

The production WebDAV implementation may use `/opt/webdav/<login>` bind mounts to construct the virtual view. Real login-to-directory mappings remain on the live server and are intentionally excluded from this repository.

## Family/Photos permission exception

`/data/Family/Photos` is intentionally different from the private roots:

- family users: **read-only**;
- Syncthing: **write** for photo backup;
- Android photo folders: **Send Only**.

This prevents an accidental deletion through a family client from deleting the source photo dataset while still allowing Syncthing to receive new photos.

Other `Family` subdirectories may have different purpose-specific permissions. `Family/Shared` can be read/write for family users when configured that way.

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

During testing, Cloudflare Access on the public hostname returned an HTTP 302 login response to `PROPFIND`. That behavior is unsuitable for normal Finder/WebDAV interoperability, so Access was removed from this hostname.

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
