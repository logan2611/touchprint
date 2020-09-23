TouchPrint is very customizable, and both the GUI and/or OctoPrint can be disabled if you already have an existing setup to perform those tasks.

# Table of Contents
- [Screenshots](#screenshots)
- [Requirements](#requirements)
- [Quick Setup Guide](#quick-setup-guide)
  - [Flashing on Windows/Mac OS/Linux \(Easy\)](#flashing-on-windowsmac-oslinux-easy)
  - [Flashing on Mac OS/Linux/BSD \(Recommended\)](#flashing-in-mac-oslinuxbsd-recommended)
  - [First Boot](#first-boot)
  - [OctoPrint Setup](#octoprint-setup)
  - [Accessing OctoPrint](#accessing-octoprint)
  - [Configuring TouchPrint](#configuring-touchprint)
- [Reporting Bugs](#reporting-bugs)

# Screenshots
TODO

# Requirements
### Minimum:
- Raspberry Pi 3
- 8GB microSD card
- Keyboard and video for first time setup

### Recommended:
- Raspberry Pi 4
- 8GB Class 10 microSD card
- Keyboard and video for first time setup

# Quick Setup Guide
### Flashing on Windows/Mac OS/Linux (Easy)
1. Download and install [balenaEtcher](https://www.balena.io/etcher/).
2. Download the [latest image from the releases section](/releases).
3. Follow the on screen instructions in Etcher to burn the image to your microSD or [USB drive](https://www.raspberrypi.org/documentation/hardware/raspberrypi/bootmodes/msd.md).

### Flashing in Mac OS/Linux/BSD (Recommended)
1. Download the [latest image from the releases section](/releases).
2. Open a terminal and navigate to where you downloaded the image file.
3. Ensure that xz is installed on your computer.

    | **OS**        | **Command**            |
    |---------------|------------------------|
    | Ubuntu/Debian | `apt install xz-utils` |
    | Arch/Manjaro  | `pacman -S xz`         |
    | Mac OS        | `brew install xz`      |

4. Run `xz -d -c IMAGE_NAME.img.xz | sudo dd of=/dev/sdX`, replacing IMAGE\_NAME and /dev/sdX with the appropriate paths, and adding flags per your preferences.

### First Boot
1. Connect an HDMI cable and a keyboard to your Raspberry Pi.
2. Power on your Raspberry Pi and wait for it to boot.
3. Once booted, you will be put into the first time setup, where you can configure networking, choose which services you want to run, etc.
  - Use the arrow keys to move the "cursor", Spacebar to toggle checkboxes, Tab to move the cursor between different sections, and Enter to continue.
4. Once the first time setup is complete, the Raspberry Pi will reboot.

### OctoPrint Setup
- If the GUI is enabled, you can setup OctoPrint on the Raspberry Pi. You can also setup OctoPrint by opening up a web browser on another computer and navigating to `https://RPI-IP`, replacing RPI-IP with the IP address of your Raspberry Pi.
- If MJPG-Streamer is enabled, you can put `/webcam` into the Stream URL box to enable it in OctoPrint.
- If you wish to enable timelapses, the path to ffmpeg is `/usr/bin/ffmpeg`.

### Accessing OctoPrint
- If OctoPrint is enabled, you can access it at `https://RPI-IP`, replacing RPI-IP with the IP address of your Raspberry Pi.

### Configuring TouchPrint
- TouchPrint can be configured either over SSH or in a TTY using the `tp-config` script. This script is provided to make management of core features easier and to consolidate TouchPrint's settings into one place.
- OctoPrint can be configured through the OctoPrint UI as normal.

# Reporting Bugs
Please report any bugs by [filing an issue](/issues). Please include as much detail as you can, including (but not limited to):
- Raspberry Pi Model
- Version of TouchPrint
- What you were doing when the bug/issue occured
- Steps to reproduce
- Logs
