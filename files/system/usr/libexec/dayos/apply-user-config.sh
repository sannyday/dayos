#!/bin/sh
# Keep the original "day" configuration if that account exists with UID 1000.
# Otherwise point the same settings at the account that owns UID 1000.
set -eu
umask 022

if getent passwd day >/dev/null 2>&1 && [ "$(id -u day)" = "1000" ]; then
    exit 0
fi

user="$(getent passwd 1000 | cut -d: -f1 || true)"
[ -n "${user}" ] || exit 0

# Replace only the hardcoded "day" values in the original config files.
sed -i -E "s/^([[:space:]]*User[[:space:]]*=[[:space:]]*)day[[:space:]]*$/\1${user}/" /etc/plasmalogin.conf
sed -i -E "s/^([[:space:]]*trusted-users[[:space:]]*=[[:space:]]*)day[[:space:]]*$/\1${user}/" /etc/nix/nix.conf
