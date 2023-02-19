# homeserver

## Setting up debian
1. vim
2. zfs
    1. Add `contrib` and `backports` to [SourcesList](https://wiki.debian.org/SourcesList)
    2. `sudo apt update`
    3. `sudo apt install linux-headers-amd64`
    4. `sudo apt install -t bullseye-backports zfsutils-linux`
3. docker
    1. Add to repositories
    
          ```
            sudo apt install ca-certificates curl gnupg lsb-release`
            sudo mkdir -m 0755 -p /etc/apt/keyrings`
            curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg`
            echo \
              "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
              $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            sudo apt update
    2. Install: `sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin`
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
    1. `sudo zfs create tank/NC`
    2. Optionally enable compression with `sudo zfs set compression=lz4 tank/NC`
5. Check maintainance options
    1. Regular scrub `cat /etc/cron.d/zfsutils-linux`

## TO DO
1. Nextcloud in docker
    1. Nextcloud
	2. MariaDB
	3. Redis
2. Docker network
3. Caddy Docker
