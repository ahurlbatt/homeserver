# homeserver

## Setting up debian

1. `su -c "usermod -aG sudo USERNAME" -`
2. Reboot
3. `sudo apt update && sudo apt upgrade -y`
4. `sudo apt install vim openssh-server`
5. Copy ssh-key from controller with `ssh-copy-id SERVER`
6. `sudo vim /etc/ssh/sshd_config`
    1. `PasswordAuthentication no`
    2. `PubkeyAuthentication yes`
7. `sudo systemctl restart ssh`

## Infrastructure

1. Register a domain
2. Set up a dynamic DNS service
3. Enable HTTP and HTTPS port forwards from your router to the server
4. Create and activate a Repository on [Borgbase](https://www.borgbase.com/)
    - On the server, create a new SSH keypair with `ssh-keygen -t ed25519 -a 100`
    - Copy the public key to Borgbase
    - Initialise the repo with `borg init -e repokey-blake2 ssh://...`
    - Export the key with `borg key export --paper ssh://... borg_key.txt` and store it somewhere safe

## Setting up Ansible Controller

1. If on Windows, install WLS2 and do everything in there
2. [Follow the online guide for Ubuntu](https://docs.ansible.com/ansible/latest/installation_guide/installation_distros.html)
    - For Ubuntu, after an `apt update` just use `apt install ansible`
3. Install the hardening collection with `ansible-galaxy collection install devsec.hardening`
4. Put the ansible vault password in `./secrets/ansible_vault_password.secret`

## Setting up the server

1. Ensure SSH access to target server (see above)
2. Put the IP/hostname of the target machine in inventory.yaml
3. Check the connection with `ansible all -i inventory.yaml -m ping`
4. Run the playbook with `ansible-playbook -K -i inventory.yaml playbook.yaml`
    - The flag `-K` will prompt for the sudo password for the target machine

## Some explanations

1. MariaDB settings are taken from the following sources. I don't understand all of them.
    - [Reddit post about it](https://www.reddit.com/r/zfs/comments/u1xklc/mariadbmysql_database_settings_for_zfs/)
    - [ZFS Documentation](https://openzfs.github.io/openzfs-docs/Performance%20and%20Tuning/Workload%20Tuning.html#mysql)
    - [This company](https://www.percona.com/blog/mysql-zfs-performance-update/)
    - [This Blog](https://shatteredsilicon.net/mysql-mariadb-innodb-on-zfs/)
    - [This health check discussion](https://github.com/MariaDB/mariadb-docker/issues/94)
    - [Hardening recreates this](https://github.com/dev-sec/ansible-mysql-hardening/blob/master/tasks/mysql_secure_installation.yml)
2. Caddy settings and docker parameters are taken from:
    - [Nextcloud Documentation](https://github.com/nextcloud/documentation/blob/master/admin_manual/configuration_server/reverse_proxy_configuration.rst)
    - [The Repo for the image](https://github.com/lucaslorentz/caddy-docker-proxy)
    - [This dudes Repo](https://github.com/blazekjan/docker-selfhosted-apps)
    - [This blog post](https://dev.to/jhot/caddy-docker-proxy-like-traefik-but-better-565l)
    - [This Gist](https://gist.github.com/tmo1/72a9dc98b0b6b75f7e4ec336cdc399e1)
3. Nextcloud settings have been taken from
    - [Server tuning guide](https://docs.nextcloud.com/server/21/admin_manual/installation/server_tuning.html)
    - [This health check discussion](https://github.com/nextcloud/docker/issues/676)
4. ZFS Snapshots are managed using [Sanoid](https://github.com/jimsalterjrs/sanoid)

## Ansible Notes

1. For encryption of key and other secrets, the file `./secrets/ansible_vault_password.secret` is also needed.
2. GitHub deploy key was generated on a VM, then extracted and encrypted with ansible vault using these commands:
    ```
    ssh 192.168.178.56 'cat ~/.ssh/id_rsa.pub' | ansible-vault encrypt_string --stdin-name 'github_deploy_key_public' --output 'github_deploy_key_public.vault'
    ssh 192.168.178.56 'cat ~/.ssh/id_rsa' | ansible-vault encrypt_string --stdin-name 'github_deploy_key_private' --output 'github_deploy_key_private.vault'
    ```
3. Secrets were encrypted using `encrypt-secrets.sh` script.

## Backup Strategy

1. Backups are made of snapshots, not the running filesystem
2. Backups are done using borgbackup to an external hosted storage service
3. Backups are encrypted on-site
4. Each snapshot is backed up in a way that allows them to be retrieved individually
5. Backups are automatic and monitored
6. All existing snapshots are backed up, if they are not already
7. Existing backups that do not correspond to an existing snapshot are checked against the defined snapshot strategy
   before pruning
8. An inconsistent state between backups and snapshots creates an alert

## TO DO

1. Ansible
    1. ~~Memory overcommit~~
    2. ~~Install zfs~~
    3. ~~Install docker~~
    4. ~~Set up zfs~~
    5. ~~Checkout repo~~
    6. ~~Set up secrets and environment~~
    7. ~~OS Hardening~~
    8. ~~Start containers~~
    9. ~~MariaDB Hardening~~
    10. ~~Deal with zfs volumes from other servers~~
2. Backups
    1. ~~Regular snapshouts with [sanoid](https://github.com/jimsalterjrs/sanoid)~~
        1. ~~Install~~
        2. ~~Configure~~
    2. Borg backup to borgbase
3. Nextcloud Apps
    1. Memories
4. Monitoring
    1. Netdata?
    2. Prometheus?
    3. Checkmk?
    4. Uptime Kuma?
    5. Ntfy?
5. Template compose file with e.g. dataset names
6. Move secrets to git submodule, then rotate
