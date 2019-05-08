#!/bin/bash
# programmer: De Dauw Valentijn
#       date: 2019/02/02
# sync webiste from provider to local dir
#
# tip when receiving lftp certificate error
# 1) create a new dir if not exists ~/lftp
# 2) create a new file ~/lftp/rc
#     contents one line: set ssl:verify-certificate no
#
# arguments                          default
# TAG         tag=thetag             LFTP
# HOST        host=thehost
# LOCALDIR    localdir=thedir
# REMOTEDIR   remotedir=thedir
# FTPUSER     user=theuser           www-data
# FTPPASSWORD password=thepassword   www-datapw
#
# when FTPPASSWORD is empty and FTPUSER=anonymous, connection is made without paswword
#
# arguments are decoded using their name part, example: domain= for the domain
#

SCRIPT="lftp.backup.sh"
VERSION="0.0.4"
DATE="2019/02/02"

RETVAL=0
NO_HOST=1
NO_USER=2
NO_PASSWORD=3
NO_LOCAL_DIR=4
NO_REMOTE_DIR=5
NO_PROGRAM=6
NO_TAG=7

TAG="LFTPBACKUP"
PORT=ftp

SYNTAXS=("tag=" "host=" "localdir=" "remotedir=" "user=" "password=")
PROGRAMS=("gawk" "grep" "lftp")
ARGS=("$@")

# produce a log message in the logger and on screen
logit()
{
   logger -t $TAG "$MES"
   echo "$MES"
}

# log something and then exit abnormaly
loggerExit()
{
   logit
   exit $RETVAL
}

lookiProgram() {
        MES="check program $PROGRAM"
        logit
        RETVAL=$NO_PROGRAM
        if [ -z $PROGRAM ]; then
                MES="Program undefined"
                loggerExit
        fi
        whereis $PROGRAM | grep /$program > /dev/null
        if [ ! $? -eq 0 ]; then
                MES="Program $PROGRAM not installed"
                loggerExit
        fi
}

lookiArg() {
        echo $ARGUMENT | grep $SYNTAX > /dev/null
        if [ $? -eq 0 ]; then
                VALUE=$(echo $ARGUMENT | gawk -F = '{print $2}')
        fi
        case $SYNTAX in
                "tag=") TAG=$VALUE
                        if [ -z $TAG ]; then TAG="LFTPBACKUP"; fi
                ;;
		"host=") HOST=$VALUE ;;
		"localdir=") LOCALDIR=$VALUE ;;
                "remotedir=") REMOTEDIR=$VALUE ;;
                "user=") FTPUSER=$VALUE ;;
                "password=") FTPPASSWORD=$VALUE ;;
        esac
}

lookiArgument() {
	echo "checking argument $ARGUMENT"
        for SYNTAX in "${SYNTAXS[@]}"
        do
                lookiArg
        done
}

hasHost() {
        RETVAL=$NO_HOST
        if [ -z $HOST ]; then
                MES="HOST undefined"
                loggerExit
        fi
}

hasUser() {
        RETVAL=$NO_USER
        if [ -z $FTPUSER ]; then
                MES="USER undefined"
                loggerExit
        fi
}

hasPassword() {
        RETVAL=$NO_PASSWORD
	if [ -z $FTPPASSWORD ]; then
		MES="no password checking for anonymous"
		logit
		if [ $FTPUSER = "anonymous" ]; then
			MES="use anonymous working with no password"
			logit
			return
		fi
	fi
        if [ -z $FTPPASSWORD ]; then
                MES="PASSWORD undefined"
                loggerExit
        fi
}

hasLocalDir() {
        RETVAL=$NO_LOCAL_DIR
        if [ -z $LOCALDIR ]; then
                MES="Local directory undefined"
                loggerExit
        fi
        if [ ! -d $LOCALDIR ]; then
                MES="Local directory $LOCALDIR does not exist"
                loggerExit
        fi
}

hasRemoteDir() {
        RETVAL=$NO_REMOTE_DIR
        if [ -z $REMOTEDIR ]; then
                MES="Remote directory undefined"
                loggerExit
        fi
}

echo "$SCRIPT version $VERSION from $DATE"

for PROGRAM in "${PROGRAMS[@]}"
do
        lookiProgram
done
echo

COUNT=1
for ARGUMENT in "${ARGS[@]}"
do
	lookiArgument
	COUNT=$(($COUNT + 1))
done
echo

hasHost
hasLocalDir
hasRemoteDir
hasUser
hasPassword

echo "tag $TAG"
echo "host $HOST"
echo "port $PORT"
echo "localdir $LOCALDIR"
echo "remotedir $REMOTEDIR"
echo "user $FTPUSER"
echo "password $FTPPASSWORD"

# do the syncing, from local to host
FTPURL="$PORT://$FTPUSER:$FTPPASSWORD@$HOST"
DELETE="--delete"
lftp -c "set $PORT:list-options -a;
set ssl:verify-certificate no
open '$FTPURL';
lcd $LOCALDIR;
cd $REMOTEDIR;
mirror $DELETE --verbose "

