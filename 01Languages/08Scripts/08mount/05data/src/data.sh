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

TAG=DATA
SCRIPT="data.sh"
DATE="2019/05/06"
VERSION="0.0.3"
MES=" "

NFSHOST=ch3snas
HOSTS=/var/lib/bind/de-dauw.eu.hosts
NFSMOUNT=/data
NFSPORT=2049
NFSEXPORT=/mnt/HD_a2/data
SIZE=1,8T

RETVAL=0
NO_MOUNT=1

PROGRAMS=("mount.sh" "showmount")

# return values indicating incorrect command line values are the same as the check numbers
# as a documentation feature they are repeated as an error name
TNAME="tag"
IS_TAG=1                 # dummy value, no check for 'tag'
CNAME="command"
IS_COMMAND=2             # dummy value, no check for 'command'

# define arrays
PROGRAMS=("mount.sh" "showmount")
PARAMS=("$@")
OPTIONS=
COMMANDS=("silence" "mount" "unmount" "show" "free")

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

lookiProgram() {
        MES="      check program $PROGRAM"
        echoIt
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

lookiPrograms() {
        MES=""
        echoIt
        MES="Checking programs"
        echoIt
        for PROGRAM in "${PROGRAMS[@]}"
        do
                lookiProgram
        done
        MES=""
        echoIt
}

readCommandLineParameter() {
        MES="      read command line parameter $COUNT $PARAMETER"
        echoIt

        # read single word parameter
        for NAME in "${!COMMANDS[@]}"
        do
                if [ $NAME = "silence" ]; then
                        SILENCE=$PARAMETER
                fi
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

# commands are:
#    mount, mount the NASs exported volume
#  unmount, unmount the NASs exported volume
MES="version $VERSION from $DATE command=$1"
logit

lookiPrograms
readCommandLineParameters

if [ -z $COMMAND ]; then COMMAND="mount"; fi

sudo mount.sh $SILENCE $COMMAND tag="DATA" nfshost=$NFSHOST nfsexport=$NFSEXPORT nfsmount=$NFSMOUNT nfsport=$NFSPORT nfssize=$SIZE

