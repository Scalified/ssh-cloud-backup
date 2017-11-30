FROM scalified/alpine-cron:latest

ARG RCLONE_HOME=/opt/rclone
ARG RCLONE_CONFIG_DIR=/root/.config/rclone
ARG SSH_DIR=/root/.ssh
ARG RCLONE_URL=https://downloads.rclone.org/rclone-current-linux-amd64.zip
ARG RCLONE_ARCHIVE=rclone.zip

ARG BACKUP_LOG_DIR
ENV BACKUP_LOG_DIR ${BACKUP_LOG_DIR:-/var/log/crond}

ARG BACKUP_SCRIPTS_DIR
ENV BACKUP_SCRIPTS_DIR ${BACKUP_SCRIPTS_DIR:-/root/.scripts}

ARG RCLONE_REMOTE_NAME
ENV RCLONE_REMOTE_NAME ${RCLONE_REMOTE_NAME:-backup-remote}

ARG BACKUP_DIR
ENV BACKUP_DIR ${BACKUP_DIR:-/root/.backup}

RUN apk add --update --no-cache curl unzip bash

RUN mkdir -p $RCLONE_HOME

RUN curl $RCLONE_URL --output $RCLONE_HOME/$RCLONE_ARCHIVE \
    && cd $RCLONE_HOME \ 
    && unzip -j $RCLONE_ARCHIVE \
    && rm $RCLONE_ARCHIVE
    
RUN chmod 755 $RCLONE_HOME/rclone

RUN ln -s $RCLONE_HOME/rclone /usr/bin/rclone
    
RUN mkdir -p $RCLONE_CONFIG_DIR \
    $BACKUP_SCRIPTS_DIR \
    $BACKUP_LOG_DIR \
    $SSH_DIR \
    $BACKUP_DIR

COPY scripts/* $BACKUP_SCRIPTS_DIR/

RUN dos2unix $BACKUP_SCRIPTS_DIR/*.sh          

RUN chmod u+x $BACKUP_SCRIPTS_DIR/*.sh

COPY crontabs/root $CRONTABS_DIR

RUN chmod 600 $CRONTABS_DIR/root
          
VOLUME $SSH_DIR
VOLUME $BACKUP_DIR
VOLUME $RCLONE_CONFIG_DIR
