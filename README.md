# Arch MSI

## live：LUKS 和挂载（重装会清空 p4）

```sh
cryptsetup luksFormat --type luks2 /dev/nvme0n1p4
cryptsetup open /dev/nvme0n1p4 cryptroot
mkfs.ext4 /dev/mapper/cryptroot
mount /dev/mapper/cryptroot /mnt
mount --mkdir /dev/nvme0n1p1 /mnt/boot
```

## live：安装基础系统

默认内核用 `linux-zen`；需要时可额外装 `linux` 作回退。

```sh
pacstrap -K /mnt base base-devel linux-zen mkinitcpio linux-firmware-intel intel-ucode intel-media-driver sof-firmware networkmanager vis-lexers
genfstab -U /mnt > /mnt/etc/fstab
arch-chroot /mnt
```

## chroot：时间、语言、用户

```sh
ln -sf /usr/share/zoneinfo/Asia/Bangkok /etc/localtime
hwclock --systohc
printf 'en_US.UTF-8 UTF-8\n' > /etc/locale.gen
locale-gen
printf 'LANG=en_US.UTF-8\n' > /etc/locale.conf
printf 'archlinux\n' > /etc/hostname
passwd
useradd -m -G wheel -s /bin/bash xfn
passwd xfn
sed -i 's/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL$/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers
```

## chroot：加密根分区启动

编辑 `/etc/mkinitcpio.conf`，HOOKS 改为：
```sh
HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt filesystems fsck)
```

```sh
mkinitcpio -P
bootctl install
```

写入引导项，UUID 从新建的 LUKS 分区读取，不沿用旧 UUID：
```sh
uuid=$(blkid -s UUID -o value /dev/nvme0n1p4)
cat > /boot/loader/entries/arch.conf <<EOF
title Arch Linux (zen)
linux /vmlinuz-linux-zen
initrd /initramfs-linux-zen.img
options rd.luks.name=$uuid=cryptroot root=/dev/mapper/cryptroot rw
EOF
```

若同时安装了官方 `linux`，可额外写回退项：
```sh
cat > /boot/loader/entries/arch-linux.conf <<EOF
title Arch Linux (stock)
linux /vmlinuz-linux
initrd /initramfs-linux.img
options rd.luks.name=$uuid=cryptroot root=/dev/mapper/cryptroot rw
EOF
```

默认直接进入 Windows；开机按住空格显示菜单，选择 Arch（zen）或 Windows。
`/boot/loader/loader.conf`：
```text
default auto-windows
timeout 0
editor no
```

```sh
systemctl enable NetworkManager systemd-timesyncd
exit
umount -R /mnt
cryptsetup close cryptroot
reboot
```

## 重启后

```sh
printf '\n[archlinuxcn]\nServer = https://mirrors.xtom.sg/archlinuxcn/$arch\n' | sudo tee -a /etc/pacman.conf
sudo pacman-key --lsign-key farseerfc@archlinux.org
sudo pacman -Sy archlinuxcn-keyring
sudo pacman -Su --needed paru
```

按需选择，配置目录彼此独立。

- bash：bash-completion fzf fastfetch chafa
- fontconfig：ttf-inconsolata wqy-microhei
- niri：niri fuzzel swaybg swaylock swayidle wlsunset
- alacritty：alacritty
- dbar：dbar-bin
- fcitx5：fcitx5-rime
- lf：lf
- portal：xdg-desktop-portal-termfilechooser xdg-desktop-portal-gtk
- GTK 默认主题：gnome-themes-extra
- vis：vis-lexers
- keyd：keyd
- mihomo：mihomo
- msi-fan：见 `msi-fan/install.sh`
- xrdp-config：见 `xrdp-config/work-config.sh`
- waydroid：waydroid（测安卓套壳用；zen 已带 rust binder）
- 格式化：prettier stylua shfmt ruff go
- 音频：pipewire-pulse wireplumber pavucontrol
- 电源：power-profiles-daemon python-gobject

归档配置见 `00archive/`（labwc / nvim / emacs 等）。

Vis 打开方式：
```sh
install -Dm644 vis/vis.desktop ~/.local/share/applications/vis.desktop
update-desktop-database ~/.local/share/applications
xdg-mime default vis.desktop text/plain
```

Rime（本机 schema 为 `moran_fixed`，词库仍用 `moran_fixed_simp`）：
```sh
install -Dm644 fcitx5/rime/* ~/.local/share/fcitx5/rime/
```

dbar 亮度滚轮（首次设置后重新登录）：
```sh
sudo install -Dm644 dbar/90-backlight.rules /etc/udev/rules.d/90-backlight.rules
sudo usermod -aG video "$USER"
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=backlight --action=add
```
