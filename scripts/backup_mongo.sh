#!/bin/sh

set -e

USER=root
BACKUP_DIR=~/.backup
RCLONE_REMOTE_NAME="auto-backup"

# Parsing arguments
while getopts "s:n:d:u:q" opt
do
    case $opt in
      s) SOURCE_HOST=$OPTARG;;
      n) DATA_BASE_NAME=$OPTARG;;
      d) DESTINATION_OUTPUT_PATH=$OPTARG;;  
      q) QUIT=1;;
      :|\?) exit 1;;
    esac
done

      #m) FILE_MASK=$OPTARG;;

# Required params
[ -z $SOURCE_HOST ] && echo "-h <SOURCE_HOST> is required" && exit 1
[ -z $DATA_BASE_NAME ] && echo "-n <DATA_BASE_NAME> is required" && exit 1
[ -z $DESTINATION_OUTPUT_PATH ] && echo "-t <DESTINATION_OUTPUT_PATH> is required" && exit 1

backup() {
	ARCHIVE_NAME=mongo_dump_"$(date '+%Y-%m-%d-%H%M').gz"

	echo "Start to backup the Mongo DataBase ${DATA_BASE_NAME} at ${SOURCE_HOST} host"

	ssh ${USER}@${SOURCE_HOST} "mongodump --archive=${DESTINATION_OUTPUT_PATH}/${ARCHIVE_NAME} --gzip --db ${DATA_BASE_NAME}"

    if [ $? == 0 ]; then
    	echo "[INFO][$(date -u)]: Successfully created the backup archive ${ARCHIVE_NAME} of the Mongo database ${DATA_BASE_NAME} at ${SOURCE_HOST} host"

     	TEMP_BACKUP_DIR=/tmp/${SOURCE_HOST}

    	sh ${BACKUP_SCRIPTS_DIR}/downloadFiles.sh -u ${USER} -s ${SOURCE_HOST} -f ${DESTINATION_OUTPUT_PATH} -d ${TEMP_BACKUP_DIR} -m ${ARCHIVE_NAME}

    	MONGO_UPLOAD_DIR=${BACKUP_DIR}/MONGO/${SOURCE_HOST}
     
    	mkdir -p ${MONGO_UPLOAD_DIR}

    	cp ${TEMP_BACKUP_DIR}/${ARCHIVE_NAME} ${MONGO_UPLOAD_DIR}
     
    	rm -rf ${TEMP_BACKUP_DIR}
     
		sh ${BACKUP_SCRIPTS_DIR}/rcloneUploadPath.sh -s ${MONGO_UPLOAD_DIR} -n ${RCLONE_REMOTE_NAME} -d ${SOURCE_HOST}                    
            
        exit 0;

    else
     echo "[INFO][$(date -u)]: Failed to create the backup archive ${ARCHIVE_NAME} of the Mongo database ${DATA_BASE_NAME} at ${SOURCE_HOST} host"
     exit 1;
    fi
}

echo "-------------------------------------------------------------------------------------"
echo "-------------------------------------------------------------------------------------"
echo "-------------------[INFO][$(date -u)]: Mongo Backup Script is run --------------"
echo "-------------------------------------------------------------------------------------"
echo "-------------------------------------------------------------------------------------"

backup