# MS-14K2 fan-only configuration

Hardware: MSI Stealth 14 AI Studio A1VFG, MS-14K2, EC 14K2EMS1.110.

## Evidence

- Windows screenshots confirm Cooler Boost at 0x98 bit 7, advanced fan mode at 0xd4 (0x8d), second speeds at 0x73 and 0x8b.
- Linux isolated first-speed tests at 0x72 and 0x8a yielded both live fan readings of 30.
- Small increases to all 14 speed slots were read back and restored. This is NOT a full thermal/load validation of high stages.
- A 15-minute 30% minimum test cooled the CPU from 54 C to roughly 48–49 C; user accepted the noise.

## Long-term service

Root-owned /usr/local/bin/msi-fan-daemon reuses checked I/O from root-owned /usr/local/bin/msi-fan-test.
Runit service: /etc/sv/msi-fan, enabled by /var/service/msi-fan symlink.
Log: /var/log/msi-fan/current, rotated (200 KB, three old logs).

Both curves: 30,42,48,58,70,90,100.
Temperature thresholds remain unchanged. No CPU, charging, keyboard or Cooler Boost control writes.

The service checks board, firmware, stock starting curves and thresholds. It uses an exclusive lock with the test tool and verifies every write. Normal stop restores stock curves and automatic mode. A verified exact stock reset (e.g. resume) is reapplied. Unknown changes or CPU >=85 C stop the service and restore stock; the finish script disables retries and next-boot startup using /etc/sv/msi-fan/down. Resume/reboot behavior has not yet been tested.

These are community-derived raw EC controls, NOT an official support guarantee. Power loss, SIGKILL, kernel failure or EC failure can prevent cleanup. High-temperature stage effectiveness has not been validated; hardware safety protections must not be assumed from software checks alone.

Status:

    sudo sv status /var/service/msi-fan

Stop and restore (current boot only):

    sudo sv down /var/service/msi-fan

Start:

    sudo sv up /var/service/msi-fan

Disable across boots and restore:

    sudo touch /etc/sv/msi-fan/down
    sudo sv down /var/service/msi-fan

Reenable after inspection:

    sudo rm -f /etc/sv/msi-fan/down
    sudo sv up /var/service/msi-fan

Inspect logs:

    sudo tail -30 /var/log/msi-fan/current

Stop the service before running msi-fan-test. The test command automatically restores on normal completion/Ctrl+C.

## Other session changes

PipeWire + WirePlumber + PulseAudio compatibility installed; user audio services started by ~/.config/pipewire/pipewire.conf.d/20-session-audio.conf and niri startup. /etc/udev/rules.d/99-local-sound.rules grants audio group 0660 ALSA access. Firefox GPU video-engine activity confirmed hardware video decoding.

CPU turbo temporarily disabled earlier, but restored by reboot; no persistent CPU tuning was added.
