#!/usr/bin/env bash

mount_location="/mnt/backup"
#sanoid_config="/etc/sanoid/sanoid.conf"
sanoid_config="sanoid.conf"

usage_info() {
  echo "Usage: $0"
  echo "Mounts the latest sanoid snapshots to $mount_location"
}

usage() {
  exec 1>&2
  usage_info
  exit 1
}

error() {
  echo "$0: $*" >&2
  exit 1
}

check_root() {
  if [ "$(id -u)" -ne 0 ]; then
    error "This script must be run as root"
  fi
}

mapfile -t datasets < <(grep -P '^\s*\[(?!template_)' "$sanoid_config" | sed -E 's/\[|\]//g')

echo "Datasets:"
for dataset in "${datasets[@]}"; do
  echo "  $dataset"
done