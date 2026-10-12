# MSI / Void 配置

默认桌面：niri（Wayland）。唯一系统安装入口：

```sh
sh setup-msi.sh
```

这是整机安装脚本，会修改软件包、GRUB、服务和用户配置；不要为了改桌面细节重复运行它。

## 启动

退出图形会话后，在 TTY 执行：

```sh
source ~/.bashrc
ni
```

## 桌面

仓库维护原来的 `niri/config.kdl`：

- 内屏 1.5×
- `Super+a` 终端、`Super+c` 浏览器
- `Super+q` 框选截图、`Super+p` 全屏截图
- `Super+Escape` 锁屏并关屏
- 方向/列切换仍用原来的 `Super+s/f/e/d` 等绑定
- 自启动：pipewire、fcitx5、alacritty、wlsunset、swayidle

其余多为安装时复制/生成一次：

- Fcitx5 自然码
- PipeWire drop-in（niri 启动 pipewire）
- lf 作为默认目录打开器
- 文本文件用 Alacritty 打开 Vis；终端 `EDITOR=vis`；配置在 `vis/`
- portal 文件选择用 termfilechooser + lf；其余走 gtk
- seat 用 seatd（不装 elogind）
- 界面字体文泉驿微米黑，终端 Inconsolata

## MSI 风扇

`msi-fan/` 保存本机已验证的工具和 runit 服务。
**仅支持 MS-14K2 / EC 14K2EMS1.110。** 不修改控制逻辑，不自动清除故障 `down` 标记。

```sh
sudo sv status msi-fan
sudo tail -n 30 /var/log/msi-fan/current
sudo sv down msi-fan
```

安装脚本拒绝热更新与仓库不同的运行中风扇程序；不要在服务运行时执行 `msi-fan-test`。

## 其他

- `keyd/`、Bash 和 Readline 保留既有习惯。
- `work-config.sh` 是远程 Debian RDP 环境，不是本机安装入口。
- `xray/` 实际维护 Mihomo；`tg-remind/` 是独立应用。
- `backup-push.sh` 会执行全仓库 `git add -A`，提交前必须检查全部改动。
