#!/usr/bin/env bash

secret_files=(
  "./secrets/mysql_database.secret"
  "./secrets/mysql_password.secret"
  "./secrets/mysql_root_password.secret"
  "./secrets/mysql_user.secret"
  "./secrets/nextcloud_admin_password.secret"
  "./secrets/nextcloud_admin_user.secret"
)

for file in "${secret_files[@]}"; do
  if [ ! -f "$file" ]; then
    echo "File $file does not exist"
    exit 1
  fi
done

for file in "${secret_files[@]}"; do
  ansible-vault encrypt "$file" --output "$file".vault
done