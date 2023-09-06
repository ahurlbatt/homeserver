# homeserver

This is my playground for building a home Nextcloud solution with something close to a one-touch setup. Feel free to
steal the ideas if you think they're good, or send constructive criticism if you think they're bad.

*This repo currently contains encrypted passwords for some of the defined services. This is generally not a good idea
but is used for this testing phase to make deployment to a new VM simpler. Please don't do this for production systems.*

## Setting up debian

1. `su -c "/user/sbin/usermod -aG sudo USERNAME" -`
2. Reboot
3. `sudo apt update && sudo apt upgrade -y`
4. `sudo apt install vim openssh-server`
5. Create a local ssh key with `ssh-keygen`
6. Copy ssh-key to authorized keys file with `ssh-copy-id localhost`
7. `sudo vim /etc/ssh/sshd_config`
    1. `PasswordAuthentication no`
    2. `PubkeyAuthentication yes`
8. `sudo systemctl restart ssh`

## Infrastructure

1. Register a domain
2. Set up a dynamic DNS service
3. Enable HTTP and HTTPS port forwards from your router to the server
4. Create and activate a Repository on [Borgbase](https://www.borgbase.com/)
    - On the server, create a new SSH keypair for root with the flags `-t ed25519` and `-a 100`
        - Don't set a passphrase
    - Copy the public key to Borgbase
    - Initialise the repo with `borg init -e repokey-blake2 ssh://...`
    - Export the key with `borg key export --paper ssh://... borg_key.txt` and store it somewhere safe

## Setting up the server

1. Install ansible and the hardening collection
    - `apt update`
    - `apt install ansible`
    - `ansible-galaxy collection install devsec.hardening`
2. Clone this repo
3. Put the ansible vault password in `./secrets/ansible_vault_password.secret`
4. Run the playbook from the `ansible` directory with `ansible-playbook -K -i inventory.yaml playbook.yaml`
    - The flag `-K` will prompt for the sudo password

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
5. Monitoring settings
    - Ideas taken from [this blog post](https://blog.randombits.host/monitoring-self-hosted-services/)
    - A lot of compose settings taken from
     the [grafana docs](https://grafana.com/docs/grafana-cloud/quickstart/docker-compose-linux/)
    - Loki and promtail settings taken by combining the [production compose file](https://github.com/grafana/loki/blob/main/production/docker-compose.yaml), the [getting-started examples](https://github.com/grafana/loki/tree/main/examples/getting-started) and loki [configuration templates](https://grafana.com/docs/loki/latest/configuration/examples/)

## Ansible Notes

1. For encryption of secrets, the file `./secrets/ansible_vault_password.secret` is needed
2. Secrets were encrypted using `encrypt-secrets.sh` script

## TO DO


1. Include monitoring dataset in backups
2. Test restoring a backup
3. Change zfs pools to disk by-id (/dev/disk/by-id/)
4. Nextcloud Apps
    1. Memories
5. Move secrets out of git, then rotate
