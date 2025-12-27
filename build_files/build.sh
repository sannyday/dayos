#!/bin/bash

set -ouex pipefail

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

# this installs a packages from COPR repos
dnf5 -y copr enable sdegler/hyprland
dnf5 -y copr enable tofik/nwg-shell
dnf5 -y copr enable erikreider/SwayNotificationCenter
dnf5 -y copr enable errornointernet/quickshell
dnf5 -y copr enable aquacash5/nerd-fonts

readarray -t pkgs < <(cat /ctx/fonts /ctx/hypr | grep -v \#)
dnf5 -y --enablerepo=terra install ${pkgs[*]}

dnf5 -y copr disable sdegler/hyprland
dnf5 -y copr disable tofik/nwg-shell
dnf5 -y copr disable erikreider/SwayNotificationCenter
dnf5 -y copr disable errornointernet/quickshell
dnf5 -y copr disable aquacash5/nerd-fonts

# install VirtualBox
/ctx/virtualbox.sh
# install Determinate Nix
/ctx/nix.sh

#### Example for enabling a System Unit File

systemctl enable podman.socket

mkdir /nix
