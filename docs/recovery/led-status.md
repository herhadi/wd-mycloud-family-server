# WD My Cloud Gen1 LED status notes

This document records LED observations made during the recovery of this specific WD My Cloud Gen1. LED behavior is useful as a recovery clue, but must not be treated as a universal hardware specification unless independently verified.

## Observed states during this recovery

| Device state | LED observation | Interpretation used during recovery |
|---|---|---|
| Original WD Cloud firmware | Record the observed factory-firmware LED state here when available | Factory firmware / original boot environment |
| Clean Debian Jessie boot | **Green LED observed after the clean Jessie recovery boot** | Device reached a working booted state |
| Brick/recovery state | Record exact color/blink pattern when observed | Recovery diagnosis; do not infer failure from LED alone |

## Important distinction

The LED is only one diagnostic signal. During recovery, always correlate it with:

- SSH availability
- IP address obtained on the LAN
- kernel/system identification (`uname -a`)
- filesystem mounts (`df -h`, `mount`)
- RAID state (`cat /proc/mdstat`)
- service state (Samba/Syncthing)

A green LED after installing clean Debian Jessie does not mean the original WD Cloud firmware is still running. In this project the device booted the recovered Jessie environment while the LED was green.

## Recovery diary

Keep exact observations here rather than replacing them with generic LED tables. If a future recovery produces a different color or blink pattern, add the observation with the corresponding system state and date.

## Caution

Do not use the LED alone to decide whether it is safe to unplug the device. Before power removal, stop services and unmount filesystems where possible. The recovery session for this project included a forced power removal during troubleshooting; future procedures should prefer a controlled shutdown when the system is responsive.
