#!/bin/sh
set -eu
cd -- "$(dirname -- "$0")"

sudo pacman -S --needed mihomo curl python

sudo install -d -m 700 /var/lib/mihomo /var/lib/mihomo/providers
sudo /usr/bin/mihomo -t -d /var/lib/mihomo \
    -f /home/xfn/arch-work/xray-config/mihomo-config.yaml
sudo install -m 755 mihomoctl /usr/local/bin/mihomoctl
sudo chmod 600 /home/xfn/arch-work/xray-config/mihomo-config.yaml

sudo tee /etc/systemd/system/mihomo.service >/dev/null <<'EOF'
[Unit]
Description=Mihomo proxy
Wants=network-online.target
After=network-online.target

[Service]
ExecStart=/usr/bin/mihomo -d /var/lib/mihomo -f /home/xfn/arch-work/xray-config/mihomo-config.yaml
StateDirectory=mihomo
StateDirectoryMode=0700
Restart=on-failure
RestartSec=5
TimeoutStopSec=30

[Install]
WantedBy=multi-user.target
EOF
sudo chmod 644 /etc/systemd/system/mihomo.service
sudo systemctl daemon-reload
sudo systemctl enable --now mihomo
printf '%s\n' '已部署并启用服务。'
