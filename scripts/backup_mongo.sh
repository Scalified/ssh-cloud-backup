#!/bin/bash

USER=root
BACKUP_DIR=~/.backup
RCLONE_REMOTE_NAME="auto-backup"

  # Parsing arguments
  while getopts "s:d:o:q" opt
  do
    case $opt in
      s) SOURCE_HOST=$OPTARG;;
      d) DATABASE_NAME=$OPTARG;;
      o) DESTINATION_OUTPUT_PATH=$OPTARG;;  
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
}


backup() {
  echo "Started ${DATABASE_NAME} Mongo DataBase backup at ${SOURCE_HOST} host"

  local archive_name=mongo_dump_${DATABASE_NAME}_"$(date '+%Y-%m-%d-%H%M').gz"

  dump_db() {    
    ssh ${USER}@${SOURCE_HOST} "mongodump --archive=${DESTINATION_OUTPUT_PATH}/${archive_name} --gzip --db ${DATABASE_NAME}"
  }
  
  dump_db
  
  echo "[INFO][$(date -u)]: the backup archive ${archive_name} of the Mongo database ${DATABASE_NAME} has been successfully created at ${SOURCE_HOST} host."
     	
  MONGO_BACKUP_DIR=${BACKUP_DIR}/Mongo/${SOURCE_HOST}
     
  mkdir -p ${MONGO_BACKUP_DIR}

  sh ${BACKUP_SCRIPTS_DIR}/download_files.sh -u ${USER} -s ${SOURCE_HOST} -f ${DESTINATION_OUTPUT_PATH} -d ${MONGO_BACKUP_DIR} -m ${archive_name}
        
  sh ${BACKUP_SCRIPTS_DIR}/rclone_upload_path.sh -s ${MONGO_BACKUP_DIR} -n ${RCLONE_REMOTE_NAME} -d ${SOURCE_HOST}/Mongo

  delete_dump_db() {
    ssh ${USER}@${SOURCE_HOST} "rm ${DESTINATION_OUTPUT_PATH}/${archive_name}"
  }

  delete_dump_db
}

echo "-------------------------------------------------------------------------------------"
echo "-------------------------------------------------------------------------------------"
echo "-------------------[INFO][$(date -u)]: Runing Mongo Backup Script --------------"
echo "-------------------------------------------------------------------------------------"
echo "-------------------------------------------------------------------------------------"

validate

backup