#!/bin/sh

USER=root
BACKUP_DIR=~/.backup
RCLONE_REMOTE_NAME="auto-backup"

# Parsing arguments
while getopts "a:s:u:f:m:h:t:q" opt
do
    case $opt in
      s) BACKUP_DIR_PATH=$OPTARG;;
      f) BACKUP_FILE=$OPTARG;;
      m) BACKUP_FILE_MASK=$OPTARG;;                                                     
      u) UPLOAD_PATH=$OPTARG;;
      h) SOURCE_HOST=$OPTARG;;
      t) TEMP_LOCAL_BACKUP_PATH=$OPTARG;;
      a) ARCHIVE_REMOTELY=$OPTARG;;  
      q) QUITE=1;;
      :|\?) exit 1;;
    esac
done

# Required params
[ -z $SOURCE_HOST ] && echo "-h <SOURCE_HOST> is required" && exit 1
[ -z $BACKUP_DIR_PATH ] && echo "-s <BACKUP_DIR_PATH> is required" && exit 1
[ -z $TEMP_LOCAL_BACKUP_PATH ] && echo "-t <TEMP_LOCAL_BACKUP_PATH> is required" && exit 1

backup() {
        if [ -n "$BACKUP_DIR_PATH" ] && [ -n "$ARCHIVE_REMOTELY" ]
        then
            if [ $ARCHIVE_REMOTELY = true ]
            then
                BACKUP_ARCHIVE_NAME="$(date '+%Y-%m-%d-%H%M').tar.gz"
                echo "BACKUP_ARCHIVE_NAME = ${BACKUP_ARCHIVE_NAME}"

                FULL_REMOTE_ARCHIVE_SAVED_PATH="/tmp"
                ssh ${SOURCE_HOST} "cd ${BACKUP_DIR_PATH} && tar -cvzf ${FULL_REMOTE_ARCHIVE_SAVED_PATH}/${BACKUP_ARCHIVE_NAME} ${BACKUP_DIR_PATH}" 2> /dev/null

                if [ $? == 0 ]; then
                    echo "[INFO][$(date -u)]: Successfully was created the archive ${BACKUP_ARCHIVE_NAME} on remote host ${SOURCE_HOST}"
                    echo "Start coping the backup archive ${BACKUP_ARCHIVE_NAME} from remote host ${SOURCE_HOST}"

                    UPLOAD_DIR=${BACKUP_DIR}/${SOURCE_HOST}
                    
                    mkdir -p ${BACKUP_DIR}
                    mkdir -p ${UPLOAD_DIR}
                    
                    scp ${USER}@${SOURCE_HOST}:${FULL_REMOTE_ARCHIVE_SAVED_PATH}/${BACKUP_ARCHIVE_NAME} ${UPLOAD_DIR}

                    if [ $? == 0 ]; then
                        echo "[INFO][$(date -u)]: Successfully was copied the archive ${BACKUP_ARCHIVE_NAME} from remote host ${SOURCE_HOST}"
                        echo "[INFO][$(date -u)]: Start uploading on GDrive ..."

                        upload
                        exit 0;                
                    else
                        echo "[INFO][$(date -u)]: Failed to copy the file ${BACKUP_FILE}."
                        exit 1;
                    fi

                else
                    echo "[INFO][$(date -u)]: Failed to create the archive on remote host ${SOURCE_HOST}"
                    exit 1;
                fi
            else
                echo "The optional parameter -a must be set to \"true\""
                exit 1;
            fi    
            
            exit 0;
        elif [ -n "$BACKUP_DIR_PATH" ] && [ -n "$BACKUP_FILE" ]
        then
            mkdir -p ${TEMP_LOCAL_BACKUP_PATH}
            scp ${USER}@${SOURCE_HOST}:${BACKUP_DIR_PATH}/${BACKUP_FILE} ${TEMP_LOCAL_BACKUP_PATH}
            echo "BACKUP SOURCE_HOST = ${SOURCE_HOST}"
            echo "BACKUP_DIR_PATH = ${BACKUP_DIR_PATH}"
            echo "BACKUP_FILE = ${BACKUP_FILE}"

            if [ $? == 0 ]; then
                echo "[INFO][$(date -u)]: Successfully the file ${BACKUP_FILE} was copied."                
            else
                echo "[INFO][$(date -u)]: Failed to copy the file ${BACKUP_FILE}."
                exit 1;
            fi
            
            archive
            upload
            
            exit 0;
        elif [ -n "${BACKUP_DIR_PATH}" ] && [ -n "${BACKUP_FILE_MASK}" ]        
        then    
            MASK=$(echo "${BACKUP_FILE_MASK}" | sed 's/.*\*//g')            

            echo "-------------------------------------------------"
            echo "MASK = ${MASK}"
            echo "BACKUP_FILE_MASK = ${BACKUP_FILE_MASK}"
            echo "-------------------------------------------------"

            FILES=$(ssh ${USER}@${SOURCE_HOST} ls ${BACKUP_DIR_PATH} |grep ${MASK})
            echo "-------------------------------------------------"
            echo "REMOTE FILES for COPING = ${FILES}"
            echo "-------------------------------------------------"    
            
            for file in ${FILES}                                                                               
            do                                                                                                                        
                echo "Start coping the ${file} file ..."
                mkdir -p ${TEMP_LOCAL_BACKUP_PATH}
                scp ${USER}@${SOURCE_HOST}:${BACKUP_DIR_PATH}/${file} ${TEMP_LOCAL_BACKUP_PATH}
            done

            if [ $? == 0 ]; then
                echo "[INFO][$(date -u)]: Successfully all files were copied."                
            else
                echo "[INFO][$(date -u)]: Failed to copy the files."
                exit 1;
            fi

            archive
            upload              
            
            exit 0;
        elif [ -n "$BACKUP_DIR_PATH" ]
        then
            mkdir -p ${TEMP_LOCAL_BACKUP_PATH}

            echo "Runs a recursive copy of the entire directory on the remote machine ${SOURCE_HOST} ..."

            scp -r ${USER}@${SOURCE_HOST}:${BACKUP_DIR_PATH}/* ${TEMP_LOCAL_BACKUP_PATH}

            if [ $? == 0 ]; then
                echo "[INFO][$(date -u)]: Successfully the copy of the directory was done."                
            else
                echo "[INFO][$(date -u)]: Failed to copy the directory."
                exit 1;
            fi

            archive
            upload

            exit 0;
        else
            help
            exit 1;
        fi      
}

archive() {
    echo "[INFO][$(date -u)]: Start archiving ..."

    if [ -n "${TEMP_LOCAL_BACKUP_PATH}" ] && [ -d "${TEMP_LOCAL_BACKUP_PATH}" ]
        then
            BACKUP_ARCHIVE_NAME=`date "+%Y-%m-%d-%H%M"`.tar.gz
            UPLOAD_DIR=${BACKUP_DIR}/${SOURCE_HOST}
            FULL_BACKUP_FILE_PATH=${UPLOAD_DIR}/${BACKUP_ARCHIVE_NAME}          

            mkdir -p ${BACKUP_DIR}
            mkdir -p ${UPLOAD_DIR}
            
            tar -cvzf ${FULL_BACKUP_FILE_PATH} ${TEMP_LOCAL_BACKUP_PATH} 2> /dev/null               
            
            if [ $? == 0 ]; then
                echo "[INFO][$(date -u)]: Successfully was created the backup archive."
                
                rm -rf ${TEMP_LOCAL_BACKUP_PATH}

                if [ $? == 0 ]; then
                    echo "[INFO][$(date -u)]: Successfully was deleted the directory of temp backup."
                else
                    echo "[INFO][$(date -u)]: Failed to delete the directory of temp backup."
                    exit 1;
                fi
            else
                echo "[INFO][$(date -u)]: Failed to create a tar archive."
                exit 1;
            fi
        else
            echo "[INFO][$(date -u)]: Archiving error. Path to the archive directory = ${TEMP_LOCAL_BACKUP_PATH}"
            exit 1;        
        fi
}

upload() {
     echo "[INFO][$(date -u)]: Start uploading the files ..."

     GDRIVE_DIR=${SOURCE_HOST}

     rclone copy ${UPLOAD_DIR} ${RCLONE_REMOTE_NAME}:/${GDRIVE_DIR}

     if [ $? == 0 ]; then
        echo "[INFO][$(date -u)]: Successfully all files were uploaded to the GDRIVE folder /${GDRIVE_DIR}"
        exit 0;
     else
        echo "[INFO][$(date -u)]: Failed to upload the files to the GDRIVE folder /${GDRIVE_DIR}"
        exit 1;
     fi
}

help() {
    echo "HELP MANUAL of SCRIPT"
}

echo "-------------------------------------------------------------------------------------"
echo "-------------------------------------------------------------------------------------"
echo "-------------------[INFO][$(date -u)]: Script is run --------------"
echo "-------------------------------------------------------------------------------------"
echo "-------------------------------------------------------------------------------------"

backup