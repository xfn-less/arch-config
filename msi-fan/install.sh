#!/bin/sh
# Usage: sudo ./install.sh
# Installs the adjacent Python file and enables/starts its systemd service.
set -eu
cd -- "$(dirname -- "$0")"
if [ "$(id -u)" != 0 ]; then
    echo 'Run: sudo ./install.sh' >&2
    exit 1
fi
for cmd in python3 modprobe modinfo mount systemctl install; do
    command -v "$cmd" >/dev/null || { echo "Missing dependency: $cmd" >&2; exit 1; }
done
python3 - <<'PY'
from pathlib import Path
if Path('/sys/class/dmi/id/board_name').read_text().strip() != 'MS-14K2':
    raise SystemExit('Unsupported motherboard; nothing installed.')
compile(Path('msi-fan.py').read_text(), 'msi-fan.py', 'exec')
PY
modinfo ec_sys >/dev/null
# Restore stock settings before replacing a running controller.
if systemctl is-active --quiet msi-fan.service; then
    systemctl stop msi-fan.service
fi
install -o root -g root -m 0755 msi-fan.py /usr/local/bin/msi-fan.py
# The unit is embedded here: no separate service or finish-script file needed.
cat > /etc/systemd/system/msi-fan.service <<'UNIT'
[Unit]
Description=Verified MS-14K2 fan-only controller
After=systemd-modules-load.service
ConditionPathExists=/sys/class/dmi/id/board_name

[Service]
Type=simple
ExecCondition=/usr/bin/test ! -e /var/lib/msi-fan/failed
ExecStart=/usr/bin/python3 /usr/local/bin/msi-fan.py
ExecStopPost=/bin/sh -c 'if [ "$$SERVICE_RESULT" != "success" ]; then touch /var/lib/msi-fan/failed; echo "msi-fan failed; inspect journalctl -u msi-fan before removing /var/lib/msi-fan/failed" >&2; fi'
StateDirectory=msi-fan
StateDirectoryMode=0700
Restart=no
TimeoutStopSec=30
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
UNIT
chown root:root /etc/systemd/system/msi-fan.service
chmod 0644 /etc/systemd/system/msi-fan.service
systemctl daemon-reload
if [ -e /var/lib/msi-fan/failed ]; then
    echo 'Installed, but a previous failure blocks startup. Inspect: journalctl -u msi-fan' >&2
    exit 1
fi
systemctl enable --now msi-fan.service
sleep 1
if ! systemctl is-active --quiet msi-fan.service; then
    echo 'Controller did not stay running. Inspect: journalctl -u msi-fan' >&2
    exit 1
fi
printf '%s\n' 'Installed, running, and enabled at boot.' 'Stop and disable: sudo systemctl disable --now msi-fan'
