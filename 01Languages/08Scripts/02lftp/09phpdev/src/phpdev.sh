#!/bin/bash
# programmer: De Dauw Valentijn
#       date: 2016/09/06
# sync /aegis/04php naar phptest server
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
# sync naar phpdev:///var/www/html =============================================================
#
# history
# 0.1.8 implementing isexecutable.sh
# 0.2.3 adapted to new lftp.sh

SCRIPT="phpdev.sh"
VERSION="0.2.3"
DATE="2019/02/02"

RETVAL=0
NO_ISEXECUTABLE=1
NO_PROGRAM=2

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

SILENCE=$1
if [ -z $SILENCE ]; then SILENCE="---"; fi
if [ $SILENCE = "silence" ]; then shift; fi
if [ $SILENCE = "SILENCE" ]; then shift; fi
PARAMS=("$@")

COMMAND=$1
if [ -z $COMMAND ]; then COMMAND="publish"; fi

TAG="PHPDEV"
MES="version $VERSION from $DATE"
logit

if [ ! -x /usr/bin/isexecutable.sh ]; then
        RETVAL=$NO_ISEXECUTABLE
        MES="isexecutable.sh not installed"
        loggerExit
fi

isexecutable.sh silence $TAG "lftp.sh"
if [ !$? -eq 0 ]; then
        RETVAL=$NO_PROGRAM
        MES="one or more executables not installed"
        loggerExit
fi

lftp.sh $SILENCE $COMMAND tag=$TAG host="phptest" localdir="/aegis/04php" remotedir="/var/www/html" user="www-data" password="www-datapw"
