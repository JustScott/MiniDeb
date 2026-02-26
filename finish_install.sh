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

INSTALLATION_VARIABLES_FILE=/activate_installation_variables.sh

PRETTY_OUTPUT_LIBRARY=/pretty_output_library.sh

if ! source $PRETTY_OUTPUT_LIBRARY &>/dev/null
then
    printf "\n\n\e[31m%s %s\e[0m\n\n" \
        "[!] Couldn't source the pretty output library. Make sure" \
        "to run bash ./MiniDeb/start_install.sh."
    exit 1
fi

if ! source $INSTALLATION_VARIABLES_FILE &>/dev/null
then
    printf "\n\n\e[31m%s %s\e[0m\n\n" \
        "[!] Couldn't source the installation variable. Make sure" \
        "to run \`bash ./MiniDeb/start_install.sh\` first"
    exit 1
fi

if [[ -z "$admin_password" ]]
then
    printf "\n\n\e[31m%s\e[0m\n\n" \
        "[!] No admin password set. Make sure to run start_install.sh first"
    exit 1
fi

if [[ -z "$username" ]]
then
    printf "\n\n\e[31m%s\e[0m\n\n" \
        "[!] No username set. Make sure to run start_install.sh first"
    exit 1
fi


apt update >>"$STDOUT_LOG_PATH" 2>>"$STDERR_LOG_PATH" &
task_output $! "$STDERR_LOG_PATH" "Update apt"
[[ $? -ne 0 ]] && exit 1


apt install -y gnome locales efibootmgr efivar linux-image-amd64 \
    grub-efi-amd64-bin network-manager sudo \
    >>"$STDOUT_LOG_PATH" 2>>"$STDERR_LOG_PATH" &
task_output $! "$STDERR_LOG_PATH" "Install system packages and gnome"
[[ $? -ne 0 ]] && exit 1

{
    # Set the keyboard orientation
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
    export LANG="en_US.UTF-8"
    echo "LANG=$LANG" > /etc/locale.conf
} >>"$STDOUT_LOG_PATH" 2>>"$STDERR_LOG_PATH" &
task_output $! "$STDERR_LOG_PATH" "Configure locale: 'en_US.UTF-8'"
[[ $? -ne 0 ]] && exit 1

if [[ -n "$user_timezone" ]]
then
    ln -sf /usr/share/zoneinfo/America/Chicago /etc/localtime \
        >>"$STDOUT_LOG_PATH" 2>>"$STDERR_LOG_PATH" &
    task_output $! "$STDERR_LOG_PATH" "Set timezone: 'America/Chicago'"
    [[ $? -ne 0 ]] && exit 1
fi

locale-gen >>"$STDOUT_LOG_PATH" 2>>"$STDERR_LOG_PATH" &
task_output $! "$STDERR_LOG_PATH" "Generate locale"
[[ $? -ne 0 ]] && exit 1

grub-install --efi-directory=/boot \
    >>"$STDOUT_LOG_PATH" 2>>"$STDERR_LOG_PATH" &
task_output $! "$STDERR_LOG_PATH" "Install grub"
[[ $? -ne 0 ]] && exit 1

grub-mkconfig -o /boot/grub/grub.cfg \
    >>"$STDOUT_LOG_PATH" 2>>"$STDERR_LOG_PATH" &
task_output $! "$STDERR_LOG_PATH" "Configure grub"

update-initramfs -u \
    >>"$STDOUT_LOG_PATH" 2>>"$STDERR_LOG_PATH" &
task_output $! "$STDERR_LOG_PATH" "Update the initramfs"

useradd -UmG sudo -s /bin/bash administrator \
    >>"$STDOUT_LOG_PATH" 2>>"$STDERR_LOG_PATH" &
task_output $! "$STDERR_LOG_PATH" "Create administrator account"
[[ $? -ne 0 ]] && exit 1

echo administrator:"$admin_password" | chpasswd \
    >>"$STDOUT_LOG_PATH" 2>>"$STDERR_LOG_PATH" &
task_output $! "$STDERR_LOG_PATH" "Set administrator password"
[[ $? -ne 0 ]] && exit 1

useradd -Um -s /bin/bash $username  \
    >>"$STDOUT_LOG_PATH" 2>>"$STDERR_LOG_PATH" &
task_output $! "$STDERR_LOG_PATH" "Create user account: '$username'"
[[ $? -ne 0 ]] && exit 1

passwd -d $username >>"$STDOUT_LOG_PATH" 2>>"$STDERR_LOG_PATH" &
task_output $! "$STDERR_LOG_PATH" "Make user account passwordless"
[[ $? -ne 0 ]] && exit 1

echo -e "[User]\nUserAccount=true" \
    > /var/lib/AccountsService/users/administrator &
task_output $! "$STDERR_LOG_PATH" "Remove administrator from gdm login screen"
[[ $? -ne 0 ]] && exit 1

systemctl enable NetworkManager >>"$STDOUT_LOG_PATH" 2>>"$STDERR_LOG_PATH" &
task_output $! "$STDERR_LOG_PATH" "Enable NetworkManager service"
[[ $? -ne 0 ]] && exit 1
