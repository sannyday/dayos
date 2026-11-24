#!/bin/sh
# Point Nix trusted-users at the account that owns UID 1000.
set -eu
umask 022

user="$(getent passwd 1000 | cut -d: -f1 || true)"
[ -n "${user}" ] || exit 0

sed -i -E "s/^([[:space:]]*trusted-users[[:space:]]*=[[:space:]]*).*$/\1${user}/" /etc/nix/nix.conf
