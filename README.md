# DayOS

[![bluebuild build badge](https://github.com/sannyday/dayos/actions/workflows/build.yml/badge.svg)](https://github.com/sannyday/dayos/actions/workflows/build.yml)

DayOS is a personal, custom [Bazzite](https://bazzite.gg) image built with
[BlueBuild](https://blue-build.org). It starts from the Universal Blue
`bazzite-nvidia` base, removes the KDE Plasma desktop/applications and Lutris,
and layers Hyprland, labwc, the Nix package manager, Nerd Fonts, and a handful
of machine-specific system tweaks on top.

The build is defined in [`recipes/main.yml`](recipes/main.yml); shared
modules live in [`recipes/common.yml`](recipes/common.yml).

## What's included

- **Hyprland** with UWSM, `hyprpolkitagent`, and `xdg-desktop-portal-hyprland`
- **labwc**, a lightweight wlroots-based Wayland compositor
- **KDE Plasma and Lutris removed** from the Bazzite base to reduce image
  size; Flatpaks are left untouched
- **greetd + tuigreet 0.11.1**, a lightweight login manager with Rose Pine
  theme, matrix background, and `Alt+C/S/P/B` menus
- **Nix** with the daemon enabled and `/nix` bind-mounted from `/var/home/nix`;
  Nix trust is aligned with the UID 1000 account at boot
- **Nerd Fonts** from the `aquacash5/nerd-fonts` COPR
- **Default Flatpaks** from Flathub, installed by a boot-time timer rather
  than baked into the image
- Desktop tools: Ghostty, Fuzzel, cliphist, Noctalia, GParted, VeraCrypt,
  ecryptfs, proxychains-ng, and the `lgl-vm-curator` helper
- **System configuration** from [`files/main/00-init/`](files/main/00-init):
  GRUB menu timeout, `rpm-ostreed` staging of automatic updates,
  podman socket, and relocation of Flatpak data to `/var/home/flatpak`
- **systemd units** from [`files/systemd/system/`](files/systemd/system) for the
  Nix mount/copy/group setup, UID 1000 user configuration, greetd, and the
  Flatpak relocation service

## Flatpaks

The Flatpaks in the `default-flatpaks` module of
[`recipes/main.yml`](recipes/main.yml) are **not baked into the image**.
A systemd timer (`system-flatpak-setup.timer`) runs about 30 seconds after
boot and installs anything missing from Flathub, similar to Bazzite's default
apps.

Notifications are disabled (`notify: false`); set it to `true` if you want a
desktop notification when the setup runs. On a running system,
`bluebuild-flatpak-manager` can show the configuration and disable or
re-enable the automatic setup.

## Installation

> [!WARNING]
> Rebasing to a custom image is experimental. Make sure you have a working
> rollback path before switching.

The image is signed with cosign. To move an existing Bazzite/atomic Fedora
installation onto DayOS, rebase to the unsigned image first so the signing
policy can be installed, then switch to the signed image:

```bash
# 1. Rebase to the unsigned image to install the signing keys/policy
sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/sannyday/dayos:latest
systemctl reboot

# 2. Rebase to the signed image
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/sannyday/dayos:latest
systemctl reboot
```

The `latest` tag always points at the newest build. DayOS tracks the `stable`
tag of `ghcr.io/ublue-os/bazzite-nvidia`, so it stays on the same Bazzite
release until the base image is changed in the recipe.

## Verification

Download [`cosign.pub`](cosign.pub) from this repository and verify the image
signature:

```bash
cosign verify --key cosign.pub ghcr.io/sannyday/dayos:latest
```

## Building locally

Install the [BlueBuild CLI](https://github.com/blue-build/cli#installation),
then build the recipe with podman:

```bash
bluebuild build --skip-validation recipes/main.yml
```

Useful helpers are also available through `just`:

```bash
just build       # bluebuild build --skip-validation
just generate    # write the generated Containerfile to ./Containerfile
just switch      # rebase this machine onto the locally built image
just iso         # build an installer ISO from the published image
```

To inspect what BlueBuild generates without building:

```bash
bluebuild generate --skip-validation recipes/main.yml -o Containerfile
```

## VM test image

The main image uses the NVIDIA base and needs GPU passthrough in a VM. The
`dayos-vm` variant uses the plain `bazzite` base:

```bash
just image-vm    # build localhost/dayos-vm:latest
just qcow2-vm    # convert it to output-vm/*.qcow2
```

The VM recipe creates a `test` / `test` account in the `wheel` group on first
boot, managed by `files/virtual/06-vm`. Change the password with `passwd` after logging
in.

The anaconda-iso path is not supported with the official CentOS-based BIB for
this Fedora image, so use the qcow2 above.

## Disk images

The repository keeps the `bootc-image-builder` based
[`build-disk.yml`](.github/workflows/build-disk.yml) workflow, which produces a
`qcow2` image as a job artifact (or uploads it to S3 if the corresponding
secrets are configured). It uses the official
`quay.io/centos-bootc/bootc-image-builder:latest` builder.

`just qcow2` builds a qcow2 from the published image; `just qcow2-vm` builds one
from the locally built VM image.

## Repository layout

```text
recipes/main.yml        # main NVIDIA image definition
recipes/virtual.yml     # non-NVIDIA VM test variant
recipes/common.yml      # shared modules imported by both recipes
recipes/greet.yml       # greetd/tuigreet, session menu
recipes/guards.yml      # main-only build guards
files/main/00-init/       # base system config
files/main/02-noscripts/  # DNF noscripts drop-in
files/main/04-greetd/     # greetd config
files/main/05-sessions/   # hyprland/terminal entries
files/main/06-autologin/  # main-only autologin
files/main/08-theming/    # tuigreet theme/matrix
files/virtual/00-init/    # duplicate shared base config
files/virtual/02-noscripts/
files/virtual/04-greetd/
files/virtual/05-sessions/
files/virtual/06-vm/      # VM-only test account
files/virtual/08-theming/
files/systemd/            # systemd module units, untouched
disk_config/              # bootc-image-builder configurations
.github/workflows/        # image build (BlueBuild) + disk image build
cosign.pub                # public key for image verification
```

## Customization notes

- Shared modules live in [`recipes/common.yml`](recipes/common.yml); both
  recipes import them with `from-file: common.yml`. Image-specific modules
  stay in the recipe.
- Add or remove shared packages, COPR repositories, and units in
  [`recipes/common.yml`](recipes/common.yml). Modules run top to bottom.
- KDE Plasma, its applications, and Lutris are removed declaratively with
  `dnf.remove`; `systemd.masked` blocks the old display-manager alias.
  Flatpaks are not touched.
- The removal list was audited against a snapshot of the packages installed on
  the running DayOS system; it is not used by the build.
- Put configuration files under `files/main/` or `files/virtual/` using the
  numbered stage and the path inside the image (for example
  `files/main/00-init/etc/default/grub`). Shared files are duplicated in both
  trees; keep them in sync. `files/systemd/` is untouched.
- Put systemd units under `files/systemd/system/`; the `systemd` module copies
  them to `/usr/lib/systemd/system` and enables them.
- `files/main/00-init/etc/fstab.tower` and `files/main/00-init/etc/crypttab.tower` are
  reference copies for the `tower` machine and are **not** applied because of
  the `.tower` suffix. Rename them if you want them to take effect.
- `files/main/00-init/etc/nix/nix.conf` keeps `trusted-users = day`; at boot
  `dayos-user-config.service` replaces it with the UID 1000 account name. If
  your account uses a different UID, adjust it in
  [`apply-user-config.sh`](files/main/00-init/usr/libexec/dayos/apply-user-config.sh).
- The image uses **greetd** with **tuigreet 0.11.1**. Sessions are read from
  `/usr/share/wayland-sessions` (`hyprland`, `labwc`, `terminal`). The main
  image autologins into `uwsm start -e -D Hyprland start-hyprland` as `day`;
  the VM shows the greeter.
- `recipes/guards.yml` is main-only and checks `/usr/bin/tuigreet`,
  `/usr/bin/uwsm`, `/usr/bin/Hyprland`, `/usr/bin/start-hyprland`, and the
  NVIDIA stack. `recipes/virtual.yml` has no guards.
- Session entries are `files/main/05-sessions/.../hyprland.desktop` (`Name=hyprland`,
  `Exec=/usr/bin/uwsm start -e -D Hyprland start-hyprland`) and
  `terminal.desktop` (`Name=terminal`).

## License

DayOS is distributed under the terms of the [Apache License 2.0](LICENSE).
It is based on [Universal Blue](https://universal-blue.org) images and built
with [BlueBuild](https://blue-build.org).
