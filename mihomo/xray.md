# Xray 两条线路

```text
香港：客户端 -> 47.239.97.156:8443 -> 香港出口
国内：客户端 -> 47.239.97.156:9443 -> 183.56.236.235:443 -> 国内出口
网站：         47.239.97.156:443
```

只备份两个文件：

- 本机：`~/arch-work/xray-config/mihomo-config.yaml`
- 手机：`~/arch-work/xray-config/mihomo-mobile.yaml`

权限为 600，不要提交仓库。服务器重装时重新生成 Reality 凭据，再更新 Mihomo。

## Xray 出口配置

香港和国内共用这个模板，分别替换端口和各自生成的凭据：

- 香港：`__PORT__` 为 `8443`
- 国内：`__PORT__` 为 `443`

```json
{
  "log": {"loglevel": "warning"},
  "routing": {
    "rules": [
      {"type": "field", "ip": ["geoip:private"], "outboundTag": "BLOCK"}
    ]
  },
  "inbounds": [
    {
      "listen": "0.0.0.0",
      "port": __PORT__,
      "protocol": "vless",
      "settings": {
        "clients": [
          {"id": "__UUID__", "flow": "xtls-rprx-vision", "email": "xfn"}
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "raw",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "target": "www.nvidia.com:443",
          "xver": 0,
          "serverNames": ["www.nvidia.com"],
          "privateKey": "__PRIVATE_KEY__",
          "shortIds": ["__SHORT_ID__"]
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls", "quic"]
      }
    }
  ],
  "outbounds": [
    {"protocol": "freedom", "tag": "DIRECT"},
    {"protocol": "blackhole", "tag": "BLOCK"}
  ]
}
```

服务器保存私钥；Mihomo 使用 UUID、`xray x25519` 输出的 PublicKey 和 short ID。

## 香港服务器

- SSH：`ssh xfn@47.239.97.156`
- `443` 留给网站
- `8443`：香港 Xray
- `9443`：转发到国内 `183.56.236.235:443`
- `33890`：xrdp 公网直连 `IP:33890`；工作机见 `xrdp-config/work-config.sh`
- Xray 配置：`/usr/local/etc/xray/config.json`
- 转发配置：`/etc/systemd/system/xray-relay.{socket,service}`

安装 Xray 必须使用 Bash：

```sh
curl -fsSL https://github.com/XTLS/Xray-install/raw/main/install-release.sh \
  -o /tmp/install-release.sh
sudo useradd --system --home-dir /var/lib/xray --create-home \
  --shell /usr/sbin/nologin xray 2>/dev/null || true
sudo env TERM=xterm bash /tmp/install-release.sh install --install-user xray
```

生成新的 UUID、X25519 密钥和 short ID，写入监听 `8443` 的
`/usr/local/etc/xray/config.json`，然后验证并启动：

```sh
sudo /usr/local/bin/xray uuid
sudo /usr/local/bin/xray x25519
openssl rand -hex 8
sudo chown root:xray /usr/local/etc/xray/config.json
sudo chmod 640 /usr/local/etc/xray/config.json
sudo /usr/local/bin/xray run -test \
  -config /usr/local/etc/xray/config.json
sudo systemctl enable --now xray
```

`xray-relay.socket`：

```ini
[Socket]
ListenStream=9443
NoDelay=true

[Install]
WantedBy=sockets.target
```

`xray-relay.service`：

```ini
[Unit]
After=network-online.target

[Service]
ExecStart=/lib/systemd/systemd-socket-proxyd 183.56.236.235:443
NoNewPrivileges=true
PrivateTmp=true
```

```sh
sudo systemctl daemon-reload
sudo systemctl enable --now xray-relay.socket
sudo ss -lntp | grep -E ':(8443|9443)\b'
```

服务商防火墙开放 TCP `22`、`443`、`8443`、`9443`、`33890`。

## 国内服务器

- SSH：`ssh root@183.56.236.235`
- `443`：国内 Xray，只允许来源 `47.239.97.156/32`
- 配置：`/usr/local/etc/xray/config.json`

国内下载 GitHub 较慢：在本机通过 Mihomo 下载并校验，再 SCP 过去，不需要经过香港服务器。

```sh
set -euo pipefail
version=$(curl -fsSL https://api.github.com/repos/XTLS/Xray-core/releases/latest |
  sed -n 's/.*"tag_name": "\(v[^"]*\)".*/\1/p' | head -n 1)
# API 限流或解析失败时 version 为空，下载会变成 .../download//Xray-linux-64.zip → 404
[ -n "$version" ] || { echo "failed to resolve latest Xray version from GitHub API" >&2; exit 1; }
echo "Xray $version"
curl -fLO https://raw.githubusercontent.com/XTLS/Xray-install/main/install-release.sh
curl -fLO "https://github.com/XTLS/Xray-core/releases/download/$version/Xray-linux-64.zip"
curl -fLO "https://github.com/XTLS/Xray-core/releases/download/$version/Xray-linux-64.zip.dgst"
expected=$(sed -n 's/^SHA2-256= //p' Xray-linux-64.zip.dgst)
printf '%s  Xray-linux-64.zip\n' "$expected" | sha256sum -c -
scp install-release.sh Xray-linux-64.zip root@183.56.236.235:/tmp/
```

在国内服务器部署：

```sh
useradd --system --home-dir /var/lib/xray --create-home \
  --shell /usr/sbin/nologin xray 2>/dev/null || true
bash /tmp/install-release.sh install \
  --local /tmp/Xray-linux-64.zip --install-user xray
/usr/local/bin/xray uuid
/usr/local/bin/xray x25519
openssl rand -hex 8
# 用新凭据写入监听 443 的 /usr/local/etc/xray/config.json
chown root:xray /usr/local/etc/xray/config.json
chmod 640 /usr/local/etc/xray/config.json
/usr/local/bin/xray run -test -config /usr/local/etc/xray/config.json
systemctl enable --now xray
```

服务商防火墙只开放 TCP `22`，以及仅允许香港 IP 访问的 `443`。

## 客户端（Arch Linux + systemd）

本机已配置的 `archlinuxcn` 仓库提供 `mihomo`，包更新交给 pacman。

```sh
sh ~/arch-config/mihomo/mihomo.sh
```

`mihomo.sh` 和 `mihomoctl` 放在同一目录。脚本安装依赖、校验现有 YAML、部署控制脚本与服务，并启用、启动服务。TUN 会改变路由和 DNS；配置路径和代理规则不改动。

服务：`/etc/systemd/system/mihomo.service`；数据：`/var/lib/mihomo`；日志：journal。

```sh
systemctl status mihomo
sudo systemctl stop mihomo
sudo systemctl start mihomo
sudo systemctl restart mihomo
journalctl -u mihomo -b
mihomoctl status          # 仅查询代理模式和节点
sudo systemctl disable --now mihomo  # 停止并取消开机自启
```

- 本机：`~/arch-work/xray-config/mihomo-config.yaml`
- 手机：`~/arch-work/xray-config/mihomo-mobile.yaml`

```text
香港节点：47.239.97.156:8443，使用香港凭据
国内节点：47.239.97.156:9443，使用国内凭据
```

验证：

```sh
sudo mihomo -t -d /var/lib/mihomo -f ~/arch-work/xray-config/mihomo-config.yaml
sudo systemctl restart mihomo
mihomoctl use global hk
curl -4 https://icanhazip.com    # 应为 47.239.97.156
mihomoctl use global cn
curl -4 https://icanhazip.com    # 应为 183.56.236.235
mihomoctl use global hk
mihomoctl use rule split
```

## 更换国内服务器

1. 备份本机和手机 Mihomo。
2. 新国内机按上文安装 Xray，生成新 UUID / X25519 / short ID，写入 `443` 配置；防火墙只放行香港 `47.239.97.156/32` 访问 `443`。
3. 香港把 `xray-relay.service` 的目标改成新国内 IP，然后：
   ```sh
   sudo systemctl daemon-reload
   sudo systemctl restart xray-relay.socket
   ```
4. 本机和手机 Mihomo：更新「国内节点」的 uuid / public-key / short-id；把规则里的旧国内 IP 换成新 IP（`IP-CIDR,<新国内>/32,香港`）。
5. `mihomoctl use global cn` 后 `curl -4 https://icanhazip.com` 应为新国内 IP；确认后再关旧机。

## 更换香港服务器

1. 备份本机和手机 Mihomo。
2. 新香港机重新部署 Xray，并建立 `9443 -> 国内:443` 转发。
3. 国内 `443` 白名单和客户端地址改为新香港 IP。
4. 验证两个出口后，再关闭旧服务器。
