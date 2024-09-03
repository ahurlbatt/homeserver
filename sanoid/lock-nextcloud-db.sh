#!/usr/bin/env bash

LOCKFILE="/tmp/mariadb-locked"
CONTAINER_NAME="nextcloud-db"

usage_info() {
  echo "Usage: $0"
  echo "Forces or removes a read lock on the instance of mariadb running in the container $CONTAINER_NAME"
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

check_permissions() {
  if ! docker info >/dev/null 2>&1 && true; then
    error "This script must have permission to run 'docker' commands."
  fi
}

container_running() {
  [ $(docker inspect --type=container --format='{{.State.Running}}' "$CONTAINER_NAME") == "true" ]
}

lockfile_exists() {
  docker exec "$CONTAINER_NAME" bash -c "[ -e $LOCKFILE ]"
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
  docker exec "$CONTAINER_NAME" bash -c "rm $LOCKFILE"
}

set -Eeuo pipefail

trap 'echo " releasing lock ..."; release_lock' ERR

if [ "$#" -ne 1 ]; then
  usage
fi

check_permissions

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

if ! container_running; then
  echo "Container $CONTAINER_NAME not running - nothing to do."
  exit 0
fi

if [ "$LOCK" -eq 1 ]; then
  if ! lockfile_exists; then
    lock_db
    echo "Database locked."
  else
    echo "Database already locked - nothing to do."
    exit 0
  fi
else
  if lockfile_exists; then
    release_lock
    echo "Database unlocked."
  else
    echo "Database not locked - nothing to do."
    exit 0
  fi
fi
