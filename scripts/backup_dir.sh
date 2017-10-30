#!/bin/sh

USER=root
BACKUP_DIR=~/.backup
RCLONE_REMOTE_NAME="auto-backup"

# Parsing arguments
while getopts "s:h:t:m:a:q" opt
do
    case $opt in
      s) SOURCE_INPUT_PATH=$OPTARG;;
      h) SOURCE_HOST=$OPTARG;;
      t) DESTINATION_OUTPUT_PATH=$OPTARG;;  
      m) BACKUP_FILE_MASK=$OPTARG;;                                                                 
      a) ARCHIVE_REMOTELY=$OPTARG;;  
      q) QUITE=1;;
      :|\?) exit 1;;
    esac
done

# Required params
[ -z $SOURCE_HOST ] && echo "-h <SOURCE_HOST> is required" && exit 1
[ -z $SOURCE_INPUT_PATH ] && echo "-s <SOURCE_INPUT_PATH> is required" && exit 1
[ -z $DESTINATION_OUTPUT_PATH ] && echo "-t <DESTINATION_OUTPUT_PATH> is required" && exit 1

backup() {
        if [ -n "$ARCHIVE_REMOTELY" ]
        then
            if [ $ARCHIVE_REMOTELY = true ]
            then
                BACKUP_ARCHIVE_NAME="$(date '+%Y-%m-%d-%H%M').tar.gz"
                echo "BACKUP_ARCHIVE_NAME = ${BACKUP_ARCHIVE_NAME}"

                DESTINATION_REMOTE_PATH="/tmp"
                
                sh ${BACKUP_SCRIPTS_DIR}/archiveRemotePath.sh -u ${USER} -s ${SOURCE_HOST} -f ${SOURCE_INPUT_PATH} -m ${DESTINATION_REMOTE_PATH}/${BACKUP_ARCHIVE_NAME}
                
                sh ${BACKUP_SCRIPTS_DIR}/downloadFiles.sh -u ${USER} -s ${SOURCE_HOST} -f ${DESTINATION_REMOTE_PATH} -m ${BACKUP_ARCHIVE_NAME} -d ${BACKUP_DIR}/${SOURCE_HOST}                
                
                sh ${BACKUP_SCRIPTS_DIR}/rcloneUploadPath.sh -s ${BACKUP_DIR}/${SOURCE_HOST} -n ${RCLONE_REMOTE_NAME} -d ${SOURCE_HOST}                                                 
            else
                echo "The optional parameter -a must be set to \"true\""
                exit 1;
            fi    
            
            exit 0;
        elif [ -n "${BACKUP_FILE_MASK}" ]        
        then
            sh ${BACKUP_SCRIPTS_DIR}/downloadFiles.sh -u ${USER} -s ${SOURCE_HOST} -f ${SOURCE_INPUT_PATH} -d ${DESTINATION_OUTPUT_PATH} -m ${BACKUP_FILE_MASK}

            sh ${BACKUP_SCRIPTS_DIR}/arhiveLocalPath.sh -s ${DESTINATION_OUTPUT_PATH} -d ${BACKUP_DIR}/${SOURCE_HOST}
            
            rm -rf ${DESTINATION_OUTPUT_PATH}
            
            sh ${BACKUP_SCRIPTS_DIR}/rcloneUploadPath.sh -s ${BACKUP_DIR}/${SOURCE_HOST} -n ${RCLONE_REMOTE_NAME} -d ${SOURCE_HOST}                    
            
            exit 0;
        elif [ -n "SOURCE_INPUT_PATH" ]
        then
            sh ${BACKUP_SCRIPTS_DIR}/downloadPath.sh -u ${USER} -s ${SOURCE_HOST} -f ${SOURCE_INPUT_PATH} -d ${DESTINATION_OUTPUT_PATH}

            sh ${BACKUP_SCRIPTS_DIR}/arhiveLocalPath.sh -s ${DESTINATION_OUTPUT_PATH} -d ${BACKUP_DIR}/${SOURCE_HOST}

            rm -rf ${DESTINATION_OUTPUT_PATH}
            
            sh ${BACKUP_SCRIPTS_DIR}/rcloneUploadPath.sh -s ${BACKUP_DIR}/${SOURCE_HOST} -n ${RCLONE_REMOTE_NAME} -d ${SOURCE_HOST}                     

            exit 0;
        else
            help
        fi      
}

help() {
    echo "HELP MANUAL of SCRIPT"

    exit 0;
}

echo "-------------------------------------------------------------------------------------"
echo "-------------------------------------------------------------------------------------"
echo "-------------------[INFO][$(date -u)]: Script is run --------------"
echo "-------------------------------------------------------------------------------------"
echo "-------------------------------------------------------------------------------------"

backup