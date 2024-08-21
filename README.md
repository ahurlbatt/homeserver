# homeserver

This is my playground for building a home Nextcloud solution with something close to a one-touch setup. Feel free to
steal the ideas if you think they're good, or send constructive criticism if you think they're bad.

## Setting up debian

1. Install debian without a Desktop environment, but with ssh server
2. Don't set a root password, to get sudo
3. `sudo apt update && sudo apt upgrade -y`
4. Copy your ssh-key from your machine to the server authorized keys file with `ssh-copy-id user@server`
5. `sudo vim /etc/ssh/sshd_config`
    1. `PasswordAuthentication no`
    2. `PubkeyAuthentication yes`
6. `sudo systemctl restart ssh`

## Infrastructure

1. Register a domain
2. Set up a dynamic DNS service
3. Enable HTTP and HTTPS port forwards from your router to the server
4. Create and activate a Repository on [Borgbase](https://www.borgbase.com/)
    - On the server, create a new SSH keypair for root with the flags `-t ed25519` and `-a 100`
        - Don't set a passphrase
    - Copy the public key to Borgbase
    - Initialise the repo with `borg init -e repokey-blake2 ssh://...`
    - Export the key with `borg key export ssh://...` and store it somewhere safe

## Setting up the server

1. Install ansible and the hardening collection
    - `apt update`
    - `apt install ansible`
    - `ansible-galaxy collection install devsec.hardening`
2. Clone this repo
3. Create and populate all the required secrets listed in `./secrets/required_secrets.txt`
4. Adapt the address of the server in the file `./ansible/inventory.yaml`
5. Run the playbook from the `ansible` directory with `ansible-playbook -K -i inventory.yaml playbook.yaml`
    - The flag `-K` will prompt for the sudo password
6. Nextcloud and apps require manual setup
    - Nextcloud itself needs e.g. email set for the admin account, locations if wanted, and apps installing
    - For running command-line configuration using `occ`, this should be done with the user `www-data` according to the [Documentation](https://docs.nextcloud.com/server/latest/admin_manual/configuration_server/occ_command.html)
      - This is done from the host machine for example using `sudo docker compose exec -it -u33 nextcloud-app php occ <command>`
      - Here user Id 33 corresponds to `www-data` - check this by running `getent passwd` inside the container
    - The app [Memories](https://github.com/pulsejet/memories) needs some [initial configuration](https://memories.gallery/config/), which is fortunately well documented
	  - It depends on the apps [Preview Generator](https://github.com/rullzer/previewgenerator), [Recognize](https://github.com/nextcloud/recognize), and [Camera RAW Previews](https://github.com/ariselseng/camerarawpreviews)
	    - Preview Generator requires `occ preview:generate-all` to be run once after installation (also a cron line, but that's part of the nextcloud-cron docker image)
		- Recognize needs to have models downloaded and tagging activated - check the admin settings page
		- The [Face Recognition](https://github.com/matiasdelellis/facerecognition) is also recommended, but seems a lot of work to set up
		
## Restoring from remote backup

The backup will be restored from the remote repository using `borgmatic extract`. As the name suggests, this extracts files, it doesn't restore a state. That means, for eaxmple, that files created since the time of the backup will not be automatically deleted from the target. The simplest way to deal with this is to manually delete the contents of the target before starting the `extract`ion. There may be a 'smarter' way to do this using mounts and sync tools - see the [discussion about this on Github](https://github.com/borgbackup/borg/issues/4598).

1. If you're starting from scratch, set up the server as detailed above, with the exception of the infrastructure - this should alread exist, and you don't want to reinitialise the borg repo
    - You will also not need to do the setup of Nextcloud and its apps
2. Disable the scheduled back up tasks
    - `sudo systemctl disable sanoid.timer borgmatic.timer`
3. Use `sudo borgmatic rlist` to get a list of the archives available and pick the one to use
    - Each 'archive' is a single backup
    - Copy the name and put it somewhere temporary - you'll need it a few times
4. Navigate your terminal to `/tank` and delete the contents of the datasets there, if there is any
    - You can only delete the _contents_ of a dataset, not the dataset itself, without going through `zfs`
    - We don't want to do this, so your delete command will need to name each dataset explicitly
5. Still within the directory `/tank`, use the following extract command to extract the contents of the archive onto disk i.e. restore from the backup
    - `sudo borgmatic extract --archive {YOUR_ARCHIVE_NAME} --path mnt/backup/tank --strip-components 3`
    - The last two options are needed because of the way snapshots are mounted as the source of each backup
    - I didn't realise what effect this would have and now it's kinda too late to change it
    - You can use the `--progress` flag to monitor the progress, but there's a chance it would actually slow down the restore
6. Figure out a way of checking the progress, or I guess leave it running and pray

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
	- Environment variables are reasonably well documented on the official [Docker Hub page](https://hub.docker.com/_/nextcloud)
	- SMTP environment variables are further clarified in [this Github issue](https://github.com/nextcloud/docker/issues/1187)
4. ZFS Snapshots are managed using [Sanoid](https://github.com/jimsalterjrs/sanoid)
5. Monitoring settings
    - Ideas taken from [this blog post](https://blog.randombits.host/monitoring-self-hosted-services/)
    - A lot of compose settings taken from
     the [grafana docs](https://grafana.com/docs/grafana-cloud/quickstart/docker-compose-linux/)
    - Loki and promtail settings taken by combining the [production compose file](https://github.com/grafana/loki/blob/main/production/docker-compose.yaml), the [getting-started examples](https://github.com/grafana/loki/tree/main/examples/getting-started) and loki [configuration templates](https://grafana.com/docs/loki/latest/configuration/examples/)

## TO DO

1. Write runbook for full restore from backup
2. Update diagram
3. Make caddy do the DDNS stuff
4. Click together grafana monitoring
5. Set up notifications
