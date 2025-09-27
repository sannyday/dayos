#!/bin/bash

set -ouex pipefail

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

# this installs a packages from fedora repos
dnf5 -y install ecryptfs-utils

# this installs a packages from COPR repos
dnf5 -y copr enable solopasha/hyprland
dnf5 -y copr enable che/nerd-fonts
dnf5 -y copr enable tofik/nwg-shell
dnf5 -y copr enable erikreider/SwayNotificationCenter
dnf5 -y copr enable errornointernet/quickshell
dnf5 -y install hypridle hyprland hyprlock rofi-wayland seatd SwayNotificationCenter waybar swww mpvpaper cliphist quickshell nerd-fonts
dnf5 -y copr disable solopasha/hyprland
dnf5 -y copr disable che/nerd-fonts
dnf5 -y copr disable tofik/nwg-shell
dnf5 -y copr disable erikreider/SwayNotificationCenter
dnf5 -y copr disable errornointernet/quickshell

# install VirtualBox
/ctx/virtualbox.sh

#### Example for enabling a System Unit File

systemctl enable podman.socket

mkdir /nix
