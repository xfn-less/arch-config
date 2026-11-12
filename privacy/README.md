# 采集禁用（实测结论）

## 摄像头（驱动级，OK）

`/etc/modprobe.d/disable-capture.conf`：
```
blacklist uvcvideo
install uvcvideo /bin/false
```

配套：`/etc/udev/rules.d/99-disable-capture.rules`（video/media 节点 MODE=0000）。

## 麦克风（不能 blacklist DMIC）

`blacklist snd_soc_dmic` 会让整张 SOF 声卡起不来（扬声器变 Dummy）。

**系统级**（全用户，含 xfng/xfnx/xfnk）：

- `/etc/wireplumber/wireplumber.conf.d/99-disable-onboard-mic.conf` — 禁用 `alsa_input.*`
- `/etc/wireplumber/wireplumber.conf.d/99-bt-no-mic.conf` — A2DP 听歌（需 `a2dp_source`），关 HFP/HSP 麦
- 蓝牙耳机：`/etc/bluetooth/main.conf` 用 `ControllerMode = bredr`（双模 LE 时易 AVDTP 失败）

仓库副本：`arch-config/wireplumber/wireplumber.conf.d/`（与 `/etc` 对齐）。  
不要再放一份在 `~/.config/wireplumber/`，以免重复。

3.5mm 不插 = 无模拟麦。
