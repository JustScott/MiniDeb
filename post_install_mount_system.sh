#!/bin/bash
# post_install_mount_system.sh - part of the DebianInstaller project
# Copyright (C) 2026, Scott Wyman, development@scottwyman.me
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

# For mounting the system in a live environment after installation is
# finished to fix any issues

# Uses the variables in `install_constants`

INSTALL_CONSTANTS_FILE=./DebianInstaller/install_constants

if ! source $INSTALL_CONSTANTS_FILE &>/dev/null
then
    printf "\n\n\e[31m%s %s\e[0m\n\n" \
        "[!] Couldn't source the install_constants file. Make sure" \
        "to run \`bash ./DebianInstaller/start_install.sh\`"
    exit 1
fi

if [[ "$(whoami)" != "root" ]]
then
    printf "\n\e[31m%s\e[0m\n" "[!] Must run script as root"
    exit 1
fi

check_required_install_constants()
{
    if [[ -z "$EFI_PARTITION" ]]
    then
        printf "\n\e[31m%s\e[0m\n" \
            "[!] \$EFI_PARTITION constant not set, this is fatal...stopping"
        return 1
    fi
    if [[ -z "$BOOT_PARTITION" ]]
    then
        printf "\n\e[31m%s\e[0m\n" \
            "[!] \$BOOT_PARTITION constant not set, this is fatal...stopping"
        return 1
    fi
    if [[ -z "$ROOT_PARTITION" ]]
    then
        printf "\n\e[31m%s\e[0m\n" \
            "[!] \$ROOT_PARTITION constant not set, this is fatal...stopping"
        return 1
    fi
    if [[ -z "$KEYFILE_PARTITION" ]]
    then
        printf "\n\e[31m%s\e[0m\n" \
            "[!] \$KEYFILE_PARTITION constant not set, this is fatal...stopping"
        return 1
    fi

    return 0
}

check_required_install_constants || exit 1

mkdir -p /media/keyfile_usb
mount $KEYFILE_PARTITION /media/keyfile_usb/

cryptsetup open --key-file /media/keyfile_usb/luks_keyfile $ROOT_PARTITION cryptdisk

mount /dev/mapper/cryptdisk /mnt
mount $BOOT_PARTITION /mnt/boot
mount $EFI_PARTITION /mnt/boot/efi

if ! cmp -s ./DebianInstaller/fake_windows_boot_name.sh \
    /mnt/fake_windows_boot_name.sh &>/dev/null
then
    cp ./DebianInstaller/fake_windows_boot_name.sh \
        /mnt/fake_windows_boot_name.sh &>/dev/null
fi
