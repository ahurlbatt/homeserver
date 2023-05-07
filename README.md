# homeserver

## Setting up Ansible Controller

1. If on Windows, install WLS2 and do everything in there
2. [Follow the online guide for Ubuntu](https://docs.ansible.com/ansible/latest/installation_guide/installation_distros.html)
    - For Ubuntu, after an `apt update` just use `apt install ansible`
3. Ensure SSH access (by e.g. copying the public key)
4. Check the IP/hostname of the target machine in inventory.yaml
5. Check the connection with `ansible all -i inventory.yaml -m ping`
6. Put the ansible vault password in `ansiblevault.secret`

## Setting up debian

1. Basics
    1. `su -c "usermod -aG sudo USERNAME" -`
    2. Reboot
    3. `sudo apt update && sudo apt upgrade -y`
    4. `sudo apt install vim openssh-server`
    5. Copy ssh-key from controller with `ssh-copy-id SERVER`
    6. `sudo vim /etc/ssh/sshd_config`
        1. `PasswordAuthentication no`
        2. `PubkeyAuthentication yes`
    7. `sudo systemctl restart ssh`
    8. [Allow `fork` memory overcommit for redis](https://redis.io/docs/getting-started/faq/#background-saving-fails-with-a-fork-error-on-linux) - `sudo sh -c "echo '\n# Enable overcommit for fork\nvm.overcommit_memory = 1\n' >> /etc/sysctl.conf"`
2. zfs
    1. Add `contrib` and `backports` to [SourcesList](https://wiki.debian.org/SourcesList)
    2. `sudo apt update`
    3. `sudo apt install linux-headers-amd64`
    4. `sudo apt install -t bullseye-backports zfsutils-linux`
3. docker
    1. Add to repositories

            ```
            sudo apt install ca-certificates curl gnupg lsb-release
            sudo mkdir -m 0755 -p /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            echo \
            "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
            $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            sudo apt update
            ```
    2. Install: `sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin`
    3. Test: `sudo docker run hello-world`

## Setting up zfs

1. Helpful:
    - https://wiki.debian.org/ZFS
    - https://arstechnica.com/information-technology/2020/05/zfs-101-understanding-zfs-storage-and-performance/
2. List of disks to include
    1. `for f in /dev/disk/by-id/*; do stat --format='%n' "$f"; done > zdisks.txt`
    2. Edit to remove e.g. boot drive
3. Create pool and vdev - check ashift vs block size!
    - `cat zdisks.txt | sudo xargs zpool create tank raidz2 `
4. Create datasets
    - Nextcloud Data: `sudo zfs create -o compression=lz4 tank/nextcloud`
    - MariaDB Data: `sudo zfs create -o recordsize=16k -o primarycache=metadata -o compression=lz4 -o logbias=throughput -o atime=off tank/mariadb`
5. Check maintenance options
    1. Regular scrub `cat /etc/cron.d/zfsutils-linux`

## Starting the services

1. Check out this repo to the system
2. Make the necessary `.secret` files
3. Adapt `homeserver.env` if needed e.g. for your domain
4. Run `sudo docker compose up`
5. Secure MariaDB
    - Use this: `sudo docker exec -it homeserver-nc-db-1 /usr/bin/mariadb-secure-installation`

## Some explanations

1. MariaDB settings are taken from the following sources. I don't understand all of them.
    - [Reddit post about it](https://www.reddit.com/r/zfs/comments/u1xklc/mariadbmysql_database_settings_for_zfs/)
    - [ZFS Documentation](https://openzfs.github.io/openzfs-docs/Performance%20and%20Tuning/Workload%20Tuning.html#mysql)
    - [This company](https://www.percona.com/blog/mysql-zfs-performance-update/)
    - [This Blog](https://shatteredsilicon.net/mysql-mariadb-innodb-on-zfs/)
2. Caddy settings and docker parameters are taken from:
    - [Nextcloud Documentation](https://github.com/nextcloud/documentation/blob/master/admin_manual/configuration_server/reverse_proxy_configuration.rst)
    - [The Repo for the image](https://github.com/lucaslorentz/caddy-docker-proxy)
    - [This dudes Repo](https://github.com/blazekjan/docker-selfhosted-apps)
    - [This blog post](https://dev.to/jhot/caddy-docker-proxy-like-traefik-but-better-565l)
    - [This Gist](https://gist.github.com/tmo1/72a9dc98b0b6b75f7e4ec336cdc399e1)
3. Nextcloud tuning takes info from here
    - [Server tuning guide](https://docs.nextcloud.com/server/21/admin_manual/installation/server_tuning.html)

## Ansible Notes

1. GitHub deploy key was generated on a VM, then extracted and encrypted with ansible vault using these commands:

    ```
    ssh 192.168.178.56 'cat ~/.ssh/id_rsa.pub' | ansible-vault encrypt_string --vault-password-file ansiblevault.secret --stdin-name 'github_deploy_key_public' --output 'github_deploy_key_public.vault'
    ssh 192.168.178.56 'cat ~/.ssh/id_rsa' | ansible-vault encrypt_string --vault-password-file ansiblevault.secret --stdin-name 'github_deploy_key_private' --output 'github_deploy_key_private.vault'
    ```

## TO DO

1. Ansible
   1. ~~Memory overcommit~~
   2. ~~Install zfs~~
   3. ~~Install docker~~
   4. ~~Set up zfs~~
   5. Checkout repo
   6. Set up secrets and environment
   7. Start containers
   8. Secure MariaDB
2. Borg backup to borgbase
3. Secrets
   1. Create encrypted files with ansible vault
   2. Put into git submodule
4. Checkmk
