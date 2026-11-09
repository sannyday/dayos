# BlueBuild helpers for DayOS. All commands run from the repository root.
export recipe := env("RECIPE", "recipes/recipe.yml")
export image_name := env("IMAGE_NAME", "dayos")
export image_registry := env("IMAGE_REGISTRY", "ghcr.io/sannyday")

[private]
default:
    @just --list

# Build the image locally with the BlueBuild CLI
build:
    bluebuild build {{ recipe }}

# Write the Containerfile generated from the recipe to ./Containerfile
generate:
    bluebuild generate {{ recipe }} --output Containerfile

# Rebase this machine onto a locally built image
switch:
    sudo bluebuild switch {{ recipe }}

# Build an installer ISO from the published image
iso:
    sudo bluebuild generate-iso --iso-name {{ image_name }}.iso image {{ image_registry }}/{{ image_name }}:latest

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
    rm -rf Containerfile output *.iso *.iso-CHECKSUM
