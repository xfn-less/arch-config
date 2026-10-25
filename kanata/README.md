# Kanata

`kanata-bin` 1.12.0。三份以同名 `keyd/*.conf` 为基准迁移，不沿用之前实验版的 3/8 Alt、base 方向键或纯 Win 调整。

| 配置 | 当前设备 |
|---|---|
| `60.kbd` | SmartCloud KG18 / KG18 Keyboard |
| `laptop.kbd` | AT Translated Set 2 keyboard |
| `new.kbd` | Hardtochooseone Hardtochooseone Keyboard |

仅抓取这些键盘名称，不抓同设备的鼠标接口或虚拟键盘。更换设备需更新名称。

`new.kbd` 按 Vial 的左右各 3×5＋3 拇指键排列。两个 Space 同码，所以 36 个物理键只列 35 个输入，右 Space 在矩阵中留空；当前两边 Space 功能相同。

- `defsrc` 是硬件输入，`base` 是软件输出；对应位置一一匹配，`_` 透传到下一层。
- `60` / `laptop` 保留原右侧平移、双功能和 Win/nav；`60` 保留 nav 下的 F 区、Delete。
- `new` 保留 Tab/Backspace Ctrl、Esc/Enter Win、W/O Shift、R/U Alt、Q Fn、Space 数字符号层，以及左 Alt/右 Shift 的左右键。
- `new` 的 Q/Fn 层额外提供 I/K 亮度加/减、J/L 音量减/加；发送标准媒体键，由 niri 现有绑定处理，每次 1%。
- `overloadt2` 用 `tap-hold-release 0 200`；`new` 的 `lettermod` 加每键 `require-prior-idle 150`。两者计时实现不同，需试打，不保证边界手感完全一致。
- 原 `new.conf` 的 `[sshift]` 没有激活入口，不人为添加；Shift 叠加数字/符号层时正常修饰输出。

## Vial 权限（new）

只给活动本地用户开放该键盘的 hidraw，不需要用 sudo 运行 Vial：
```sh
sudo install -m644 70-vial.rules /etc/udev/rules.d/70-vial.rules
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=hidraw --action=add
```

重新打开 Vial；仍未识别时拔插键盘。固件需支持 Vial。

## 鼠标模式（三份均有）

`60` / `laptop` 用 Win+X 进入；`new` 用 Z 长按进入（200ms，150ms 连打保护），轻点仍输入 z，Space+Z 仍是 7。new 不再占用 Win+X。

`new` 的鼠标层只在 Z 按住时保持，松开 Z 退出；`60` / `laptop` 的鼠标模式仍锁定保持。Enter 左击并提前退出，物理 Esc 提前退出（60/laptop 的 Caps 也退出）。其他未分配字母不输出，无中键。

按逻辑键：IJKL 上/左/下/右，U/O 水平滚动，Y/H 竖向滚动。`new` 为 D 按住慢移、F/G 左右键；`60` / `laptop` 保持 S 慢移、F/D 左右键。左键按住均可拖拽。

`new` 的逻辑键就是物理键；`60` / `laptop` 按右移后的逻辑布局，IJKL 对应物理 O/K/L/分号，U/O 对应物理 I/P，Y/H 对应物理 U/J。

`new` 鼠标模式中 Tab/Backspace 为 Ctrl，W 为 Shift，R 为 Alt，原左 Alt/右 Shift 仍是左右键，以便组合点击。

## 部署与试用

在本目录执行：
```sh
sudo install -Dm644 kanata@.service /etc/systemd/system/kanata@.service
sudo systemctl daemon-reload
kanata --check --cfg 60.kbd &&
kanata --check --cfg laptop.kbd &&
kanata --check --cfg new.kbd &&
sudo install -Dm644 -t /etc/kanata 60.kbd laptop.kbd new.kbd
```

与 keyd 互斥。先松开所有键，设置五分钟回退再启动：
```sh
sudo systemd-run --unit=kanata-rollback --on-active=5min --collect /usr/bin/systemctl start keyd.service
sudo systemctl restart kanata@60 kanata@laptop kanata@new
```

确认输入正常后，取消回退并设置开机启动：
```sh
sudo systemctl stop kanata-rollback.timer
sudo systemctl disable keyd
sudo systemctl enable kanata@60 kanata@laptop kanata@new
```

## 日常修改

编辑仓库后，检查、复制、重启对应实例；只改仓库不会自动生效：
```sh
kanata --check --cfg new.kbd &&
sudo install -m644 new.kbd /etc/kanata/new.kbd &&
sudo systemctl restart kanata@new
```

其他键盘替换文件名和实例名。切换/重启时松开所有按键。

临时回退：`sudo systemctl start keyd`，会停止三个 Kanata 实例。恢复 keyd 开机默认：
```sh
sudo systemctl disable kanata@60 kanata@laptop kanata@new
sudo systemctl enable keyd
```

紧急退出：物理左 Ctrl + Space + Esc。new 可直接用触摸板/鼠标操作终端执行回退命令。
