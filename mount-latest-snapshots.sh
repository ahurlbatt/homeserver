#!/usr/bin/env bash

MOUNT_DIR="/mnt/backup/"
SANOID_CONFIG_FILE="/etc/sanoid/sanoid.conf"

usage_info() {
  echo "Usage: $0"
  echo "Mounts the latest sanoid snapshots to $MOUNT_DIR"
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

mapfile -t datasets < <(grep -P '^\s*\[(?!template_)' "$SANOID_CONFIG_FILE" | sed -E 's/\[|\]//g')

for dataset in "${datasets[@]}"; do
  snapname="$(zfs list -H -t snapshot -o name "$dataset" | tail -n1 | sed 's|'"$dataset"'@||')"
  mkdir -p "$MOUNT_DIR$dataset"
  mapfile -t all_subsets < <(zfs list -Hr -t snapshot -o name "$dataset" | grep "$snapname" | sed 's|^'"$dataset"'||' | sed 's|@'"$snapname"'$||')
  for subset in "${all_subsets[@]}"; do
    mount -t zfs "$dataset$subset@$snapname" "$MOUNT_DIR$dataset$subset"
  done
done

# TODO: Move into functions
# TODO: Function for unmounting
# TODO: Mount/Unmount via flags