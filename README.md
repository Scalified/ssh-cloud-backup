# SSH Cloud Backup (Alpine Docker Image)

This docker image is intended for performing periodic backups via ssh. It consists of three main elements:

1. Pre-configured cron (based on [alpine-cron](https://store.docker.com/community/images/scalified/alpine-cron) Docker image)

2. Set of bash scripts to perform various kinds of backups

   * **backup files/folders into an archive**
   * **backup files/folders without archiving (as is)**
   * **backup files by mask with/without archiving**
   * **backup Mongo databases**

3. Pre-installed [rclone](https://rclone.org/) for saving backups to various cloud storage providers.

This picture shows the main workflow of the implemented approach:
[TODO](http://www.scalified.com)

> **Note:** In order to use this Docker image, first of all, you need to configure ssh connection between backup host and all the source hosts. Second step is to configure at least one rclone "remote" to be used as cloud-storage. Last step is to configure cron to execute backups in a timely manner.

Rclone Configuration
-------------

Assuming you've already set up ssh connections, you can start using backup scripts. However, to let them upload backups to the cloud you need to [configure rclone](https://rclone.org/docs/). Basically, it can be done by executing `$ rclone config` on backup host.

After providing cloud storage credentials as well as other configuration details, the configuration file will be created at: `/root/.config/rclone`

> **Note:** Rclone's "remote" name must be the same as specified in `RCLONE_REMOTE_NAME` environment variable  (`backup-remote` by default).

Supported Backup Scripts
-------------

### backup.sh

Allows to perform the following actions:

* backup the directory into an archive

* backup the directory as is (without archiving)

* backup files by mask with/without archiving

#### Required arguments:

* `-s|--source-host` - the source host to backup from
    
* `-i|--input-path` - the input path to backup (source host)
    
* `-o|--output-path` - the path where file/s should be saved (backup host)
   
* `-r|--remote-path` - the path on the cloud storage to store backups at
    
#### Additional arguments:
    
* `-m|--mask` - the backup file/s mask.
    
* `--keep-source-archive` - if specified, the backup archive will be created at source host and won't be deleted after downloading with scp. Default path where archives are kept is `/tmp`
   
* `--backup-files` - the backup files mask. Used along with the argument `-m|--mask`
   
* `--pipe-source-archive` - if specified, the backup archive will be created and downloaded without creating an archive on remote host (using pipes)

* `--backup-path-no-archived` - if specified, no archiving will be performed, e.g. directory will be backed up as is(useful when the directory already contains some backup files that just need to be replicated to cloud storage)
   
   
#### Examples of script usage:
   
* backup the remote path, do not create the archive on remote host
   
    `backup.sh -s <source-host> -i /opt/backup/squash-tm -o /root/.backup/squash-tm -r /squash-tm --pipe-source-archive`
  
* backup files using txt mask
   
    `backup.sh -s <source-host> -i /opt/backup/squash-tm -o /tmp/backup-squash-tm -m .txt -r /squash-tm --backup-files`
       
* backup 1.txt file
   
    `backup.sh -s <source-host> -i /opt/backup/squash-tm -o /tmp/backup-squash-tm -m 1.txt -r /squash-tm --backup-files`
       
* backup the path as is without creating its archive
   
    `backup.sh -s <source-host> -i /opt/backup/squash-tm -o /tmp/backup-squash-tm -r /squash-tm/no-archived --backup-path-no-archived`
       
* backup the path, keep archive on the remote host after its download
   
    `backup.sh -s <source-host> -i /opt/backup/squash-tm -o /tmp/backup-squash-tm -r /squash-tm --keep-source-archive`
               

### backup_mongo.sh

Creates a MongoDB dump.

#### Required arguments:
    
* `-s|--source-host` - the source host with MongoDB server running
        
* `-d` - name of the database to backup
        
* `-o|--output-path` - the local path to put MongoDB dump
        
* `-r|--remote-path` - the path on the cloud storage to put MongoDB dump
   
    
#### Examples of script usage:
   
* backup Mongo database
   
    `backup_mongo.sh -s your_mongo_server_domain_name -d admin -o /tmp/backup-mongo -r /mongo`

## Periodic Scripts Execution

Here's an example of [/etc/crontabs/root](./crontabs/root) file which is used by cron to execute it's jobs.

## Docker Store

To pull the image from [Docker Store](https://store.docker.com/community/images/scalified/ssh-cloud-backup):

    docker pull scalified/ssh-cloud-backup

## Supported environment variables

* `RCLONE_REMOTE_NAME` - rclone remote name to be used for backups.
* `BACKUP_SCRIPTS_DIR` - ???
* `BACKUP_DIR` - ???
    
## Volumes

* `/root/.backup` - the folder into wich the backup data is put, which will be synchronized by the rclone with a cloud storage
* `/root/.ssh` - the ssh config folder
* `/root/.config/rclone` - the rclone configuration path
* `/etc/crontabs` - the path where the root cron file is located

## Scalified Links

* [Scalified](http://www.scalified.com)
* [Scalified Official Facebook Page](https://www.facebook.com/scalified)
* Scalified Support - info@scalified.com
