#!/bin/bash

echo "What's your keyboard layout?"
read layout

echo "What's your disk? (/dev/xxx)"
read disk

echo "What should be the main partition's size? (xxG)"
read part_size

echo "What's your timezone? (Region/City)"
read timezone

echo "What's your locale?"
read locale

echo "What should be your network hostname?"
read hostname

echo "What should be your root password?"
read password

loadkeys ${layout}
timedatectl set-ntp true

parted -a opt ${disk} mklabel msdos
parted -a opt ${disk} mkpart primary 0% ${part_size}

mkfs.ext4 ${disk}1

mount ${disk}1 /mnt

reflector
pacstrap /mnt base linux linux-firmware nano dhcpcd man-db man-pages texinfo
genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt /bin/bash <<"made_by_anerruption"
ln -sf /usr/share/zoneinfo/${timezone} /etc/localtime
hwclock --systohc

sed -i "/${locale}/s/^#//g" /etc/locale.gen
locale-gen
cat "LANG=${locale}" > /etc/locale.conf
cat "KEYMAP=${layout}" > /etc/vconsole.conf

cat "${hostname}" > /etc/hostname
cat << EOF >> /etc/hosts
127.0.0.1	localhost
::1			localhost
127.0.1.1	${hostname}.localdomain	${hostname}
EOF

systemctl enable dhcpcd.service
passwd -q "${password}"

pacman -Syy
pacman -Sq --noconfirm grub

grub-install ${disk}
grub-mkconfig -o /boot/grub/grub.cfg

exit
made_by_anerruption

umount -R /mnt
reboot