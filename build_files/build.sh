#!/bin/bash

set -ouex pipefail

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

# this installs a packages from fedora repos
dnf5 -y install ecryptfs-utils gparted

# this installs a packages from COPR repos
dnf5 -y copr enable solopasha/hyprland
dnf5 -y install hypridle hyprland hyprlock rofi-wayland seatd SwayNotificationCenter waybar swww mpvpaper cliphist
dnf5 -y copr disable solopasha/hyprland

#### Example for enabling a System Unit File

systemctl enable podman.socket

mkdir /nix
