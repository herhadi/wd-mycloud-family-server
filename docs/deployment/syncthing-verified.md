# Syncthing verified deployment

## Verified on 2026-09-01

The WD My Cloud Gen1 is running Syncthing automatically at boot.

Verified runtime configuration:

- Binary: `/usr/local/bin/syncthing`
- Version: Syncthing v2.1.3
- Binary SHA256: `4e42f23fa0add9f047a9a06cd47b6d9e78cd073c18de9ecc8acd978a299a4f29`
- Linux user: `syncthing` (UID 108)
- Home/config directory: `/var/lib/syncthing`
- GUI address: `0.0.0.0:8384` on the LAN
- Current first phone: Poco F7
- Live photo path: `/data/Family/Photos/Abi`
- Repository role label: Ayah
- Intended phone folder type: **Send Only**
- Intended MyCloud folder type: **Receive Only**
- Startup: verified after system reboot

## Current photo-backup topology

```text
Poco F7
  │
  │ Send Only
  ▼
Syncthing
  │
  │
  ▼
MyCloud: /data/Family/Photos/Abi
  │
  │ Receive Only
  ▼
FamilyPhotos
  ├── Samba: read-only
  └── WebDAV: read-only
```

The repository uses generic family-role labels. The live member names remain:

```text
Ayah  → Abi
Ibu   → Umi
Anak1 → Adzra
Anak2 → Adel
Anak3 → Afzal
```

## Service operations

The installed service is controlled through the Debian service wrapper:

    service syncthing start
    service syncthing stop
    service syncthing restart
    service syncthing status

System shutdown:

    shutdown -h now

## Folder initialization and permissions

Syncthing must be able to create its `.stfolder` marker in the receive destination. For the live Abi destination, the verified setup is:

    mkdir -p /data/Family/Photos/Abi
    chown syncthing:keluarga /data/Family/Photos/Abi
    chmod 2775 /data/Family/Photos/Abi

Do not create `.stfolder` manually.

A previous initialization attempt failed with:

    mkdir /data/Family/Photos/Abi/.stfolder: permission denied

After correcting ownership/permissions, the folder initialized and photo synchronization started successfully.

## Folder path history

The original Syncthing folder path was `/data/Photos/HP-Ayah`. The final live path is `/data/Family/Photos/Abi`.

During the migration, the old server path was removed while the Syncthing index still contained the previous file inventory. Syncthing reported `folder marker missing` until the folder was recreated correctly and initialized with the proper service-account permissions.

The source photos remained on Poco F7, so the recovery strategy was to resynchronize from the phone rather than attempt to reconstruct missing server files from the old index.

## Initial synchronization

The first live phone currently contains the source photos and is being synchronized into the final server path. Do not delete the source photos from the phone until the server copy has been verified by file count, size, and spot checks.

After the initial transfer is verified, the MyCloud folder should be left as **Receive Only**.

## RAM observation

The device has 226 MB RAM and 512 MB swap. During a manual Syncthing test, Syncthing's observed RSS was approximately 22.7 MB. This is an observation, not a guarantee that all future workloads will fit safely.

## GUI access

Syncthing normally binds its GUI to localhost. For this deployment the GUI was tested with:

    --gui-address=0.0.0.0:8384

and was accessible from the LAN during verification.

Do not expose this GUI directly to the public Internet without authentication and an appropriate secure access layer.

## Operational documentation

For complete phone setup, Send Only configuration, MyCloud web-GUI Receive Only configuration, verification, and recovery procedures, see:

    docs/syncthing.md
