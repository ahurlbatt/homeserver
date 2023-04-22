# homeserver

## Setting up debian
1. Basics
    1. `usermod -aG sudo USERNAME`
    2. vim
    3. openssh-server
        1. `PasswordAuthentication no`
        2. `PubkeyAuthentication yes`
    4. [Allow `fork` memory overcommit for redis](https://redis.io/docs/getting-started/faq/#background-saving-fails-with-a-fork-error-on-linux) - `sudo sh -c "echo '\n# Enable overcommit for fork\nvm.overcommit_memory = 1\n' >> /etc/sysctl.conf"`
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
5. Check maintainance options
    1. Regular scrub `cat /etc/cron.d/zfsutils-linux`

## Starting the services
1. Check out this repo to the system
2. Make the necessary `.secret` files
3. Adapt `homeserver.env` if needed e.g. for your domain
3. Run `sudo docker compose up`
4. Secure MariaDB
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

## TO DO
1. Tuning
    1. ZFS for NC
    2. NC for ZFS
2. Read cache on ssd
3. Borg backup to borgbase
4. Ansible or similar
5. Checkmk
