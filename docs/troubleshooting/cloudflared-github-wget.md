# cloudflared download troubleshooting on Debian Jessie

## Verified failure

On the WD My Cloud Gen1 running Debian Jessie with the legacy `wget`, an earlier version-specific GitHub release asset URL failed after redirecting to `release-assets.githubusercontent.com`.

Observed sequence:

    github.com
      -> HTTP 302
      -> release-assets.githubusercontent.com
      -> HTTP 403: Server failed to authenticate the request
      -> repeated redirects/retries
      -> 20 redirections exceeded

The captured log shows the redirect followed by the 403 response and eventually `20 redirections exceeded`. The failed attempt left `/tmp/cloudflared` at 0 bytes. Copying that file to `/usr/local/bin/cloudflared` produced a zero-byte executable which returned no output.

## Subsequent successful download

A later attempt succeeded on the same WD with:

    wget -O cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm

The download completed with HTTP 200 from `release-assets.githubusercontent.com` and produced a 36,288,720-byte file.

Therefore, `/latest/download/...` is **not universally broken** on this hardware. The earlier failure was specific to the prior release URL/redirect state at that time.

## Rule for this hardware

Do not repeatedly retry a GitHub release URL when the old Jessie `wget` enters a redirect/403 loop. Stop the attempt, then use a URL that has been observed to work or transfer the binary from a modern machine.

For every download, verify before installation:

    ls -lh /tmp/cloudflared
    file /tmp/cloudflared
    sha256sum /tmp/cloudflared
    /tmp/cloudflared --version

Only after the binary is verified should it be copied to `/usr/local/bin`.

## Permanent installation lesson

`/tmp` is a staging area, not a permanent software location. A successfully tested binary should be copied to `/usr/local/bin` before rebooting.

Do not confuse this download/redirect problem with a `cloudflared tunnel run` reconnect loop; they are separate failure modes.
