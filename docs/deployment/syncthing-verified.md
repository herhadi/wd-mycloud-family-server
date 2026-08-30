# Syncthing verified deployment

## Verified on 2026-08-30

The WD My Cloud Gen1 is running Syncthing automatically at boot.

Verified runtime configuration:

- Binary: `/usr/local/bin/syncthing`
- Version: Syncthing v2.1.3
- Binary SHA256: `4e42f23fa0add9f047a9a06cd47b6d9e78cd073c18de9ecc8acd978a299a4f29`
- Linux user: `syncthing` (UID 108)
- Home/config directory: `/var/lib/syncthing`
- GUI address: `0.0.0.0:8384`
- Synced folder label: `Poco F7`
- Synced path: `/data/Photos/HP-Ayah`
- Existing synced data: approximately 9.1 GB at verification time
- Startup: verified after system reboot

## Service operations

The installed service is controlled through the Debian service wrapper:

    service syncthing start
    service syncthing stop
    service syncthing restart
    service syncthing status

System shutdown:

    shutdown -h now

## Important history

An extracted directory was named `syncthing-linux-arm-v1.19.2`, but the binary inside was verified by `--version` and SHA256 to be Syncthing v2.1.3. The directory name must therefore not be used as evidence of the binary version.

The Syncthing configuration in `/var/lib/syncthing/config.xml` retained the existing `Poco F7` folder definition, so the 9.1 GB dataset did not need to be re-created from scratch in the GUI.

## RAM observation

The device has 226 MB RAM and 512 MB swap. During a manual Syncthing test, Syncthing's observed RSS was approximately 22.7 MB. After reboot with Syncthing stopped, the system reported approximately 199 MB available memory and zero swap used. This is an observation, not a guarantee that all future workloads will fit safely.

## GUI access

Syncthing normally binds its GUI to localhost. For this deployment the GUI was tested with:

    --gui-address=0.0.0.0:8384

and was accessible from the LAN at:

    http://192.168.11.125:8384

Do not expose this GUI directly to the public Internet without authentication and an appropriate secure access layer.
