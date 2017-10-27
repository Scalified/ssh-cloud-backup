#!/bin/sh

USER=root
GDRIVE_BIN=~/gdrive
TOKEN_URI="https://www.googleapis.com/oauth2/v4/token"
REFRESH_TOKEN="1/vnNuFb8DugZOV2Q8UC35G1tTH-3FVDoOeuI-9xJqvOk"
REFRESH_ACCESS_TOKEN_URI="https://developers.google.com/oauthplayground/refreshAccessToken"
BACKUP_DIR=~/.backup

# Parsing arguments
while getopts "s:u:f:m:h:t:q" opt
do
    case $opt in
      s) BACKUP_DIR_PATH=$OPTARG;;
      f) BACKUP_FILE=$OPTARG;;
      m) BACKUP_FILE_MASK=$OPTARG;;                                                     
      u) UPLOAD_PATH=$OPTARG;;
      h) SOURCE_HOST=$OPTARG;;
      t) TEMP_LOCAL_BACKUP_PATH=$OPTARG;;
      q) QUITE=1;;
      :|\?) exit 1;;
    esac
done

# Required params
[ -z $SOURCE_HOST ] && echo "-h <SOURCE_HOST> is required" && exit 1
[ -z $BACKUP_DIR_PATH ] && echo "-s <BACKUP_DIR_PATH> is required" && exit 1
[ -z $TEMP_LOCAL_BACKUP_PATH ] && echo "-t <TEMP_LOCAL_BACKUP_PATH> is required" && exit 1

backup() {        
        if [ -n "$BACKUP_DIR_PATH" ] && [ -n "$BACKUP_FILE" ]
        then
        	mkdir -p ${TEMP_LOCAL_BACKUP_PATH}
        	scp ${USER}@${SOURCE_HOST}:${BACKUP_DIR_PATH}/${BACKUP_FILE} ${TEMP_LOCAL_BACKUP_PATH}
            echo "SOURCE_HOST = ${SOURCE_HOST} and EXIT 0"
            echo "USER = ${USER} and EXIT 0"
            echo "BACKUP_DIR_PATH = ${BACKUP_DIR_PATH} and EXIT 0"
            echo "BACKUP_FILE = ${BACKUP_FILE} and EXIT 0"
            
            archive
            upload
        	
            exit 0;
        elif [ -n "${BACKUP_DIR_PATH}" ] && [ -n "${BACKUP_FILE_MASK}" ]        
        then	
            MASK=$(echo "${BACKUP_FILE_MASK}" | sed 's/.*\*//g')
        	FILES=$(ssh ${USER}@${SOURCE_HOST} ls ${BACKUP_DIR_PATH} |grep "\.jpg$")

            echo "-------------------------------------------------"
            echo "MASK = ${MASK}"
            echo "BACKUP_FILE_MASK = ${BACKUP_FILE_MASK}"
            echo "-------------------------------------------------"

            FILES=$(ssh ${USER}@${SOURCE_HOST} ls ${BACKUP_DIR_PATH} |grep ${MASK})
            echo "-------------------------------------------------"
            echo "FILES = ${FILES}"
            echo "-------------------------------------------------"	
            
            for file in ${FILES}                                                                               
  			do                                                                                                                        
    			echo "Coping the ${file} file ..."
    			mkdir -p ${TEMP_LOCAL_BACKUP_PATH}
    			scp ${USER}@${SOURCE_HOST}:${BACKUP_DIR_PATH}/${file} ${TEMP_LOCAL_BACKUP_PATH}
  			done

  			archive
  			upload  			
        	
        	exit 0;
        elif [ -n "$BACKUP_DIR_PATH" ]
        then
            mkdir -p ${TEMP_LOCAL_BACKUP_PATH}            
        	scp -r ${USER}@${SOURCE_HOST}:${BACKUP_DIR_PATH}/* ${TEMP_LOCAL_BACKUP_PATH}

        	archive
        	upload

        	exit 0;
        else
        	help
        	exit 1;
        fi	    
}

archive() {
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
	"[INFO][$(date -u)]: Updating your access-token ..."

    get_access_token() {
        local entity="{\"token_uri\":\"${TOKEN_URI}\",\"refresh_token\":\"${REFRESH_TOKEN}\"}"
        local access_token=`curl -d ${entity} -H "Content-Type: application/json" -X POST ${REFRESH_ACCESS_TOKEN_URI} | jq -r '.access_token'`
        
        #shell return 
        echo "${access_token}"
    }

    ACCESS_TOKEN=$(get_access_token)
    
	echo "BACKUP_ARCHIVE_NAME = ${BACKUP_ARCHIVE_NAME}"
	echo "FULL_BACKUP_FILE_PATH = ${FULL_BACKUP_FILE_PATH}"
	
	if [ -n "${ACCESS_TOKEN}" ]
	then
 		echo "[INFO][$(date -u)]: Successfully was got the access-token."
 		echo "ACCESS TOKEN = ${ACCESS_TOKEN}"
        
        GDRIVE_DIR_ID=$(get_gdrive_dir_id)  
        
        echo "GDRIVE_DIRECTORY_ID  =  ${GDRIVE_DIR_ID}"

        if [ -n "${GDRIVE_DIR_ID}" ]; then                                                                                                    
     		${GDRIVE_BIN}/gdrive sync upload ${UPLOAD_DIR} ${GDRIVE_DIR_ID} --access-token ${ACCESS_TOKEN}

     		if [ $? == 0 ]; then                                                                                                    
     			echo "[INFO][$(date -u)]: Successfully all files were uploaded to the GDRIVE folder /${SOURCE_HOST}"
     			exit 0;                                    
    		else                                                                                                                    
     			echo "[INFO][$(date -u)]: Failed to upload the files to the GDRIVE folder /${SOURCE_HOST}"
     			exit 1; 
    		fi                                                                                                                      

    	else                                                                                                                    
     		echo "[INFO][$(date -u)]: Creating gdrive /${SOURCE_HOST} directory..."
     		CREATED_GDRIVE_DIR_ID=$(${GDRIVE_BIN}/gdrive mkdir ${SOURCE_HOST} --access-token ${ACCESS_TOKEN} | awk  '{print $2}')

     		if [ -n "${CREATED_GDRIVE_DIR_ID}" ]; then
     			echo "[INFO][$(date -u)]: Successfully was created the GDRIVE folder /${SOURCE_HOST}"
     			echo "CREATED_GDRIVE_DIR_ID = ${CREATED_GDRIVE_DIR_ID}"
     			
     			echo "Starting to upload the files ..."
     			${GDRIVE_BIN}/gdrive sync upload ${UPLOAD_DIR} ${CREATED_GDRIVE_DIR_ID} --access-token ${ACCESS_TOKEN}

     			if [ $? == 0 ]; then                                                                                                    
     				echo "[INFO][$(date -u)]: Successfully all files were uploaded to the GDRIVE folder /${SOURCE_HOST}"
     				exit 0;                                    
    			else                                                                                                                    
     				echo "[INFO][$(date -u)]: Failed to upload the files to the GDRIVE folder /${SOURCE_HOST}"
     				exit 1; 
    			fi                                                                                                                      

     		else
     			echo "[INFO][$(date -u)]: Failed to create the GDRIVE folder /${SOURCE_HOST}"
     			exit 1;
     		fi	
    	fi                                                                                                                      	                		
	else
 		echo "[INFO][$(date -u)]: Failed to get the access-token."
 		exit 1;
	fi
}

get_gdrive_dir_id() {
	GDRIVE_DIRECTORY_ID=$(${GDRIVE_BIN}/gdrive list --access-token ${ACCESS_TOKEN} --query "trashed=false and name contains \"${SOURCE_HOST}\"" --no-header| grep "${SOURCE_HOST}.*dir" -m 1 | sed 's/ .*//')
    
    #shell return 
    echo "${GDRIVE_DIRECTORY_ID}"	
}	

help() {
	echo "HELP MANUAL"
}

backup

