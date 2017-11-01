#!/bin/bash

# Parsing arguments
while getopts "s:d:q" opt
do
    case $opt in
      s) SOURCE_INPUT_PATH=$OPTARG;;
      d) DESTINATION_OUTPUT_PATH=$OPTARG;;  
      q) QUIT=1;;
      :|\?) exit 1;;
    esac
done

echo "About to archive the folder ${SOURCE_INPUT_PATH} to local ${DESTINATION_OUTPUT_PATH} destination path."

mkdir -p ${DESTINATION_OUTPUT_PATH}

BACKUP_ARCHIVE_NAME="$(date '+%Y-%m-%d-%H%M').tar.gz"

tar -cvzf ${DESTINATION_OUTPUT_PATH}/${BACKUP_ARCHIVE_NAME} ${SOURCE_INPUT_PATH}

echo "${SOURCE_INPUT_PATH} local path archiving completed."

