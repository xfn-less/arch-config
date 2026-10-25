#!/bin/bash
# Debian12：xrdp+TG+sakura+Firefox+fcitx5；公网 22/443/8443/9443/33890
# RDP：ip:33890（无需 SSH 隧道）
# SSH：ssh xfn@47.239.97.156
# 会话：~/.xsession（fcitx5 + TG + sakura + tint2 + openbox）
# 输入法：自然码 zrm（词库 fcitx5-chinese-addons/libime；用户词 ~/.local/share/fcitx5/table/zrm.*）
#
# TG 日期提醒（长轮询，秒回；不要再用 Google Apps Script）
#   装：bash xrdp-config/tg-remind/install.sh
#       （token 在 xrdp-config/tg-remind/.env，不入库）
#   目录/账本：~/tg-remind/  ~/tg-remind/ledger.txt
#   日志：journalctl --user -u tg-remind -f
#   状态：systemctl --user status tg-remind
#   停：  systemctl --user disable --now tg-remind
#   用法：11-13 说明  |  +01-01 明年  |  - 说明  |  ls 看表  |  多行覆盖
#   每天 6:00 / 18:00 Asia/Shanghai 推整表
#   先关掉 GAS 全部触发器，装的时候会 deleteWebhook

sudo apt-get update
sudo apt-get install -y --no-install-recommends \
  xrdp xorgxrdp openbox sakura tint2 dbus-x11 fonts-wqy-microhei telegram-desktop \
  firefox-esr \
  fcitx5 fcitx5-chinese-addons fcitx5-frontend-gtk3 fcitx5-frontend-qt5

mkdir -p ~/.config/fcitx5
cat > ~/.config/fcitx5/profile <<'EOF'
[Groups/0]
Name=Default
Default Layout=us
DefaultIM=zrm

[Groups/0/Items/0]
Name=keyboard-us
Layout=

[Groups/0/Items/1]
Name=zrm
Layout=

[GroupOrder]
0=Default
EOF

cat > ~/.xsession <<'EOF'
#!/bin/sh
export GTK_IM_MODULE=fcitx QT_IM_MODULE=fcitx XMODIFIERS=@im=fcitx
fcitx5 -d &
telegram-desktop &
sakura &
tint2 &
exec openbox
EOF
chmod +x ~/.xsession

sudo adduser "$USER" ssl-cert
sudo python3 - <<'PY'
from pathlib import Path
path = Path("/etc/xrdp/xrdp.ini")
lines = path.read_text().splitlines(keepends=True)
section = None
out = []
for line in lines:
	stripped = line.strip()
	if stripped.startswith("[") and stripped.endswith("]"):
		section = stripped[1:-1]
	if line.startswith("port=") and section == "Globals":
		line = "port=33890\n"
	out.append(line)
path.write_text("".join(out))
PY
sudo systemctl enable --now xrdp
sudo systemctl restart xrdp
