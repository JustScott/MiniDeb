#!/bin/bash
# finish_install.sh - part of the MiniDeb project
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

apt update

apt install -y gnome locales efibootmgr efivar linux-image-amd64 \
    grub-efi-amd64-bin network-manager

dpkg-reconfigure tzdata
dpkg-reconfigure locales

locale-gen

grub-install --efi-directory=/boot
grub-mkconfig -o /boot/grub/grub.cfg
update-initramfs -u

apt install sudo

useradd -UmG sudo -s /bin/bash test_user

echo "test_user":"test" | chpasswd

systemctl enable NetworkManager

