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

## Setting up Ansible Controller

1. If on Windows, install WLS2 and do everything in there
2. [Follow the online guide for Ubuntu](https://docs.ansible.com/ansible/latest/installation_guide/installation_distros.html)
    - For Ubuntu, after an `apt update` just use `apt install ansible`
3. Ensure SSH access (see above)
4. Check the IP/hostname of the target machine in inventory.yaml
5. Check the connection with `ansible all -i inventory.yaml -m ping`
6. Put the ansible vault password in `./secrets/ansible_vault_password.secret`
7. Install the hardening collection with `ansible-galaxy collection install devsec.hardening`

## Infrastructure

1. Register a domain
2. Set up a dynamic DNS service
3. Enable HTTP and HTTPS port forwards from your router to the server

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

## Ansible Notes

1. For encryption of key and other secrets, the file `./secrets/ansible_vault_password.secret` is also needed.
2. GitHub deploy key was generated on a VM, then extracted and encrypted with ansible vault using these commands:

    ```
    ssh 192.168.178.56 'cat ~/.ssh/id_rsa.pub' | ansible-vault encrypt_string --vault-password-file ansiblevault.secret --stdin-name 'github_deploy_key_public' --output 'github_deploy_key_public.vault'
    ssh 192.168.178.56 'cat ~/.ssh/id_rsa' | ansible-vault encrypt_string --vault-password-file ansiblevault.secret --stdin-name 'github_deploy_key_private' --output 'github_deploy_key_private.vault'
    ```
3. Secrets were encrypted using `encrypt-secrets.sh` script.

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
   1. Regular ZFS Snapshots
   2. Borg backup to borgbase
4. Nextcloud Apps
   1. Memories
5. Monitoring
   1. Checkmk?
   2. Uptime Kuma?
   3. Ntfy?
6. Move secrets to git submodule, then rotate
