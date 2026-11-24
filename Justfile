# BlueBuild helpers for DayOS. All commands run from the repository root.
export recipe := env("RECIPE", "recipes/main.yml")
export vm_recipe := env("VM_RECIPE", "recipes/virtual.yml")
export image_name := env("IMAGE_NAME", "dayos")
export image_registry := env("IMAGE_REGISTRY", "ghcr.io/sannyday")
export bib_image := env("BIB_IMAGE", "quay.io/centos-bootc/bootc-image-builder:latest")

[private]
default:
    @just --list

# Build the image locally with the BlueBuild CLI
build:
    bluebuild build --skip-validation {{ recipe }}

# Write the Containerfile generated from the recipe to ./Containerfile
generate:
    bluebuild generate --skip-validation {{ recipe }} --output Containerfile

# Rebase this machine onto a locally built image
switch:
    sudo bluebuild switch --skip-validation {{ recipe }}

# Build an installer ISO from the published image
iso:
    sudo bluebuild generate-iso --iso-name {{ image_name }}.iso image {{ image_registry }}/{{ image_name }}:latest

# Build an installer ISO from a locally built image
iso-local:
    sudo bluebuild generate-iso --iso-name {{ image_name }}.iso local {{ image_name }}:latest

# Build a qcow2 from the published image
qcow2:
    podman pull {{ image_registry }}/{{ image_name }}:latest
    sudo podman run --rm --privileged --pull=newer --security-opt label=type:unconfined_t \
        -v ./output:/output \
        -v /var/lib/containers/storage:/var/lib/containers/storage \
        {{ bib_image }} \
        --type qcow2 --rootfs btrfs --local \
        --output /output {{ image_registry }}/{{ image_name }}:latest

# Build the non-NVIDIA VM test image locally (rootful)
image-vm:
    sudo bluebuild build --skip-validation {{ vm_recipe }}

# Build a qcow2 from the locally built VM image
qcow2-vm:
    sudo podman run --rm --privileged --pull=newer --security-opt label=type:unconfined_t \
        -v ./output-vm:/output \
        -v /var/lib/containers/storage:/var/lib/containers/storage \
        {{ bib_image }} \
        --type qcow2 --rootfs btrfs --local \
        --output /output localhost/dayos-vm:latest
    sudo chown -R "$(id -u):$(id -g)" output-vm

# Run shellcheck on every shell script
lint:
    #!/usr/bin/env bash
    set -euo pipefail
    if ! command -v shellcheck > /dev/null; then
        echo "shellcheck is not installed" >&2
        exit 1
    fi
    find . -iname "*.sh" -type f -exec shellcheck {} +

# Remove local build artifacts
clean:
    rm -rf Containerfile output output-vm *.iso *.iso-CHECKSUM
