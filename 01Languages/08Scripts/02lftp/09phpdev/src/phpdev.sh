#!/bin/bash
# programmer: De Dauw Valentijn
#       date: 2016/09/06
# sync /data/07Software/04php/06dev/01session/php naar phptest server
#
# arguments                         default
# TAG        tag=thetag             LFTP
# HOST       host=thehost
# DOMAIN     domain=thedomain       de-dauw.eu
# LOCALDIR   localdir=thedir
# REMOTEDIR  remotedir=thedir
# USER       user=theuser           www-data
# password   password=thepassword   www-datapw
#
# sync naar phpdev////var/www/html =============================================================

SCRIPT="lftp.publish.sh"
VERSION="0.1.7"
DATE="2019/02/02"

TAG="PHPDEV"
RETVAL=0
NO_PROGRAM=1

echoIt() {
   if [ -z $SILENCE ]; then SILENCE="---"; fi
   if [ $SILENCE = 'silence' ]; then return; fi
   if [ $SILENCE = 'SILENCE' ]; then return; fi
   echo "$MES"
}

# produce a log message in the logger and on screen
logit()
{
   MES="$SCRIPT $MES"
   logger -t $TAG "$MES"
   echo "$MES"
}

# log something and then exit abnormaly
loggerExit()
{
   verbose
   exit $RETVAL
}

lookiProgram() {
	RETVAL=$NO_PROGRAM
	if [ -z $PROGRAM ]; then
		MES2="Program undefined"
		loggerExit
	fi
	whereis $PROGRAM | grep /$PROGRAM > /dev/null
        if [ ! $? -eq 0 ]; then
                MES2="Program $PROGRAM not installed"
                loggerExit
        fi
}

SILENCE=$1

PROGRAM="lftp.sh"
lookiProgram

MES0="version $VERSION from $DATE"
logit

lftp.sh $SILENCE publish tag=$TAG host="phptest" localdir="/aegis/04php" remotedir="/var/www/html" user="www-data" password="www-datapw"
