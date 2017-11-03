#!/bin/bash

set -e

USER=root

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
    validate_arg() {
        local arg="${!1}"
        local message="${2}"
        if [[ -z ${arg} ]]; then
            echo "${message}"
            exit 1
        fi
    }

    validate_arg 'SOURCE_HOST' '-s|--source-host <SOURCE_HOST> is required'
    validate_arg 'DATABASE_NAME' '-d <DATABASE_NAME> is required'
    validate_arg 'DESTINATION_OUTPUT_PATH' '-o <DESTINATION_OUTPUT_PATH> is required'
    validate_arg 'REMOTE_PATH' '-r <REMOTE_PATH> is required'
}

dump_db() {
    local archive_name="${1}"
    echo "About to dump ${DATABASE_NAME} database into ${archive_name}"
    ssh ${USER}@${SOURCE_HOST} "mkdir -p /tmp"
    ssh ${USER}@${SOURCE_HOST} "mongodump --archive=/tmp/${archive_name} --gzip --db ${DATABASE_NAME}"
}

delete_db_dump() {
    local archive_name="${1}"
    echo "About to delete ${archive_name} database dump file"
    ssh ${USER}@${SOURCE_HOST} "rm /tmp/${archive_name}"
}

backup() {
  echo "Started ${DATABASE_NAME} Mongo DataBase backup at ${SOURCE_HOST} host"

  local archive_name=mongo_dump_${DATABASE_NAME}_"$(date '+%Y-%m-%d-%H%M').gz"
  dump_db "${archive_name}"
  echo "[INFO][$(date -u)]: Backup archive ${archive_name} of the Mongo database ${DATABASE_NAME} has been successfully created at ${SOURCE_HOST} host."
     	
  mkdir -p ${DESTINATION_OUTPUT_PATH}
  sh ${BACKUP_SCRIPTS_DIR}/download_files.sh -u ${USER} -s ${SOURCE_HOST} -f /tmp -d ${DESTINATION_OUTPUT_PATH} -m ${archive_name}
  sh ${BACKUP_SCRIPTS_DIR}/rclone_upload_path.sh -s ${DESTINATION_OUTPUT_PATH} -n ${RCLONE_REMOTE_NAME} -r ${SOURCE_HOST}${REMOTE_PATH}

  delete_db_dump "${archive_name}"

  rm -rf ${DESTINATION_OUTPUT_PATH}
}

echo "-------------------[INFO][$(date -u)]: Runing Mongo Backup Script -------------------"

validate

backup
