# MiniDeb

Scripts to setup a minimal, opinionated, Gnome-based Debian Linux system.

## Usage

First, ensure you are connected to Ethernet or WiFi. Then clone the repository 
and run `start_install.sh`:

```bash
apt update
apt install git
git clone https://www.github.com/JustScott/MiniDeb
bash ./MiniDeb/start_install.sh
```

### Script Completion Handling
A `start_install_completion.txt` file is created as the script is
ran so that if any command in the script fails, you can resolve
the issue and run `bash ./MiniDeb/start_install.sh` again for it
to start after the last successfully ran command.
  * If you want to restart the script, just delete the completion
    file
  * If you want to start from a specific command/position in the 
    script, you can just delete up to and including that command
  * Or you can even just delete a specific command to just rerun
    that command

There is also a `finish_install_completion.txt` file located at /mnt/
that tracks the completion of `finish_install.sh`. All the rules above
regarding `start_install` apply the same.
