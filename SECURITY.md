# Security Policy

## Scope

This repository contains deployment documentation, configuration examples,
scripts, and a small custom Browser Gateway for a private family NAS.

Do not publish production credentials, API keys, Cloudflare tunnel credentials,
private keys, certificates, personal identifiers, private documents, or private
photos in issues, pull requests, commits, or repository files.

## Supported security baseline

The verified deployment keeps these services private unless explicitly routed
through the intended gateway:

- SMB/TCP 445: LAN only
- Syncthing GUI/TCP 8384: LAN only
- WebDAV/TCP 6065: local service endpoint
- Browser Gateway/TCP 6066: bound to `127.0.0.1`
- Public remote browser access: through the configured Cloudflare Tunnel

## Reporting a vulnerability

Please do not disclose a suspected security vulnerability in a public issue
if it could expose credentials, private files, authentication controls, or
remote access to a live deployment.

Instead, contact the repository maintainer privately through the GitHub account
associated with this repository and provide:

1. A concise description of the issue.
2. Affected component and version, if known.
3. Reproduction steps that do not require sharing secrets or private data.
4. The potential impact.

Please allow reasonable time for assessment and remediation before public
disclosure.

## Live-system caution

This project targets legacy WD My Cloud Gen1 hardware. Recovery and disk
operations can be destructive. Follow the repository recovery procedures and
verify the target device and disk before any destructive command.
