# Alpine Auto-Backup Docker

## Description

This docker image is intended for:

* **databases, files and directories backup**
* **backup scripts execution scheduling (using cron)**
* **uploading files to cloud storage (using rclone)**

## Dockerhub

**`docker pull scalified/ssh-cloud-backup`**

## Version

| #      | Version |
|--------|---------|
| Alpine | 3.4     |


## Volumes

* **`/root/.backup`**
* **`/root/.ssh`**
* **`/root/.config/rclone`**
* **`/etc/crontabs`**

## Rclone Configuration

In order to start using rclone, it must be configured using the following command:

**`$ rclone config`**

After providing cloud storage credentials as well as other configuration details, the configuration file will be created at:

**`/root/.config/rclone`**

## Main scripts

* **backup.sh**

* **backup_mongo.sh**


#### Description


**backup.sh** - allows to perform the following actions:

* **local path archiving**

* **remote path archiving**

* **remote path archiving without storing archive remotely (using pipes)**

* **files archiving by mask**

**Required arguments:**

   **`-s|--source-host`** - the source host to backup from
    
   **`-i|--input-path`** - the source input path to backup
    
   **`-o|--output-path`** - the local path to put the archive to
    
   **`-r|--remote-path`** - the path on the cloud storage to store the archive in
    
   **Additional arguments:**
    
   **`-m|--mask`** - the backup file mask
    
   **`--keep-source-archive`** - if specified, the backup archive will be created and won't be deleted after downloading. Default remote path is /tmp 
   
   **`--backup-files`** - the backup files mask. Used with the argument **`-m|--mask`**
   
   **`--pipe-source-archive`** - if specified, the backup archive will be created and downloaded locally without creating an archive on remote host

   **`--backup-path-no-archived`** - if specified, an archive won't be created on remote host
   
   
   Examples of script running
   
   * **backup the remote path, do not create the archive on remote host**
   
       **`backup.sh -s swupp-squash-tm.mircloud.us -i /opt/backup/squash-tm -o /root/.backup/squash-tm -r /squash-tm --pipe-source-archive`**
   
   * **backup files using txt mask**
   
       **`backup.sh -s swupp-squash-tm.mircloud.us -i /opt/backup/squash-tm -o /tmp/backup-squash-tm -m .txt -r /squash-tm --backup-files`**
       
   * **backup 1.txt file**
   
       **`backup.sh -s swupp-squash-tm.mircloud.us -i /opt/backup/squash-tm -o /tmp/backup-squash-tm -m 1.txt -r /squash-tm --backup-files`**
       
   * **backup the path as is without creating its archive**
   
       **`backup.sh -s swupp-squash-tm.mircloud.us -i /opt/backup/squash-tm -o /tmp/backup-squash-tm -r /squash-tm/no-archived --backup-path-no-archived`**
       
   * **backup the path, keep archive on the remote host after its download**
   
       **`backup.sh -s swupp-squash-tm.mircloud.us -i /opt/backup/squash-tm -o /tmp/backup-squash-tm -r /squash-tm --keep-source-archive`**
               

**backup_mongo.sh** - creates a Mongo DB dump.

   **Required arguments:**
    
   **`-s|--source-host`** - the source host with Mongo DB running
        
   **`-d`** - the Mongo DB name to backup
        
   **`-o|--output-path`** - the local path to put Mongo DB dump into
        
   **`-r|--remote-path`** - the path on the cloud storage to put Mongo DB dump into
   
    
   Examples of script running:
   
   * **backup mongo database**
   
       **`backup_mongo.sh -s node42008-mongo-backup.mircloud.us -d admin -o /tmp/backup-mongo -r /mongo`**       

## Logging

The log file is located **`/var/log/crond/backup.log`**
 
## Periodic Backups

The Performing daily backups is configured in **/etc/crontabs/root** file.

## Docker image

#### Building Docker Image

`docker build . -t <tag>`

#### Running Docker Image

`docker run -it scalified/ssh-cloud-backup /bin/sh`

## Scalified Links

* [Scalified](http://www.scalified.com)
* [Scalified Official Facebook Page](https://www.facebook.com/scalified)
* Scalified Support - info@scalified.com
