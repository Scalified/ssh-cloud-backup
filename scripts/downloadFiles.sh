#!/bin/sh

# Parsing arguments
while getopts "s:f:d:m:u:q" opt
do
    case $opt in
      s) SOURCE_HOST=$OPTARG;;
      f) SOURCE_INPUT_PATH=$OPTARG;;
      d) DESTINATION_OUTPUT_PATH=$OPTARG;;
      m) FILE_MASK=$OPTARG;;
      u) USER=$OPTARG;;  
      q) QUIT=1;;
      :|\?) exit 1;;
    esac
done

echo "About to download the files by ${FILE_MASK} mask from ${SOURCE_INPUT_PATH} at ${SOURCE_HOST} to local ${DESTINATION_OUTPUT_PATH} destination path."

FILES=$(ssh ${USER}@${SOURCE_HOST} ls ${SOURCE_INPUT_PATH} |grep ${FILE_MASK})

mkdir -p ${DESTINATION_OUTPUT_PATH}

for file in ${FILES}                                                                               
do                                                                                                                        
	echo "Start downloading the ${file} file ..."
    scp ${USER}@${SOURCE_HOST}:${SOURCE_INPUT_PATH}/${file} ${DESTINATION_OUTPUT_PATH}
done

echo "Completed downloading."

