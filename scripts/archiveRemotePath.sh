#!/bin/sh

# Parsing arguments
while getopts "s:f:m:u:q" opt
do
    case $opt in
      s) SOURCE_HOST=$OPTARG;;
      f) SOURCE_INPUT_PATH=$OPTARG;;
      m) SOURCE_OUTPUT_PATH=$OPTARG;;                                                     
	  u) USER=$OPTARG;;
      q) QUIT=1;;
      :|\?) exit 1;;
    esac
done

echo "About to archive ${SOURCE_INPUT_PATH} into ${SOURCE_OUTPUT_PATH} at ${SOURCE_HOST}"

ssh ${USER}@${SOURCE_HOST} "tar -cvzf ${SOURCE_OUTPUT_PATH} ${SOURCE_INPUT_PATH}"

echo "Completed remote file to archive."

