# cloudflared download issue on Debian Jessie

## Verified failure

On the WD My Cloud Gen1 running Debian Jessie with the legacy `wget`, downloading the GitHub release asset directly could fail after the GitHub redirect to `release-assets.githubusercontent.com`.

Observed sequence:

    github.com
      -> HTTP 302
      -> release-assets.githubusercontent.com
      -> HTTP 403: Server failed to authenticate the request
      -> repeated redirects/retries
      -> 20 redirections exceeded

The captured log shows the redirect followed by the 403 response and eventually:

    20 redirections exceeded

The failed attempt also left an empty `/tmp/cloudflared` file (0 bytes). Copying that file to `/usr/local/bin/cloudflared` produced a zero-byte executable which returned no output.

## Rule for this hardware

Do not repeatedly retry the same GitHub release URL from the old Jessie `wget` when this redirect loop occurs. First verify the downloaded file size and type before copying it anywhere.

Recommended verification:

    ls -lh /tmp/cloudflared
    file /tmp/cloudflared
    sha256sum /tmp/cloudflared
    /tmp/cloudflared --version

Only after the binary is verified should it be copied to `/usr/local/bin`.

## Safer workaround

When GitHub release redirects are unreliable from Jessie, download the known release asset from a modern machine on the same LAN and transfer it to the WD with `scp`. This avoids the legacy `wget` redirect/authentication problem.

## Important operational lesson

`/tmp` is not a permanent software location. A binary that has been successfully tested should be copied to `/usr/local/bin` before rebooting.

Do not confuse this download/redirect problem with a `cloudflared tunnel run` reconnect loop; they are separate failure modes.
