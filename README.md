# WD My Cloud Family Server

Lightweight private family NAS/server for WD My Cloud Gen1 running Debian Jessie on ARMv7.

> **Privacy / portability:** This repository intentionally uses generic family-role labels only: **Ayah**, **Ibu**, **Anak1**, **Anak2**, and **Anak3**. These are aliases representing roles, not fixed personal names. Anyone deploying this project may use different names in their own private configuration. Do not add real family names or other personal identifiers to this public repository.

## Verified baseline

- WD My Cloud Gen1, ARMv7l / armhf
- Debian 8.2 (Jessie), kernel 3.2.68
- Samba 4.2.14-Debian
- Syncthing v2.1.3 static ARM binary
- WebDAV v5.15.0 static ARM binary on TCP 6065
- Browser Gateway `webdav-gw` static ARMv7 binary on `127.0.0.1:6066`
- `webdav-gw.service` enabled and running
- Cloudflare Tunnel `cloudflared-mycloud.service`

## Upstream projects

This repository contains deployment documentation/configuration, scripts, and a custom Browser Gateway. The main open-source components used by the deployment are:

- **Samba** — SMB/CIFS file sharing
- **Syncthing** — file synchronization
- **WebDAV** — WebDAV server
- **cloudflared** — Cloudflare Tunnel client
- **Browser Gateway** — custom lightweight Go gateway maintained in this repository under `gateway/`

Upstream projects are not vendored into this repository unless explicitly noted. Their own licenses apply to their respective software.

## Family storage layout

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

There is no `/data/Private/` directory in the final storage model.

## Access and permission model

The same underlying storage is exposed through different protocols:

- **Samba:** normal read/write/delete access according to filesystem permissions.
- **WebDAV:** CRUD for private roots, `FamilyDocs`, `FamilyShared`, and `FamilyVideos`.
- **WebDAV `FamilyPhotos`:** read-only. Syncthing writes photo backups to this destination; family users do not modify it through WebDAV.
- **Browser Gateway:** browser-friendly directory browsing over the same WebDAV roots.

Samba permissions are independent of the WebDAV `FamilyPhotos` read-only rule.

## WebDAV and Browser Gateway

Each authenticated account uses `/data/<member>` directly as its WebDAV root. Family directories appear inside that root through filesystem bind mounts.

```text
Browser / WebDAV client
          ↓
Browser Gateway :6066
          ↓
WebDAV :6065
          ↓
/data/<member>
```

The gateway renders ordinary browser directory `GET` requests as HTML, passes WebDAV methods and file requests through, and filters common internal entries from `PROPFIND` directory responses.

The gateway is installed as `/usr/local/bin/webdav-gw` and managed by `webdav-gw.service`. It listens only on localhost and must not be exposed directly.

Cloudflare routes the public hostname to the gateway. SMB/TCP 445 and Syncthing GUI/TCP 8384 remain LAN-only.

## Cloudflare validation

For the `cloudflared` version used on the WD, validate ingress with:

```bash
/usr/local/bin/cloudflared tunnel --config /root/.cloudflared/config.yml ingress validate
```

The verified result is:

```text
Validating rules from /root/.cloudflared/config.yml
OK
```

## Release checkpoints

Verified deployment checkpoints are maintained as GitHub release/tag checkpoints. The current verified code checkpoint is **v1.1.1**.

### v1.1.1 — Browser Gateway PROPFIND checkpoint

Verified on the physical WD:

- Browser Gateway ARMv7 binary runs natively.
- `webdav-gw.service` is enabled and running.
- Browser directory rendering works through the gateway.
- WebDAV `PROPFIND` directory responses filter common internal entries while preserving normal entries.
- `FamilyPhotos` remains read-only through WebDAV.
- Samba remains independent from the WebDAV `FamilyPhotos` rule.
- The production ARMv7 binary and the build-machine binary have identical SHA-256 hashes.
- Cloudflare ingress routes the public hostname to the gateway.

See `CHANGELOG.md` and `docs/releases/` for checkpoint history.

## Safety

- Never publish passwords, API keys, Cloudflare credentials, private keys, certificates, personal names, photos, or documents.
- Keep production credential files outside Git.
- Do not expose SMB/TCP 445 or Syncthing GUI TCP 8384 publicly.
- Keep Browser Gateway TCP 6066 bound to `127.0.0.1`.
- Test locally before changing Cloudflare routing.
- Treat destructive disk commands as dangerous until the target has been verified.

## License

Original material in this repository is released under the **MIT License**. See `LICENSE`.

Third-party software remains subject to its respective upstream license.

## Repository documents

- `AGENTS.md` — repository safety and operating rules.
- `CONTRIBUTING.md` — contribution and change guidelines.
- `SECURITY.md` — security policy and vulnerability reporting.
- `CHANGELOG.md` — release history.
- `docs/setup.md` — base platform and service setup.
- `docs/architecture.md` — system architecture and permission boundaries.
- `docs/syncthing.md` — phone Send Only and MyCloud Receive Only procedure.
- `docs/deployment/syncthing-verified.md` — verified Syncthing runtime notes.
- `docs/deployment/webdav-cloudflare-verified.md` — verified WebDAV/Cloudflare deployment.
- `docs/browser-gateway.md` — Browser Gateway design, deployment and verification.
- `docs/releases/v1.1.0.md` — v1.1.0 release checkpoint.
- `docs/recovery/` — destructive recovery procedures.
