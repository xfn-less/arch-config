#!/bin/bash
# 香港工作机：ssh -p 40296 xfn@103.146.230.179
# 用法：bash xrdp-config/tg-remind/install.sh
# token 写在同目录 .env（不入库）
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
DST="$HOME/tg-remind"

mkdir -p "$DST"
cp "$SRC/bot.py" "$DST/bot.py"
chmod +x "$DST/bot.py"
touch "$DST/ledger.txt"
chmod 700 "$DST"

umask 077
if [[ -n "${BOT_TOKEN:-}" ]]; then
  printf 'BOT_TOKEN=%s\n' "$BOT_TOKEN" > "$DST/.env"
elif [[ -f "$SRC/.env" ]]; then
  cp "$SRC/.env" "$DST/.env"
elif [[ ! -f "$DST/.env" ]]; then
  echo "缺少 $SRC/.env（写一行 BOT_TOKEN=...）" >&2
  exit 1
fi
chmod 600 "$DST/.env"

mkdir -p "$HOME/.config/systemd/user"
cat > "$HOME/.config/systemd/user/tg-remind.service" <<EOF
[Unit]
Description=Telegram date sorter
After=network-online.target

[Service]
Type=simple
WorkingDirectory=$DST
ExecStart=/usr/bin/python3 $DST/bot.py
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
EOF

sudo loginctl enable-linger "$USER"
systemctl --user daemon-reload
systemctl --user enable --now tg-remind.service
systemctl --user restart tg-remind.service
systemctl --user --no-pager --full status tg-remind.service
echo
echo "账本: $DST/ledger.txt"
echo "日志: journalctl --user -u tg-remind -f"
echo "停:   systemctl --user disable --now tg-remind"
