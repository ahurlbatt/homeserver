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
    1. https://wiki.debian.org/ZFS
    2. https://arstechnica.com/information-technology/2020/05/zfs-101-understanding-zfs-storage-and-performance/
2. List of disks to include
    1. `for f in /dev/disk/by-id/*; do stat --format='%n' "$f"; done > zdisks.txt`
    2. Edit to remove e.g. boot drive
3. Create pool and vdev - check ashift vs block size!
    1. `cat zdisks.txt | sudo xargs zpool create tank raidz2 `
4. Create dataset
    1. `sudo zfs create tank/nc`
    2. Optionally enable compression with `sudo zfs set compression=lz4 tank/nc`
    3. Make folders for DB and Data: `sudo mkdir /tank/nc/db /tank/nc/ncdata`
5. Check maintainance options
    1. Regular scrub `cat /etc/cron.d/zfsutils-linux`

## Starting the services
1. Check out this repo to the system
2. Make the necessary `.secret` files
3. Adapt `homeserver.env` if needed e.g. for your domain
3. Run `sudo docker compose up`
4. Secure MariaDB
	1. Use this: `sudo docker exec -it homeserver-nc-db-1 /usr/bin/mariadb-secure-installation`

## TO DO
1. Docker Images
    2. Caddy
2. Tuning
	1. ZFS for NC
	2. NC for ZFS
	3. ZFS for MariaDB
	4. MariaDB for ZFS
3. Email?
