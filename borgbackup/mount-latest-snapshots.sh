#!/usr/bin/env bash

MOUNT_DIR="/mnt/backup/"
SANOID_CONFIG_FILE="/etc/sanoid/sanoid.conf"

usage_info() {
  echo "Usage: $0"
  echo "Mounts or unmounts the latest sanoid snapshots to/from $MOUNT_DIR"
  echo "Options:"
  echo "  -m  Mount"
  echo "  -u  Unmount"
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

get_datasets() {
  grep -P '^\s*\[(?!template_)' "$SANOID_CONFIG_FILE" | sed -E 's/\[|\]//g'
}

get_latest_snap() {
  zfs list -H -t snapshot -o name "$1" | tail -n1 | sed 's|'"$1"'@||'
}

get_subsets() {
  zfs list -Hr -t filesystem -o name "$1" | sed 's|^'"$1"'||' | sort
}

mount_dataset_snap() {
  mount -t zfs "$1@$2" "$MOUNT_DIR$1"
}

mount_snapshots() {
  mapfile -t datasets < <(get_datasets)
  for dataset in "${datasets[@]}"; do
    mkdir -p "$MOUNT_DIR$dataset"
    mapfile -t subsets < <(get_subsets "$dataset")
    for subset in "${subsets[@]}"; do
      fullset="$dataset$subset"
      snapname="$(get_latest_snap "$fullset")"
      mount_dataset_snap "$fullset" "$snapname"
    done
  done
}

unmount_snapshots() {
  mapfile -t datasets < <(get_datasets)
  for dataset in "${datasets[@]}"; do
    mapfile -t subsets < <(get_subsets "$dataset" | tac)
    for subset in "${subsets[@]}"; do
      fullset="$dataset$subset"
      umount "$MOUNT_DIR$fullset"
    done
  done
  rm -R "$MOUNT_DIR"
}

set -Eeuo pipefail

trap 'echo " unmounting ..."; unmount_snapshots' ERR

if [ "$#" -ne 1 ]; then
  usage
fi

check_root

MOUNT=0

while getopts "um" opt; do
  case $opt in
    u)
      MOUNT=0
      ;;
    m)
      MOUNT=1
      ;;
    *)
      usage
      ;;
  esac
done

if [ "$MOUNT" -eq 1 ]; then
  mount_snapshots
else
  unmount_snapshots
fi
