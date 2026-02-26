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

# TODO: Add logic for selecting disk
disk="/dev/vda"
efi_partition="/dev/vda1"
root_partition="/dev/vda2"

INSTALLATION_VARIABLES_FILE=/tmp/activate_installation_variables.sh

PRETTY_OUTPUT_LIBRARY=./MiniDeb/pretty_output_library.sh

if ! source $PRETTY_OUTPUT_LIBRARY &>/dev/null
then
    printf "\n\n\e[31m%s %s\e[0m\n\n" \
        "[!] Couldn't source the pretty output library. Make sure" \
        "to run \`bash ./MiniDeb/start_install.sh\`"
    exit 1
fi

{
    get_name() {
        declare -g name=""
        local name_verify

        while : 
        do
            read -p 'Enter Name: ' name
            read -p 'Verify Name: ' name_verify

            if [[ -z "$name" ]]
            then
                clear
                echo -e " - Name Can't Be Empty - \n"
                continue
            fi

            if [[ $name == $name_verify ]]
            then
                clear
                echo -e " - Set as '$name' - \n"
                sleep .5
                break
            else 
                clear
                echo -e " - Names Don't Match - \n"
            fi
        done
    }

    get_user_password() {
        declare -g user_password=""
        local user_password_verify

        echo -e "\n - Set Password for '$1' - "
        while :
        do
            read -s -p 'Set Password: ' user_password
            read -s -p $'\nverify Password: ' user_password_verify

            if [[ $user_password == $user_password_verify ]]
            then
                clear
                echo -e " - Set password for $1! - \n"
                sleep 1
                break
            else
                clear
                echo -e " - Passwords Don't Match - \n"
            fi
        done
    }
}

if [[ "$(whoami)" != "root" ]]
then
    printf "\n\e[31m%s\e[0m\n" "[!] Must run script as root"
    exit 1
fi

if ! grep "^admin_password=" $INSTALLATION_VARIABLES_FILE &>/dev/null
then
    clear 
    echo -e "* Prompt [1/2] *\n"
    get_user_password "administrator"
    echo -e "\nadmin_password=\"$user_password\"" >> $INSTALLATION_VARIABLES_FILE
fi

if ! grep "^username=" $INSTALLATION_VARIABLES_FILE &>/dev/null
then
    clear
    echo -e "* Prompt [2/2] *\n"
    echo ' - Set User Name - '
    get_name
    if [[ -z "$name" ]]; then
        echo -e \
            "\n - [ERROR] Failed to get a user name, this shouldn't happen... stopping - \n"
        exit 1
    fi
    echo -e "\nusername=\"$name\"" >> $INSTALLATION_VARIABLES_FILE
fi

apt update >>"$STDOUT_LOG_PATH" 2>>"$STDERR_LOG_PATH" &
task_output $! "$STDERR_LOG_PATH" "Update apt"
[[ $? -ne 0 ]] && exit 1

apt install -y arch-install-scripts debootstrap \
    >>"$STDOUT_LOG_PATH" 2>>"$STDERR_LOG_PATH" &
task_output $! "$STDERR_LOG_PATH" \
    "Install arch-install-scripts and debootstrap"
[[ $? -ne 0 ]] && exit 1

echo 'y' | mkfs.fat -F 32 /dev/vda1 \
    >>"$STDOUT_LOG_PATH" 2>>"$STDERR_LOG_PATH" &
task_output $! "$STDERR_LOG_PATH" "Format boot partition with FAT32"
[[ $? -ne 0 ]] && exit 1
echo 'y' | mkfs.ext4 /dev/vda2 \
    >>"$STDOUT_LOG_PATH" 2>>"$STDERR_LOG_PATH" &
task_output $! "$STDERR_LOG_PATH" "Configure System For EXT4"
[[ $? -ne 0 ]] && exit 1

mount /dev/vda2 /mnt >>"$STDOUT_LOG_PATH" 2>>"$STDERR_LOG_PATH" &
task_output $! "$STDERR_LOG_PATH" "Mount the root partition"
[[ $? -ne 0 ]] && exit 1

mount --mkdir /dev/vda1 /mnt/boot >>"$STDOUT_LOG_PATH" 2>>"$STDERR_LOG_PATH" &
task_output $! "$STDERR_LOG_PATH" "Mount the boot partition"
[[ $? -ne 0 ]] && exit 1

mkswap -U clear --size 4G --file /mnt/swapfile \
    >>"$STDOUT_LOG_PATH" 2>>"$STDERR_LOG_PATH" &
task_output $! "$STDERR_LOG_PATH" "Create 4GB swapfile"
[[ $? -ne 0 ]] && exit 1

swapon /mnt/swapfile >>"$STDOUT_LOG_PATH" 2>>"$STDERR_LOG_PATH" &
task_output $! "$STDERR_LOG_PATH" "Enable the swapfile"
[[ $? -ne 0 ]] && exit 1

debootstrap --arch amd64 stable /mnt https://deb.debian.org/debian \
    >>"$STDOUT_LOG_PATH" 2>>"$STDERR_LOG_PATH" &
task_output $! "$STDERR_LOG_PATH" "Run debootstrap"
[[ $? -ne 0 ]] && exit 1

genfstab -U /mnt > /mnt/etc/fstab >>"$STDOUT_LOG_PATH" 2>>"$STDERR_LOG_PATH" &
task_output $! "$STDERR_LOG_PATH" "Generate the fstab file"
[[ $? -ne 0 ]] && exit 1

cp /etc/hosts /mnt/etc/hosts >>"$STDOUT_LOG_PATH" 2>>"$STDERR_LOG_PATH" &
task_output $! "$STDERR_LOG_PATH" "Copy the hosts file to the new system"
[[ $? -ne 0 ]] && exit 1

cp ./MiniDeb/configuration_files/sources.list /mnt/etc/apt/sources.list \
    >>"$STDOUT_LOG_PATH" 2>>"$STDERR_LOG_PATH" &
task_output $! "$STDERR_LOG_PATH" "Copy sources.list to the new system"
[[ $? -ne 0 ]] && exit 1

echo "debian" > /mnt/etc/hostname >>"$STDOUT_LOG_PATH" 2>>"$STDERR_LOG_PATH" &
task_output $! "$STDERR_LOG_PATH" "Set the new systems hostname to 'debian'"
[[ $? -ne 0 ]] && exit 1

{
    cp $PRETTY_OUTPUT_LIBRARY /mnt
    cp ./MiniDeb/finish_install.sh /mnt
    cp $INSTALLATION_VARIABLES_FILE /mnt
} >>"$STDOUT_LOG_PATH" 2>>"$STDERR_LOG_PATH" &
task_output $! "$STDERR_LOG_PATH" \
    "Copy over finish_install.sh to the new system"
[[ $? -ne 0 ]] && exit 1

arch-chroot /mnt /bin/bash finish_install.sh
