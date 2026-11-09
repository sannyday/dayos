# DayOS

[![bluebuild build badge](https://github.com/sannyday/dayos/actions/workflows/build.yml/badge.svg)](https://github.com/sannyday/dayos/actions/workflows/build.yml)

DayOS is a personal, custom [Bazzite](https://bazzite.gg) image built with
[BlueBuild](https://blue-build.org). It starts from the Universal Blue
`bazzite-nvidia` base and layers a Hyprland desktop, the Nix package manager,
Nerd Fonts, and a handful of machine-specific system tweaks on top.

The build is defined in [`recipes/recipe.yml`](recipes/recipe.yml); everything
else in the repository is input for the BlueBuild modules.

## What's included

- **Hyprland** with UWSM, `hyprpolkitagent`, and `xdg-desktop-portal-hyprland`
- **Nix** with the daemon enabled and `/nix` bind-mounted from `/var/home/nix`
- **Nerd Fonts** from the `aquacash5/nerd-fonts` COPR
- Desktop tools: Ghostty, Fuzzel, cliphist, Noctalia, GParted, VeraCrypt,
  ecryptfs, proxychains-ng, and the `lgl-vm-curator` helper
- **System configuration** from [`files/system/`](files/system):
  GRUB menu timeout, `rpm-ostreed` staging of automatic updates,
  podman socket, autologin into the UWSM-managed Hyprland session, and
  relocation of Flatpak data to `/var/home/flatpak`
- **systemd units** from [`files/systemd/system/`](files/systemd/system) for the
  Nix mount/copy/group setup and the Flatpak relocation service

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
bluebuild build recipes/recipe.yml
```

Useful helpers are also available through `just`:

```bash
just build       # bluebuild build
just generate    # write the generated Containerfile to ./Containerfile
just switch      # rebase this machine onto the locally built image
just iso         # build an installer ISO from the published image
```

To inspect what BlueBuild generates without building:

```bash
bluebuild generate recipes/recipe.yml -o Containerfile
```

## ISO and disk images

BlueBuild can build an installer ISO directly from the published image:

```bash
sudo bluebuild generate-iso --iso-name dayos.iso image ghcr.io/sannyday/dayos:latest
```

The repository also keeps the `bootc-image-builder` based
[`build-disk.yml`](.github/workflows/build-disk.yml) workflow, which produces
`qcow2` and `anaconda-iso` images as job artifacts (or uploads them to S3 if
the corresponding secrets are configured). The ISO kickstart in
[`disk_config/iso.toml`](disk_config/iso.toml) hardcodes
`ghcr.io/sannyday/dayos:latest`; update it if you fork the image under a
different name.

## Repository layout

```text
recipes/recipe.yml        # BlueBuild build definition
files/system/             # copied into the image root (/), e.g. /etc, /usr
files/systemd/system/     # systemd units -> /usr/lib/systemd/system
disk_config/              # bootc-image-builder configurations
.github/workflows/        # image build (BlueBuild) + disk image build
cosign.pub                # public key for image verification
```

## Customization notes

- Add or remove packages, COPR repositories, and units in
  [`recipes/recipe.yml`](recipes/recipe.yml). Modules run top to bottom.
- Put configuration files under `files/system/` using the path they should
  have inside the image (for example `files/system/etc/default/grub`).
- Put systemd units under `files/systemd/system/`; the `systemd` module copies
  them to `/usr/lib/systemd/system` and enables them.
- `files/system/etc/fstab.tower` and `files/system/etc/crypttab.tower` are
  reference copies for the `tower` machine and are **not** applied because of
  the `.tower` suffix. Rename them if you want them to take effect.
- `files/system/etc/plasmalogin.conf` autologins the local user `day`; change
  the user name there if your account differs.

## License

DayOS is distributed under the terms of the [Apache License 2.0](LICENSE).
It is based on [Universal Blue](https://universal-blue.org) images and built
with [BlueBuild](https://blue-build.org).
