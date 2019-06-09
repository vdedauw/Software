#!/bin/bash
# programmer: De Dauw Valentijn
#       date: 2016/09/06
# sync /aegis/17orders hermes:/public_html
#
# arguments                         default
# SILENCE
# COMMAND             publish, backup, show, usage
#
# sync naar phpdev://var/www/html =============================================================
#
# history
# 0.1.8 implementing isexecutable.sh

SCRIPT="orders.sh"
DATE="2019/05/28"
VERSION="0.1.8"

RETVAL=0
NO_ISEXECUTABLE=-1
NO_PROGRAM=2

TAG="ORDERS"

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
   echoIt
}

# log something and then exit abnormaly
loggerExit()
{
   logit
   exit $RETVAL
}

readCommandLineParameter() {
        MES="      read command line parameter $COUNT $PARAMETER"
        echoIt
        # read single word parameter
        for NAME in "${COMMANDS[@]}"
        do
                if [ $NAME = $PARAMETER ]; then
                        COMMAND=$PARAMETER
                fi
        done
}

# read the command line parameters
readCommandLineParameters() {
        # read the command line parameters
        MES="reading command line parameters"
        echoIt
        COUNT=1
        for PARAMETER in "${PARAMS[@]}"
        do
                readCommandLineParameter
                COUNT=$((COUNT+1))
        done
        MES=""
        echoIt
}

SILENCE=$1
if [ -z $SILENCE ]; then SILENCE="---"; fi
if [ $SILENCE = "silence" ]; then shift; fi
if [ $SILENCE = "SILENCE" ]; then shift; fi
PARAMS=("$@")

COMMAND=$1
if [ -z $COMMAND ]; then COMMAND="publish"; fi

TAG="HERMES"
MES="version $VERSION from $DATE"
logit

if [ ! -x /usr/bin/isexecutable.sh ]; then
        RETVAL=$NO_ISEXECUTABLE
        MES="isexecutable.sh not installed"
        loggerExit
fi

isexecutable.sh silence $TAG "lftp.sh"
if [ ! $? -eq 0 ]; then
	RETVAL=$NO_PROGRAM
	MES="one or more executables not installed."
	loggerExit
fi
readCommandLineParameters

MES="version $VERSION from $DATE"
logit

HOST="hermes"
USER="www-data"
PASSWORD="www-datapw"
LOCALDIR="/aegis/17Orders"
REMOTEDIR="/var/www/html/orders"

lftp.sh $SILENCE $COMMAND tag=$TAG host=$HOST localdir=$LOCALDIR remotedir=$REMOTEDIR user=$USER password=$PASSWORD
