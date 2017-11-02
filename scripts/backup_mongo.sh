#!/bin/bash

USER=root
BACKUP_DIR=~/.backup
RCLONE_REMOTE_NAME="scalified-remote"

  # Parsing arguments
  while getopts "s:d:o:r:q" opt
  do
    case $opt in
      s) SOURCE_HOST=$OPTARG;;
      d) DATABASE_NAME=$OPTARG;;
      o) DESTINATION_OUTPUT_PATH=$OPTARG;;
      r) REMOTE_PATH=$OPTARG;;  
      q) QUIT=1;;
      :|\?) exit 1;;
  esac
  done

validate() {
  # Required params
  if [ -z "${SOURCE_HOST}" ]
  then
    echo "-s <SOURCE_HOST> is required" && exit 1
  fi

  if [ -z "${DATABASE_NAME}" ]
  then
    echo "-d <DATABASE_NAME> is required" && exit 1
  fi

  if [ -z "${DESTINATION_OUTPUT_PATH}" ]
  then
    echo "-o <DESTINATION_OUTPUT_PATH> is required" && exit 1
  fi

  if [ -z "${REMOTE_PATH}" ]
  then
    echo "-r <REMOTE_PATH> is required" && exit 1
  fi  
}


backup() {
  echo "Started ${DATABASE_NAME} Mongo DataBase backup at ${SOURCE_HOST} host"

  local archive_name=mongo_dump_${DATABASE_NAME}_"$(date '+%Y-%m-%d-%H%M').gz"

  dump_db() {
    ssh ${USER}@${SOURCE_HOST} "mkdir -p /tmp"

    ssh ${USER}@${SOURCE_HOST} "mongodump --archive=/tmp/${archive_name} --gzip --db ${DATABASE_NAME}"
  }
  
  dump_db
  
  echo "[INFO][$(date -u)]: the backup archive ${archive_name} of the Mongo database ${DATABASE_NAME} has been successfully created at ${SOURCE_HOST} host."
     	
  MONGO_BACKUP_DIR=${DESTINATION_OUTPUT_PATH}
     
  mkdir -p ${MONGO_BACKUP_DIR}

  sh ${BACKUP_SCRIPTS_DIR}/download_files.sh -u ${USER} -s ${SOURCE_HOST} -f /tmp -d ${MONGO_BACKUP_DIR} -m ${archive_name}
        
  sh ${BACKUP_SCRIPTS_DIR}/rclone_upload_path.sh -s ${MONGO_BACKUP_DIR} -n ${RCLONE_REMOTE_NAME} -r ${SOURCE_HOST}${REMOTE_PATH}

  delete_dump_db() {
    ssh ${USER}@${SOURCE_HOST} "rm /tmp/${archive_name}"
  }

  delete_dump_db

  rm -rf ${MONGO_BACKUP_DIR}
}

echo "-------------------------------------------------------------------------------------"
echo "-------------------------------------------------------------------------------------"
echo "-------------------[INFO][$(date -u)]: Runing Mongo Backup Script --------------"
echo "-------------------------------------------------------------------------------------"
echo "-------------------------------------------------------------------------------------"

validate

backup