# Changelog

All notable changes to this project are documented here.

## [Unreleased]

- No unreleased changes.

## [1.1.1] - 2026-09-04

### Added

- Browser Gateway filtering for hidden/internal entries in WebDAV `PROPFIND`
  directory responses.

### Verified

- ARMv7 gateway binary runs on the physical WD My Cloud Gen1.
- Browser directory rendering works through the gateway.
- WebDAV remains functional for normal file operations.
- `FamilyPhotos` remains read-only through WebDAV.
- Samba remains independent from the WebDAV read-only rule.
- Production and build-machine gateway binaries have matching SHA-256 hashes.

### Compatibility note

The gateway intentionally filters presentation-level `PROPFIND` entries while
preserving the underlying WebDAV response structure as much as possible. The
verified deployment uses the WebDAV server documented in the repository.

## [1.1.0] - 2026-09-02

### Added

- Initial verified Browser Gateway deployment for browser-friendly directory
  browsing through the WebDAV service.

### Known issue

WebDAV `PROPFIND` responses were not yet filtered, so some clients could display
internal files such as Syncthing or macOS metadata entries.

## Versioning

Release versions are represented by Git tags and GitHub Releases. Detailed
implementation history remains in the Git commit history.
