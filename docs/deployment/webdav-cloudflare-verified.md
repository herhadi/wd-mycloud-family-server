# WebDAV + Cloudflare verified deployment

## Scope

This document records the WebDAV and Cloudflare Tunnel state verified on the physical WD My Cloud Gen1 before custom WebDAV binary development.

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

## WebDAV virtual roots

Each account receives its own virtual root containing only `Private` and `Family`:

| Login | Virtual root | Private source | Family source |
|---|---|---|---|
| `abi` | `/opt/webdav/abi` | `/data/Private/Abi` | `/data/Family` |
| `umi` | `/opt/webdav/umi` | `/data/Private/Umi` | `/data/Family` |
| `anak1` | `/opt/webdav/adzra` | `/data/Private/Adzra` | `/data/Family` |
| `anak2` | `/opt/webdav/adel` | `/data/Private/Adel` | `/data/Family` |
| `anak3` | `/opt/webdav/afzal` | `/data/Private/Afzal` | `/data/Family` |

The ten backing bind mounts are recorded in `/etc/fstab` and are verified with `mount -a`.

This design prevents a WebDAV user from browsing another user's private directory while retaining access to the shared family tree.

## Cloudflare Tunnel

Public hostname:

```text
drive.tripleatech.my.id
```

Tunnel configuration:

```text
/root/.cloudflared/config.yml
```

The Cloudflare tunnel forwards the hostname to local WebDAV on TCP 6065. The tunnel ID is intentionally omitted from this document because it is not necessary to reproduce the service configuration.

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
  -u 'abi:<WEBdav_PASSWORD>' \
  https://drive.tripleatech.my.id/
```

Expected result:

```text
HTTP/2 207
Www-Authenticate: Basic realm="Restricted"
```

The same authenticated `PROPFIND` was also verified directly against the LAN WebDAV listener.

## Finder verification

macOS Finder has been verified against:

```text
https://drive.tripleatech.my.id
```

At least two WebDAV accounts were tested successfully through the public hostname.

## Browser behavior

A browser directory request may display raw WebDAV XML beginning with:

```xml
<D:multistatus xmlns:D="DAV:">
```

This is expected. `PROPFIND` must remain a standards-compatible `207 Multi-Status` response because Finder and other WebDAV clients depend on it.

The next implementation step is therefore deliberately narrow:

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
  -u 'abi:<WEBdav_PASSWORD>' \
  https://drive.tripleatech.my.id/
```

Direct LAN endpoint:

```bash
curl -i -X PROPFIND \
  -H 'Depth: 0' \
  -u 'abi:<WEBdav_PASSWORD>' \
  http://<MYCLOUD_LAN_IP>:6065/
```

Do not publish the real password, Cloudflare credentials JSON, certificates, or other secrets to Git.
