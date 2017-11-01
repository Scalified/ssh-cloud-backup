#!/bin/bash

# Parsing arguments
while getopts "s:i:o:u:q" opt
do
    case $opt in
      s) SOURCE_HOST=$OPTARG;;
      i) SOURCE_INPUT_PATH=$OPTARG;;
      o) DESTINATION_OUTPUT_PATH=$OPTARG;;                                                     
	  u) USER=$OPTARG;;
      q) QUIT=1;;
      :|\?) exit 1;;
    esac
done

echo "About to archive ${SOURCE_INPUT_PATH} at ${SOURCE_HOST} into ${DESTINATION_OUTPUT_PATH} local path"

archive_name=`date "+%Y-%m-%d-%H%M"`.tgz

mkdir -p ${DESTINATION_OUTPUT_PATH}

ssh ${USER}@${SOURCE_HOST} "cd ${SOURCE_INPUT_PATH} && tar -cvf - * | gzip -9" > ${DESTINATION_OUTPUT_PATH}/${archive_name}

echo "${SOURCE_INPUT_PATH} remote path archiving completed to local ${DESTINATION_OUTPUT_PATH} DESTINATION_OUTPUT_PATH"

