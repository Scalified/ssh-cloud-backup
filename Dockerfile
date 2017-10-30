FROM scalified/alpine-cron:latest

ENV RCLONE_HOME /opt/rclone
ENV RCLONE_CONFIG_DIR /root/.config/rclone
ENV BACKUP_SCRIPTS_DIR /root/.scripts
ENV CRONTABS_DIR /etc/crontabs
ENV ROOT_CRONTABS_FILE $CRONTABS_DIR/root
ENV CRON_LOG_DIR /var/log/crond
ENV SSH_DIR /root/.ssh
ENV BACKUP_DIR /root/.backup
ENV RCLONE_URL https://downloads.rclone.org/rclone-current-linux-amd64.zip
ENV RCLONE_ARCHIVE rclone.zip

RUN apk add --update --no-cache curl \
    unzip

RUN mkdir -p $RCLONE_HOME

RUN curl $RCLONE_URL --output $RCLONE_HOME/$RCLONE_ARCHIVE \
    && cd $RCLONE_HOME \ 
    && unzip -j $RCLONE_ARCHIVE \
    && rm $RCLONE_ARCHIVE
    
RUN chown root:root $RCLONE_HOME/rclone \
    && chmod 755 $RCLONE_HOME/rclone

RUN ln -s $RCLONE_HOME/rclone /usr/bin/rclone
    
RUN mkdir -p $RCLONE_CONFIG_DIR \
    $BACKUP_SCRIPTS_DIR \
    $CRONTABS_DIR \ 
    $CRON_LOG_DIR \
    $SSH_DIR \
    $BACKUP_DIR

COPY scripts/backup_dir.sh \
     scripts/archiveRemotePath.sh \
     scripts/arhiveLocalPath.sh \
     scripts/backup_mongo.sh \
     scripts/downloadFiles.sh \
     scripts/downloadPath.sh \
     scripts/rcloneUploadPath.sh $BACKUP_SCRIPTS_DIR/

RUN dos2unix $BACKUP_SCRIPTS_DIR/backup_dir.sh \
    $BACKUP_SCRIPTS_DIR/archiveRemotePath.sh \
    $BACKUP_SCRIPTS_DIR/arhiveLocalPath.sh \
    $BACKUP_SCRIPTS_DIR/backup_mongo.sh \
    $BACKUP_SCRIPTS_DIR/downloadFiles.sh \
    $BACKUP_SCRIPTS_DIR/downloadPath.sh \
    $BACKUP_SCRIPTS_DIR/rcloneUploadPath.sh          

RUN chmod u+x $BACKUP_SCRIPTS_DIR/backup_dir.sh

COPY crontabs/root $CRONTABS_DIR

RUN chmod 600 $ROOT_CRONTABS_FILE
          
VOLUME $BACKUP_DIR
VOLUME $SSH_DIR
VOLUME $RCLONE_CONFIG_DIR
VOLUME $CRONTABS_DIR