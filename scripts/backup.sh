#!/bin/bash

set -e

USER=root
BACKUP_DIR=~/.backup
RCLONE_REMOTE_NAME="scalified-remote"

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
    validate_arg 'SOURCE_INPUT_PATH' '-i|--input-path <SOURCE_INPUT_PATH> is required'
    validate_arg 'REMOTE_PATH' '-r|--remote-path <REMOTE_PATH> is required'
    validate_arg 'DESTINATION_OUTPUT_PATH' '-o|--output-path <DESTINATION_OUTPUT_PATH> is required'
}

pipe_source_archive() {
    validate

    ${BACKUP_SCRIPTS_DIR}/pipe_source_archive.sh -u ${USER} -s ${SOURCE_HOST} -i ${SOURCE_INPUT_PATH} -o ${DESTINATION_OUTPUT_PATH}
    ${BACKUP_SCRIPTS_DIR}/rclone_upload_path.sh -s ${DESTINATION_OUTPUT_PATH} -n ${RCLONE_REMOTE_NAME} -r ${SOURCE_HOST}${REMOTE_PATH}
}

keep_source_archive() {
    validate

    local backup_archive_name="$(date '+%Y-%m-%d-%H%M').tar.gz"
    echo "Set ${backup_archive_name} backup archive name"

    local destination_remote_path="/tmp"

    ${BACKUP_SCRIPTS_DIR}/archive_remote_path.sh -u ${USER} -s ${SOURCE_HOST} -f ${SOURCE_INPUT_PATH} -m ${destination_remote_path}/${backup_archive_name}
    ${BACKUP_SCRIPTS_DIR}/download_files.sh -u ${USER} -s ${SOURCE_HOST} -f ${destination_remote_path} -m ${backup_archive_name} -d ${BACKUP_DIR}/${SOURCE_HOST}
    ${BACKUP_SCRIPTS_DIR}/rclone_upload_path.sh -s ${BACKUP_DIR}/${SOURCE_HOST} -n ${RCLONE_REMOTE_NAME} -r ${SOURCE_HOST}${REMOTE_PATH}
}

backup_files() {
    validate

    ${BACKUP_SCRIPTS_DIR}/download_files.sh -u ${USER} -s ${SOURCE_HOST} -f ${SOURCE_INPUT_PATH} -d ${DESTINATION_OUTPUT_PATH} -m ${BACKUP_FILE_MASK}
    ${BACKUP_SCRIPTS_DIR}/arhive_local_path.sh -s ${DESTINATION_OUTPUT_PATH} -d ${BACKUP_DIR}/${SOURCE_HOST}

    rm -rf ${DESTINATION_OUTPUT_PATH}

    ${BACKUP_SCRIPTS_DIR}/rclone_upload_path.sh -s ${BACKUP_DIR}/${SOURCE_HOST} -n ${RCLONE_REMOTE_NAME} -r ${SOURCE_HOST}${REMOTE_PATH}
}

backup_path_no_archived() {
    validate

    mkdir -p ${DESTINATION_OUTPUT_PATH}

    ${BACKUP_SCRIPTS_DIR}/download_path.sh -u ${USER} -s ${SOURCE_HOST} -f ${SOURCE_INPUT_PATH} -d ${DESTINATION_OUTPUT_PATH}
    ${BACKUP_SCRIPTS_DIR}/rclone_upload_path.sh -s ${DESTINATION_OUTPUT_PATH} -n ${RCLONE_REMOTE_NAME} -r ${SOURCE_HOST}${REMOTE_PATH}

    rm -rf ${DESTINATION_OUTPUT_PATH}
}

display_help() {
    echo "HELP MANUAL of SCRIPT"

    exit 0;
}

parse_arguments() {
    local ARGS=("$@")
    for i in "${!ARGS[@]}"; do
        case "${ARGS[i]}" in
            -h|--help)
                display_help
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

echo "-------------------[INFO][$(date -u)]: Running Backup Script -------------------"

parse_arguments "$@"
