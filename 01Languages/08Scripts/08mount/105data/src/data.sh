#!/bin/bash
#
# Programmer: De Dauw Valentijn
#       Date: 2016/10/08
#     Target: mounting the ch3snas nfs volume, data
#      Usage: data.sh command
#
# commands are:
#    mount, mount the data volume
#  unmount, unmount the data volume
#
# History
# 0.0.1 creation
# 0.0.2 added silence
# 0.0.3 checked, error in echoIt()
# 0.0.4 checked, error in calling mount.sh
# 0.1.1 used sjabloon, more associative array
# 0.1.2 removed associative array, added commands array
# 0.1.3 parameter values in command instead of variables, improves readability
# 0.1.8 implementing isexecutable.sh
# 0.1.9 adapted for rmount.sh

SCRIPT="data.sh"
DATE="2019/05/18"
VERSION="0.1.9"
MES=" "

RETVAL=0
NO_ISEXECUTABLE=-1
NO_PROGRAM=-2

# define arrays
OPTIONS=
COMMANDS=("mount" "unmount" "show" "free" "exports" "usage")

echoIt() {
   if [ -z $SILENCE ]; then SILENCE="---"; fi
   if [ $SILENCE = 'silence' ]; then return; fi
   if [ $SILENCE = 'SILENCE' ]; then return; fi
   echo "$MES"
}

logit()
{
   MES="$SCRIPT $MES"
   logger -t $TAG $MES
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
			return
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

TAG="DATA"
MES="version $VERSION from $DATE command=$1"
logit

if [ ! -x /usr/bin/isexecutable.sh ]; then
	RETVAL=$NO_ISEXECUTABLE
	MES="isexecutable.sh not installed"
	loggerExit
fi

isexecutable.sh silence $TAG "rmount.sh"
if [ ! $? -eq 0 ]; then
	RETVAL=$NO_PROGRAM
	MES="one or more programs not installed"
	loggerExit
fi
readCommandLineParameters

# default command
if [ -z $COMMAND ]; then COMMAND="mount"; fi

sudo rmount.sh $SILENCE $COMMAND tag="DATA" nfshost='ch3snas' nfsexport='/mnt/HD_a2/data' nfsmount='/data' nfsport=2049 nfssize='1,8T'

