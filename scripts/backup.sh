#!/bin/bash

USER=root
BACKUP_DIR=~/.backup
RCLONE_REMOTE_NAME="auto-backup"

validate_extended() {
    validate_base
    
    # Required params    
    [ -z $DESTINATION_OUTPUT_PATH ] && echo "-o|--output-path <DESTINATION_OUTPUT_PATH> is required" && exit 1    
}

validate_base() {
    # Required params
    [ -z $SOURCE_HOST ] && echo "-s|--source-host <SOURCE_HOST> is required" && exit 1
    [ -z $SOURCE_INPUT_PATH ] && echo "-i|--input-path <SOURCE_INPUT_PATH> is required" && exit 1
}

backup_local_archived_path() {
    validate_base

    sh ${BACKUP_SCRIPTS_DIR}/archive_local_remote_path.sh -u ${USER} -s ${SOURCE_HOST} -i ${SOURCE_INPUT_PATH} -o ${BACKUP_DIR}/${SOURCE_HOST}

    sh ${BACKUP_SCRIPTS_DIR}/rclone_upload_path.sh -s ${BACKUP_DIR}/${SOURCE_HOST} -n ${RCLONE_REMOTE_NAME} -d ${SOURCE_HOST}
}

backup_archived_path() {
    validate_extended

    BACKUP_ARCHIVE_NAME="$(date '+%Y-%m-%d-%H%M').tar.gz"
    echo "BACKUP_ARCHIVE_NAME = ${BACKUP_ARCHIVE_NAME}"

    DESTINATION_REMOTE_PATH="/tmp"
                
    sh ${BACKUP_SCRIPTS_DIR}/archive_remote_path.sh -u ${USER} -s ${SOURCE_HOST} -f ${SOURCE_INPUT_PATH} -m ${DESTINATION_REMOTE_PATH}/${BACKUP_ARCHIVE_NAME}
                
    sh ${BACKUP_SCRIPTS_DIR}/download_files.sh -u ${USER} -s ${SOURCE_HOST} -f ${DESTINATION_REMOTE_PATH} -m ${BACKUP_ARCHIVE_NAME} -d ${BACKUP_DIR}/${SOURCE_HOST}
                
    sh ${BACKUP_SCRIPTS_DIR}/rclone_upload_path.sh -s ${BACKUP_DIR}/${SOURCE_HOST} -n ${RCLONE_REMOTE_NAME} -d ${SOURCE_HOST}           
}

backup_files() {
    validate_extended

    sh ${BACKUP_SCRIPTS_DIR}/download_files.sh -u ${USER} -s ${SOURCE_HOST} -f ${SOURCE_INPUT_PATH} -d ${DESTINATION_OUTPUT_PATH} -m ${BACKUP_FILE_MASK}

    sh ${BACKUP_SCRIPTS_DIR}/arhive_local_path.sh -s ${DESTINATION_OUTPUT_PATH} -d ${BACKUP_DIR}/${SOURCE_HOST}
            
    rm -rf ${DESTINATION_OUTPUT_PATH}
            
    sh ${BACKUP_SCRIPTS_DIR}/rclone_upload_path.sh -s ${BACKUP_DIR}/${SOURCE_HOST} -n ${RCLONE_REMOTE_NAME} -d ${SOURCE_HOST}                    
}

backup_path() {
    validate_extended

    sh ${BACKUP_SCRIPTS_DIR}/download_path.sh -u ${USER} -s ${SOURCE_HOST} -f ${SOURCE_INPUT_PATH} -d ${DESTINATION_OUTPUT_PATH}

    sh ${BACKUP_SCRIPTS_DIR}/arhive_local_path.sh -s ${DESTINATION_OUTPUT_PATH} -d ${BACKUP_DIR}/${SOURCE_HOST}

    rm -rf ${DESTINATION_OUTPUT_PATH}
            
    sh ${BACKUP_SCRIPTS_DIR}/rclone_upload_path.sh -s ${BACKUP_DIR}/${SOURCE_HOST} -n ${RCLONE_REMOTE_NAME} -d ${SOURCE_HOST}                     
}

parse_arguments() {
    local ARGS=("$@")
    for i in "${!ARGS[@]}"; do
        case "${ARGS[i]}" in
            -h|--help)
                help
                ;;
            -s|--source-host)
                SOURCE_HOST=${ARGS[i+1]}
                echo "SOURCE_HOST=${SOURCE_HOST}"
                ;;
            -i|--input-path)
                SOURCE_INPUT_PATH=${ARGS[i+1]}
                echo "SOURCE_INPUT_PATH=${SOURCE_INPUT_PATH}"
                ;;
            -o|--output-path)
                DESTINATION_OUTPUT_PATH=${ARGS[i+1]}
                echo "DESTINATION_OUTPUT_PATH=${DESTINATION_OUTPUT_PATH}"
                ;;
            -m|--mask)
                BACKUP_FILE_MASK=${ARGS[i+1]}
                echo "BACKUP_FILE_MASK=${BACKUP_FILE_MASK}"
                ;;        
            --backup-archived-path)
                backup_archived_path
                exit 0
                ;;
            --backup-files)
                backup_files
                exit 0
                ;;
            --backup-path)
                backup_path
                exit 0
                ;;
            --backup-local-archived-path)
                backup_local_archived_path
                exit 0;
                ;;        
        esac
    done
}

help() {
    echo "HELP MANUAL of SCRIPT"

    exit 0;
}

echo "-------------------------------------------------------------------------------------"
echo "-------------------------------------------------------------------------------------"
echo "-------------------[INFO][$(date -u)]: Running Backup Script ----------"
echo "-------------------------------------------------------------------------------------"
echo "-------------------------------------------------------------------------------------"

parse_arguments "$@"