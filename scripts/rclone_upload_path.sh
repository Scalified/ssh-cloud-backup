#!/bin/bash

# Parsing arguments
while getopts "s:d:n:q" opt
do
    case $opt in
      s) SOURCE_INPUT_PATH=$OPTARG;;
      d) DESTINATION_OUTPUT_PATH=$OPTARG;;
	  n) RCLONE_REMOTE_NAME=$OPTARG;; 	  
      q) QUIT=1;;
      :|\?) exit 1;;
    esac
done

echo "About to upload the local folder ${SOURCE_INPUT_PATH} to ${DESTINATION_OUTPUT_PATH} destination path on the remote ${RCLONE_REMOTE_NAME} cloud environment."
     
rclone copy ${SOURCE_INPUT_PATH} ${RCLONE_REMOTE_NAME}:/${DESTINATION_OUTPUT_PATH}

echo "Completed ${SOURCE_INTPUT_PATH} path uploading to ${DESTINATION_OUTPUT_PATH} path."

