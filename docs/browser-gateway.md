# Browser UI Gateway

## Purpose

The browser gateway provides a human-friendly HTML directory view while keeping WebDAV as the actual file-service backend.

It is intentionally a thin, lightweight native Go program suitable for the WD My Cloud Gen1 ARMv7 environment.

## Architecture

```text
Browser
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

The gateway listens on `127.0.0.1:6066`. WebDAV remains on `0.0.0.0:6065`.

The Cloudflare Tunnel is not changed until the gateway has been verified locally.

## Request handling

For ordinary browser `GET` requests:

1. The gateway forwards the browser `Authorization` header to an upstream WebDAV `PROPFIND` request.
2. It requests `Depth: 1`.
3. A `207 Multi-Status` response is parsed as WebDAV XML.
4. Directory entries are rendered as HTML.
5. If the requested resource is not a directory, the original `GET` is reverse-proxied unchanged.

For all non-GET methods, the gateway reverse-proxies the request directly to WebDAV. This preserves WebDAV operations such as `PROPFIND`, `OPTIONS`, `PUT`, `DELETE`, `MKCOL`, `MOVE`, `COPY`, `LOCK`, and `UNLOCK`.

## UI v1

Verified local UI v1 features:

- Home navigation
- Back navigation
- Current-path breadcrumb
- Directory-first sorting
- File sizes from WebDAV metadata
- Folder icon
- File-type icons for images, video, audio, documents, spreadsheets, presentations and archives
- Browser-only hiding of common internal files:
  - `.DS_Store`
  - `._*`
  - `.stfolder`
  - `.temp`
  - `.stversions`
  - `.trashed-*`
  - `.trash*`
  - `.mace_*`

The hidden files are not deleted or modified. Filtering applies only to the HTML browser view.

## Build and local test

Development/build is performed on Ubuntu x86_64. The WD My Cloud target is Linux ARMv7.

Native test build:

```bash
cd ~/wd-mycloud-family-server/gateway
go build -o webdav-gw-test .
WEBDAV_URL=http://<mycloud-lan-ip>:6065 ./webdav-gw-test
```

Cross-build for the WD:

```bash
cd ~/wd-mycloud-family-server/gateway
GOOS=linux GOARCH=arm GOARM=7 go build -o webdav-gw .
```

The browser is then tested locally at:

```text
http://127.0.0.1:6066/
```

Verify authentication, root listing, folder navigation, file links, Home, Back, file-type icons and internal-file filtering before any production deployment.

## Deployment boundary

Do not expose SMB/TCP 445 or Syncthing GUI TCP 8384 through the public tunnel.

Do not replace WebDAV `:6065` until the gateway has passed local verification.

When the gateway is later deployed as a service, it should remain bound to localhost and the Cloudflare Tunnel should be the only public path to the browser UI.

## UI roadmap

UI v1 is the verified directory browser only.

Planned UI v2 work starts with image preview, followed by other file actions such as video preview, upload, folder creation, delete and rename. Each feature must preserve the underlying WebDAV semantics and be verified locally before deployment.
