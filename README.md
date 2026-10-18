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

```sh
pacstrap -K /mnt base base-devel linux mkinitcpio linux-firmware-intel intel-ucode intel-media-driver sof-firmware networkmanager vis-lexers
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
title Arch Linux
linux /vmlinuz-linux
initrd /initramfs-linux.img
options rd.luks.name=$uuid=cryptroot root=/dev/mapper/cryptroot rw
EOF
```

默认直接进入 Windows；开机按住空格显示菜单，选择 Arch 或 Windows。
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

bash-completion fzf fastfetch chafa
ttf-inconsolata wqy-microhei
labwc alacritty fuzzel kanshi swaybg swaylock swayidle wlopm wlsunset
fcitx5-rime
xdg-desktop-portal-gtk gnome-themes-extra
vis prettier stylua shfmt ruff go
pipewire-pulse wireplumber pavucontrol
power-profiles-daemon python-gobject
