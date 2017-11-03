#!/bin/bash

set -e

USER=root
BACKUP_DIR=~/.backup
RCLONE_REMOTE_NAME="scalified-remote"

validate_extended() {
    validate_base
    
    # Required params    
    [ -z $DESTINATION_OUTPUT_PATH ] && echo "-o|--output-path <DESTINATION_OUTPUT_PATH> is required" && exit 1    
}

validate_base() {
    # Required params
    [ -z $SOURCE_HOST ] && echo "-s|--source-host <SOURCE_HOST> is required" && exit 1
    [ -z $SOURCE_INPUT_PATH ] && echo "-i|--input-path <SOURCE_INPUT_PATH> is required" && exit 1
    [ -z $REMOTE_PATH ] && echo "-r|--remote-path <REMOTE_PATH> is required" && exit 1
}

pipe_source_archive() {
    validate_extended

    sh ${BACKUP_SCRIPTS_DIR}/pipe_source_archive.sh -u ${USER} -s ${SOURCE_HOST} -i ${SOURCE_INPUT_PATH} -o ${DESTINATION_OUTPUT_PATH}

    sh ${BACKUP_SCRIPTS_DIR}/rclone_upload_path.sh -s ${DESTINATION_OUTPUT_PATH} -n ${RCLONE_REMOTE_NAME} -r ${SOURCE_HOST}$REMOTE_PATH
}

keep_source_archive() {
    validate_extended

    BACKUP_ARCHIVE_NAME="$(date '+%Y-%m-%d-%H%M').tar.gz"
    echo "BACKUP_ARCHIVE_NAME = ${BACKUP_ARCHIVE_NAME}"

    DESTINATION_REMOTE_PATH="/tmp"
                
    sh ${BACKUP_SCRIPTS_DIR}/archive_remote_path.sh -u ${USER} -s ${SOURCE_HOST} -f ${SOURCE_INPUT_PATH} -m ${DESTINATION_REMOTE_PATH}/${BACKUP_ARCHIVE_NAME}
                
    sh ${BACKUP_SCRIPTS_DIR}/download_files.sh -u ${USER} -s ${SOURCE_HOST} -f ${DESTINATION_REMOTE_PATH} -m ${BACKUP_ARCHIVE_NAME} -d ${BACKUP_DIR}/${SOURCE_HOST}
                
    sh ${BACKUP_SCRIPTS_DIR}/rclone_upload_path.sh -s ${BACKUP_DIR}/${SOURCE_HOST} -n ${RCLONE_REMOTE_NAME} -r ${SOURCE_HOST}$REMOTE_PATH           
}

backup_files() {
    validate_extended

    sh ${BACKUP_SCRIPTS_DIR}/download_files.sh -u ${USER} -s ${SOURCE_HOST} -f ${SOURCE_INPUT_PATH} -d ${DESTINATION_OUTPUT_PATH} -m ${BACKUP_FILE_MASK}

    sh ${BACKUP_SCRIPTS_DIR}/arhive_local_path.sh -s ${DESTINATION_OUTPUT_PATH} -d ${BACKUP_DIR}/${SOURCE_HOST}
            
    rm -rf ${DESTINATION_OUTPUT_PATH}
            
    sh ${BACKUP_SCRIPTS_DIR}/rclone_upload_path.sh -s ${BACKUP_DIR}/${SOURCE_HOST} -n ${RCLONE_REMOTE_NAME} -r ${SOURCE_HOST}$REMOTE_PATH                    
}

backup_path_no_archived() {
    validate_extended

    local upload_dir_path=${DESTINATION_OUTPUT_PATH}

    mkdir -p ${DESTINATION_OUTPUT_PATH}

    sh ${BACKUP_SCRIPTS_DIR}/download_path.sh -u ${USER} -s ${SOURCE_HOST} -f ${SOURCE_INPUT_PATH} -d ${upload_dir_path}

    sh ${BACKUP_SCRIPTS_DIR}/rclone_upload_path.sh -s ${upload_dir_path} -n ${RCLONE_REMOTE_NAME} -r ${SOURCE_HOST}$REMOTE_PATH

    rm -rf ${DESTINATION_OUTPUT_PATH}
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
            -r|--remote-path)
                REMOTE_PATH=${ARGS[i+1]}
                echo "REMOTE_PATH=${REMOTE_PATH}"
                ;;            
            --keep-source-archive)
                keep_source_archive
                exit 0
                ;;
            --backup-files)
                backup_files
                exit 0
                ;;
            --pipe-source-archive)
                pipe_source_archive
                exit 0;
                ;;
            --backup-path-no-archived)
                backup_path_no_archived
                exit 0;
                ;;            
        esac
    done
}

help() {
    echo "HELP MANUAL of SCRIPT"

    exit 0;
}

echo "-------------------[INFO][$(date -u)]: Running Backup Script -------------------"

parse_arguments "$@"