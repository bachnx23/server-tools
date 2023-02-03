#!/bin/sh

RESET_COLOR='\033[0m'
## text color
WARNING='\033[1;33m'
DANGER='\033[1;31m'
SUCCESS='\033[1;32m'
BLACK='\033[1;30m'
WHITE='\033[1;37m'

REMOTE_IP=''
SSH_BASE_COMMAND='ssh -i /root/remote/access_rsa'
BACKUP_BASE_PATH='/mnt/data/mysql_backup/'

MYSQL_USER='percona'
MYSQL_PASSWORD='Megaads@123'

RSYNC_COMMAND=(
    "rsync -av"
    "-e \"${SSH_BASE_COMMAND}\""
    "root@${REMOTE_IP}:/tmp/xtrabackup*"
)

XTRABACKUP_ARGS=(
    "--user=$MYSQL_USER"
    "--password=$MYSQL_PASSWORD"
    "--backup"
    "--stream=xbstream"
    "--target-dir=./"
    "--extra-lsndir=/tmp/"
)

echo -e $WHITE"Enter remote server"$RESET_COLOR
read -p "REMOTE IP: " REMOTE_IP

CHECK_REMOTE_IP=$(curl -s --connect-timeout 5 http://${REMOTE_IP})

if [[ ! $CHECK_REMOTE_IP ]];then
    echo -e $DANGER"${REMOTE_IP} doesn't exists. Please, check again!"$RESET_COLOR
    exit;
fi

SSH_CHECK=$($SSH_BASE_COMMAND -o BatchMode=yes -o ConnectTimeout=5  root@$REMOTE_IP echo Done 2>&1)

ACCESS_STATE="next"

if [[ "$SSH_CHECK" != "Done" ]]; then
    echo -e $WARNING"Cannot connect to remote server. Please, create user and add access to remote server."$RESET_COLOR
    ACCESS_STATE="fail"
fi

CONTINUE=''
if [[ $ACCESS_STATE == 'fail' ]];then
    read -p "Continue?(Y/n) " CONTINUE
fi
if [[ "${CONTINUE,,}" == 'y' ]]; then 
    echo -e $WHITE"Please, add bellow public key to remote server"$RESET_COLOR
    PUBLIC_KEY=$(cat /root/remote/access_rsa.pub)
    echo -e $BLACK"$PUBLIC_KEY"$RESET_COLOR
    read -p "Configured! Continue?(Y/n) " CONTINUE
    if [[ "${CONTINUE,,}" != 'y' ]];then 
        exit;
    fi
elif [[ $ACCESS_STATE == 'fail' && "${CONTINUE,,}" != 'y' ]];then
    echo -e $WARNING"Bye!"$RESET_COLOR
    exit;
fi
echo -e  $SUCCESS"SSH check success! Check percona-xtrabackup was installed on the remote server yet."$RESET_COLOR

BACKUP_STEP=''

read -p "Do you want to check Xtrabackup or Run backup now?(C/B) " BACKUP_STEP

if [[ $BACKUP_STEP == 'c' ]];then
    CHECK_XTRABACKUP=$($SSH_BASE_COMMAND root@$REMOTE_IP -t "yum list installed | grep xtrabackup" 2>&1)
    INSTALLED_TEXT='percona-xtrabackup'

    if [[ "$CHECK_XTRABACKUP" != *"$INSTALLED_TEXT"* ]];then 
        echo -e $DANGER"Percona Xtrabackup wasn't installed on remote server $REMOTE_IP."$RESET_COLOR
        echo -e $WARNING"Start install Percona Xtrabackup version 2.4"$RESET_COLOR
        INSTALL_PERCONA_REPO=$($SSH_BASE_COMMAND root@$REMOTE_IP "yum -y install https://repo.percona.com/yum/percona-release-latest.noarch.rpm" 2>&1)
        # CHECK_PERCONA_REPO=$($SSH_BASE_COMMAND root@$REMOTE_IP -t "yum list | grep percona" 2>&1)
        INSTALL_XTRABACKUP=$($SSH_BASE_COMMAND root@$REMOTE_IP "yum -y install percona-xtrabackup-24" 2>&1)
        echo $INSTALL_XTRABACKUP
    fi
fi

echo -e $SUCCESS"Percona Xtrabackup was installed. Run backup now!"$RESET_COLOR

## Check access to mysql on remote
MYSQL_ACCESS=$($SSH_BASE_COMMAND root@$REMOTE_IP "mysql -u $MYSQL_USER -p$MYSQL_PASSWORD --batch --skip-column-names -e 'show databases;'" 2>&1)
FAIL_MYSQL_MESSAGE='Access denied for user'

if [[ "$MYSQL_ACCESS" == *"$FAIL_MYSQL_MESSAGE"* ]]; then
    echo -e $DANGER"Cannot access to MySQL Server. Please create mysql user follow command bellow: "$RESET_COLOR
    echo -e $BLACK"CREATE USER '$MYSQL_USER'@'localhost' IDENTIFIED BY '$MYSQL_PASSWORD';"$RESET_COLOR
    echo -e $BLACK"GRANT RELOAD, LOCK TABLES, PROCESS, REPLICATION CLIENT ON *.* TO '$MYSQL_USER'@'localhost';"$RESET_COLOR
    echo -e $BLACK"FLUSH PRIVILEGES;"$RESET_COLOR
fi

read -p "Enter name of database you want to backup. Backup all databases if blank: " DB_NAME

if [[ $DB_NAME != "" ]];then
    XTRABACKUP_ARGS+=("--databases=$DB_NAME")
fi

## Setup backup path separate by remote server
BACKUP_DB_PATH="$BACKUP_BASE_PATH$REMOTE_IP/"
BACKUP_LOG="$BACKUP_BASE_PATH$REMOTE_IP/backup.log"
TODAY_DIR="$BACKUP_DB_PATH$(date +%a)"

#Create directory to backup if not exists
if [[ ! -d "$BACKUP_DB_PATH" ]];then
    echo ""
    echo -e $WHITE"Backup directory not exists. Create new!"$RESET_COLOR
    mkdir -p $BACKUP_DB_PATH
    BACKUP_TYPE='full'
    BACKUP_DB_FILE="$BACKUP_BASE_PATH$REMOTE_IP/${BACKUP_TYPE}.xbstream"
fi

#Check if not exists base file take a full backup
#Else prepare for take a incremental backup 

if [[ -d "$BACKUP_DB_PATH" ]];then
    echo -e $BLACK"Check LSN point for prepare incremental backup"$RESET_COLOR

    if [[ -f "${BACKUP_DB_PATH}xtrabackup_checkpoints" ]];then 
        BACKUP_TYPE='incremental'
        LSN=$(awk '/to_lsn/ {print $3;}' "${BACKUP_DB_PATH}xtrabackup_checkpoints")
        XTRABACKUP_ARGS+=("--incremental-lsn=${LSN}")
        BACKUP_DB_FILE="${TODAY_DIR}/"
        mkdir -p "${BACKUP_DB_FILE}"
        BACKUP_DB_FILE="${TODAY_DIR}/${BACKUP_TYPE}.xbstream"
        BACKUP_DB_PATH="${TODAY_DIR}/"
        echo "${BACKUP_DB_FILE}"
    fi
fi
XTRABACKUP_COMMAND="xtrabackup ${XTRABACKUP_ARGS[@]}"

echo "****"
echo -e $WARNING"Take a ${BACKUP_TYPE} backup..."$RESET_COLOR
echo "${XTRABACKUP_COMMAND}"
RUN_BACKUP=$($SSH_BASE_COMMAND  root@$REMOTE_IP "${XTRABACKUP_COMMAND}" 2> "${BACKUP_LOG}" | gzip > "${BACKUP_DB_FILE}")

#Finish backup. If success, copy checkpoint file from remote to local server
#Else show error message
if tail -1 "${BACKUP_LOG}" | grep -q "completed OK"; then
    rsync -av -e "${SSH_BASE_COMMAND}" root@"${REMOTE_IP}":/tmp/xtrabackup* "${BACKUP_DB_PATH}"
    echo -e $SUCCESS"Backup successful!\n"$RESET_COLOR
else
    echo -e $DANGER"Backup failure! Check ${BACKUP_LOG} for more information"$RESET_COLOR
fi