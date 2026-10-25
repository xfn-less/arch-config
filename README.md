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

目标：装完后尽量只靠包名复现可用桌面；自定义配置能少则少。

### 桌面（主线，开箱）

```sh
sudo pacman -S --needed \
  plasma-desktop sddm \
  plasma-nm plasma-pa \
  dolphin konsole kate spectacle \
  breeze breeze-gtk kde-gtk-config \
  xdg-desktop-portal-kde kscreen \
  fcitx5 fcitx5-qt fcitx5-gtk fcitx5-configtool fcitx5-rime \
  noto-fonts noto-fonts-cjk noto-fonts-emoji \
  pipewire-pulse wireplumber
sudo systemctl enable sddm NetworkManager
```

登录选 **Plasma (Wayland)**。截图用 Spectacle，文件管理 Dolphin，终端 Konsole，编辑 Kate。
显示缩放本机约 `1.5`（2560x1600）。输入法装上后用系统设置 / fcitx5-configtool。

### 仍保留、尚未替换

- bash / fzf：下一步再换 shell
- fcitx5 自定义 Rime、fontconfig、mihomo、msi-fan、xrdp-config：未动
- vis / alacritty / kanata / keyd：暂留，后续归档

### 已归档（`00archive/`）

labwc / niri / nvim / emacs / lf / ghostty / bt /
xdg-desktop-portal（niri）/ xdg-desktop-portal-termfilechooser

niri 包仍可作登录回退；日常主线改为 Plasma。
