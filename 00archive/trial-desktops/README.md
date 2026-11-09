# 多 DE 试用（自装）

用户：`xfn`（niri）/ `xfng`（GNOME）/ `xfnx`（XFCE）/ `xfnk`（Plasma）  
DM：**ly**（已装；脚本里 `enable ly@tty1`）  
原则：只装壳，文件管理器/终端套件缺了再装。

## 已做好的准备

| 项 | 状态 |
|---|---|
| `pkg-before.txt` | 装包前软件列表 |
| `niri-baseline.txt` | niri 内存基线（对比用） |
| `install.sh` | 一键：三套壳 + 启 ly（用户已建则跳过） |
| 用户 `xfng`/`xfnx`/`xfnk` | 已建，`wheel,video`；临时密码见 `~/.cache/agent-scratch/trial-desktops-passwords.txt` |
| 禁麦 | 升到 `/etc/wireplumber/wireplumber.conf.d/`（全用户） |
| 禁摄 | 已在 `/etc/modprobe.d` + udev（不动） |

## 你要做的

```sh
bash ~/arch-config/trial-desktops/install.sh
# 重启后用 ly 选用户和会话
```

手动等价步骤见 `install.sh` 正文。

## 登录对照

| 用户 | 会话 | 缩放预期 |
|---|---|---|
| xfn | Niri | 已有 1.5 |
| xfng | GNOME Wayland | 设置里 150% |
| xfnx | XFCE | 弱，对照用 |
| xfnk | Plasma Wayland | 设置里 150% |

## 内存对比口径

见 `niri-baseline.txt` 末尾 tip。空闲会话、尽量关浏览器，再 `free` + 壳进程 RSS。

## 回滚

```sh
# 对照新增包
comm -13 <(sort ~/arch-config/trial-desktops/pkg-before.txt) <(sort <(pacman -Qq))

sudo systemctl disable --now ly@tty1.service
sudo systemctl enable getty@tty1.service   # 若需要恢复纯 getty

sudo userdel -r xfng
sudo userdel -r xfnx
sudo userdel -r xfnk

# 卸 DE 按 comm 列表 pacman -Rns …；ly 可留可卸
# /etc 禁麦默认保留
```
