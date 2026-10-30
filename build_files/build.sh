#!/bin/bash

set -ouex pipefail

### Install packages

# this installs a packages from COPR repos
#dnf5 -y copr enable sdegler/hyprland
dnf5 -y copr enable ashbuk/Hyprland-Fedora
dnf5 -y copr enable tofik/nwg-shell
dnf5 -y copr enable erikreider/SwayNotificationCenter
dnf5 -y copr enable aquacash5/nerd-fonts
dnf5 -y copr enable avengemedia/dms-git
dnf5 -y copr enable gregoryloscombe/mangowc
dnf5 -y copr enable scottames/ghostty
dnf5 -y copr enable theblackdon/dcli-bootc

readarray -t pkgs < <(cat /ctx/fonts /ctx/hypr | grep -v \#)
dnf5 -y install --skip-unavailable ${pkgs[*]}

#dnf5 -y copr disable sdegler/hyprland
dnf5 -y copr disable ashbuk/Hyprland-Fedora
dnf5 -y copr disable tofik/nwg-shell
dnf5 -y copr disable erikreider/SwayNotificationCenter
dnf5 -y copr disable aquacash5/nerd-fonts
dnf5 -y copr disable avengemedia/dms-git
dnf5 -y copr disable gregoryloscombe/mangowc
dnf5 -y copr disable scottames/ghostty
dnf5 -y copr disable theblackdon/dcli-bootc

#/ctx/veracrypt.sh
#/ctx/virtualbox.sh

#### Example for enabling a System Unit File

systemctl enable podman.socket

mkdir /nix
