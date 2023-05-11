#!/usr/bin/env bash

secret_names_file="./secrets/secrets.txt"

mapfile -t secret_files < "$secret_names_file"

usage_info() {
  echo "Usage: $0 [-d]"
  echo "Encrypts all secret files"
  echo "Options:"
  echo "  -d  Decrypts all secret files instead"
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

check_vault_password_file_exists() {
  if [ ! -f "./secrets/ansible_vault_password.secret" ]; then
    error "Required file ./secrets/ansible_vault_password.secret does not exist"
  fi
}

check_secret_files_exist() {
  for file in "${secret_files[@]}"; do
    if [ ! -f "$file" ]; then
      error "Required file $file does not exist"
    fi
  done
}

check_vault_files_exist() {
  for file in "${secret_files[@]}"; do
    if [ ! -f "$file".vault ]; then
      error "Required file $file.vault does not exist"
    fi
  done
}

encrypt_files() {
  for file in "${secret_files[@]}"; do
    ansible-vault encrypt "$file" --output "$file".vault
  done
}

decrypt_files() {
  for file in "${secret_files[@]}"; do
    ansible-vault decrypt "$file".vault --output "$file"
  done
}

if [ "$#" -gt 1 ]; then
  usage
fi

DECRYPT=0

while getopts ":d" opt; do
  case $opt in
    d)
      DECRYPT=1
      ;;
    *)
      usage
      ;;
  esac
done

check_vault_password_file_exists

if [ "$DECRYPT" -eq 1 ]; then
  check_vault_files_exist
  decrypt_files
else
  check_secret_files_exist
  encrypt_files
fi