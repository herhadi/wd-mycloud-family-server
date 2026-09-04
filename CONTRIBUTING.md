# Contributing

Thanks for helping improve this project.

## Before making changes

- Read `AGENTS.md` and the relevant document under `docs/` first.
- Keep changes small, reversible, and focused on one purpose.
- Do not include passwords, API keys, tunnel credentials, private keys,
  certificates, personal identifiers, photos, or private documents.
- Use the generic family-role aliases defined by `AGENTS.md` in public examples.
- Do not make production changes merely to make documentation match the
  repository.

## Code and configuration changes

For service or gateway changes:

1. Validate the configuration before restarting a service.
2. Run the applicable tests and non-destructive health checks.
3. Verify the change on the target hardware when the change affects the
   verified deployment baseline.
4. Document important compatibility or recovery implications.

For the Browser Gateway, preserve WebDAV behavior unless a change explicitly
requires otherwise. Authentication, WebDAV methods, response metadata, and
permission boundaries are part of the compatibility surface.

## Commits

Use concise, imperative commit messages, for example:

```text
gateway: filter hidden entries from PROPFIND
```

Avoid mixing unrelated changes in one commit.

## Pull requests

A useful pull request should explain:

- What changed.
- Why it changed.
- How it was tested.
- Any known limitations or compatibility concerns.

Do not attach production configuration files or secrets.

## Release checkpoints

Verified deployment checkpoints are represented by Git tags and GitHub
Releases. Release assets should contain only intentionally distributable build
artifacts and must never contain production credentials or configuration.
