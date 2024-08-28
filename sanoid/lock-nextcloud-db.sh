#!/usr/bin/env bash

LOCKFILE="/tmp/mariadb-locked"

usage_info() {
  echo "Usage: $0"
  echo "Forces or removes a read lock on the instance of mariadb running in the container nextcloud-db"
  echo "Options:"
  echo "  -l  Lock"
  echo "  -u  Unlock"
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

lockscript() {
  cat <<EOF
mariadb --user=root --password="\$MYSQL_ROOT_PASSWORD" --batch << END &
  delimiter ;;
  flush tables with read lock;;
  system touch $LOCKFILE
  system while test -e $LOCKFILE; do sleep .5; done
  exit
END

while ! test -e $LOCKFILE; do sleep .5; done
EOF
}

lock_db() {
  lockscript | docker exec --interactive nextcloud-db bash
}

release_lock() {
  docker exec nextcloud-db bash -c "rm $LOCKFILE"
}

set -Eeuo pipefail

trap 'echo " releasing lock ..."; release_lock' ERR

if [ "$#" -ne 1 ]; then
  usage
fi

check_root

LOCK=0

while getopts "lu" opt; do
  case $opt in
    l)
      LOCK=1
      ;;
    u)
      LOCK=0
      ;;
    *)
      usage
      ;;
  esac
done

if [ "$LOCK" -eq 1 ]; then
  lock_db
else
  release_lock
fi
