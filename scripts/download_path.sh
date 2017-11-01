#!/bin/bash

# Parsing arguments
while getopts "s:f:d:u:q" opt
do
    case $opt in
      s) SOURCE_HOST=$OPTARG;;
      f) SOURCE_INPUT_PATH=$OPTARG;;
      d) DESTINATION_OUTPUT_PATH=$OPTARG;;
      u) USER=$OPTARG;;  
      q) QUIT=1;;
      :|\?) exit 1;;
    esac
done

echo "About to download the folder ${SOURCE_INPUT_PATH} at ${SOURCE_HOST} to local ${DESTINATION_OUTPUT_PATH} destination path."

mkdir -p ${DESTINATION_OUTPUT_PATH}

scp -r ${USER}@${SOURCE_HOST}:${SOURCE_INPUT_PATH}/* ${DESTINATION_OUTPUT_PATH}
  
echo "${SOURCE_INPUT_PATH} path downloading completed."

