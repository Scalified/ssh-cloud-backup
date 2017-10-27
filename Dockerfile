FROM scalified/alpine-cron:latest

ENV RCLONE_HOME /usr/bin
ENV RCLONE_CONFIG_DIR /root/.config/rclone
ENV BACKUP_SCRIPTS_DIR /root/.scripts
ENV CRONTABS_DIR /var/spool/cron/crontabs
ENV ROOT_CRONTABS_FILE $CRONTABS_DIR/root
ENV CRON_LOG_DIR /var/log/crond
ENV SSH_DIR /root/.ssh
ENV BACKUP_DIR /root/.backup
ENV RCLONE_URL https://downloads.rclone.org/rclone-current-linux-amd64.zip

RUN apk add --update --no-cache curl

RUN curl -O $RCLONE_URL \
    && mkdir rclone \
    && unzip rclone-current-linux-amd64.zip -d rclone

RUN cd rclone/rclone-*-linux-amd64  \
    && mkdir -p $RCLONE_HOME \
    && cp rclone $RCLONE_HOME \    
    && chown root:root $RCLONE_HOME/rclone \
    && chmod 755 $RCLONE_HOME/rclone

RUN mkdir -p $RCLONE_CONFIG_DIR $BACKUP_SCRIPTS_DIR $CRONTABS_DIR \	
	$CRON_LOG_DIR $SSH_DIR $BACKUP_DIR

COPY scripts/backup_dir.sh $BACKUP_SCRIPTS_DIR

RUN chmod u+x $BACKUP_SCRIPTS_DIR/backup_dir.sh \
    && echo "TZ=UTC" >> $ROOT_CRONTABS_FILE \
	&& echo "00      20      *       *       1-5     $BACKUP_SCRIPTS_DIR/backup_dir.sh -h swupp-squash-tm.mircloud.us -s /opt/backup/squash-tm -t /tmp/backup-squash-tm -a true >> $CRON_LOG_DIR/backup.log" >> $ROOT_CRONTABS_FILE \
	&& echo "00      21      *       *       1-5     $BACKUP_SCRIPTS_DIR/backup_dir.sh -h swupp-squash-tm.mircloud.us -s /opt/backup/squash-tm -t /tmp/backup-squash-tm >> $CRON_LOG_DIR/backup.log" >> $ROOT_CRONTABS_FILE \
	&& echo "00      08      *       *       1-5     $BACKUP_SCRIPTS_DIR/backup_dir.sh -h swupp-squash-tm.mircloud.us -s /opt/backup/squash-tm -t /tmp/backup-squash-tm -m \"*.txt\" >> $CRON_LOG_DIR/backup.log" >> $ROOT_CRONTABS_FILE \
	&& echo "00      09      *       *       1-5     $BACKUP_SCRIPTS_DIR/backup_dir.sh -h swupp-squash-tm.mircloud.us -s /opt/backup/squash-tm -t /tmp/backup-squash-tm -f 1.txt >> $CRON_LOG_DIR/backup.log" >> $ROOT_CRONTABS_FILE

RUN dos2unix $BACKUP_SCRIPTS_DIR/backup_dir.sh
          
VOLUME $RCLONE_HOME
VOLUME $RCLONE_CONFIG_DIR
VOLUME $BACKUP_SCRIPTS_DIR
VOLUME $CRONTABS_DIR
VOLUME $SSH_DIR
VOLUME $BACKUP_DIR