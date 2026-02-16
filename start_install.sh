#!/bin/bash
#
# start_install.sh - part of the MiniDeb project
# Copyright (C) 2026, JustScott, development@justscott.me
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

disk="/dev/vda"
efi_partition="/dev/vda1"
root_partition="/dev/vda2"

if [[ "$(whoami)" != "root" ]]
then
    printf "\n\e[31m%s\e[0m\n" "[!] Must run script as root"
    exit 1
fi

apt update

apt install -y arch-install-scripts debootstrap

echo 'y' | mkfs.fat -F 32 /dev/vda1
echo 'y' | mkfs.ext4 /dev/vda2

mount /dev/vda2 /mnt
mount --mkdir /dev/vda1 /mnt/boot

mkswap -U clear --size 4G --file /mnt/swapfile
swapon /mnt/swapfile

if ! debootstrap --arch amd64 stable /mnt https://deb.debian.org/debian
then
    printf "\n\e[31m%s\e[0m\n" "[!] debootstrap failed"
    exit 1
fi

genfstab -U /mnt > /mnt/etc/fstab

cp /etc/hosts /mnt/etc/hosts

cp ./MiniDeb/sources.list /mnt/etc/apt/sources.list

echo "debian" > /mnt/etc/hostname

cp ./MiniDeb/finish_install.sh /mnt/

arch-chroot /mnt /bin/bash finish_install.sh
