#!/bin/bash
#
# Programmer: De Dauw Valentijn
#       Date: 2019/05/06
#     Target: general rmount script
#             mounting an exported nfs volume on a mountpoint
#      Usage: rmount.sh arguments
#
# name        example                   syntax      description                            default 
# TAG         tag=thetag                tag=        TAG for logger                         MOUNT     optional
# SILENCE     silence                               when set the script will not echo                optional !!! only $1
# NFSHOST     nfshost=ch3snas           nfshost=    the NFS host
# NFSEXPORT   nfsexport=/mnt/HD_a2/data nfsexport=  the export to mount
# NFSMOUNRT   nfsmount=/data            nfsmount=   the mountpoint to mount onto
# NFSPORT     nfsport=2048              nfsport=    the port the nfs server uses           2049      optional
# NFSSIZE     nfssize=1.8T              nfssize=    the expected size when mounted                   not checked when empty
#
# example:
#    rmount.sh silence mount tag="CH3SNAS" nfshost="ch3snas" nfsexport="/mnt/HD_a2/data" nfsmount="/data" nfsport=2048 nfssize="1.8T"
#
# !! the script must be run as 'root', use sudo or su
#
# history
# 0.0.2 looki?? and has?? methods
# 0.0.3 added program and argument arrays
# 0.0.4 added syntax array
# 0.0.5 added verbosity
# 0.0.6 added showArgument
# 0.0.7 removed verbosity, because it did not work
# 0.0.8 now working with associative arrays for syntax and todo
# 0.0.9 making sure echoIt has no error
# 0.1.1 using associative arrays to store command line parameter values
# 0.1.2 added setValues
# 0.1.3 removed setValues, added commands array
# 0.1.4 added usage
# 0.1.5 added checks individual message
# 0.1.6 define arrays and parameter values close to each other, improves readability
# 0.1.7 in check?, use associative arrays for ?_title, ?_message, ?_error
# 0.1.8 implementing isexecutable.sh
# 0.1.9 corrected, after noexecutable.sh, no RETVAL check (added NO_PROGAM return value)
# 0.2.2 no assiciative arrays, predefined order in checks, added command 'checks'

SCRIPT="rmount.sh"
VERSION="0.2.2"
DATE="2019/06/06"
MES=" "

# return value, default value 0
RETVAL=0
NO_ISEXECUATBLE=-1
NO_PROGRAM=-2
DO_EXIT="true"

# define arrays
OPTIONS=
COMMANDS=("mount" "unmount" "show" "checks" "free" "exports" "usage")

declare -a NAMES
declare -a SYNTAXS
declare -a VALUES
declare -a CHECK1
declare -a CHECK2
declare -a CHECK3
declare -a CHECK4

# the check series identifiers
CHECK1[0]=1
NAMES[1]="Identifier"
CHECK2[0]=2
NAMES[2]="Identifier"
CHECK3[0]=3
NAMES[3]="Identifier"
CHECK4[0]=4
NAMES[4]="Identifier"

# tag for this run
# ID 1,2,3,4 are not used as check, but as 'check serie' identifier, see above
TAG_ID=5
   NAMES[$TAG_ID]="TAG"
  VALUES[$TAG_ID]="false"
 SYNTAXS[$TAG_ID]="tag="

# the command for this script
# origin command line first of second parameter, 'command=' not used !!
COMMAND_ID=10
   NAMES[$COMMAND_ID]="COMMAND"
  VALUES[$COMMAND_ID]="true"
 SYNTAXS[$COMMAND_ID]="command="

# local domain definition
DOMAIN=20
   NAMES[$DOMAIN]="DOMAIN"
  VALUES[$DOMAIN]="not-used"
 SYNTAXS[$DOMAIN]="domain="

# read from the comand line
# origin command line
HOST=30
   NAMES[$HOST]="NFSHOST"
  VALUES[$HOST]="false"
 SYNTAXS[$HOST]="nfshost="
# check if there is a device with serial
HOST_ONLINE=31
 NAMES[$HOST_ONLINE]="HOST_ONLINE"
VALUES[$HOST_ONLINE]="false"
CHECK1[$HOST_ONLINE]=$HOST_ONLINE
# check if host is in local domain
HOST_IN_DOMAIN=32
 NAMES[$HOST_IN_DOMAIN]="HOST_IN_DOMAIN"
VALUES[$HOST_IN_DOMAIN]="false"
#CHECK1[$HOST_IN_DOMAIN]=$HOST_IN_DOMAIN ?? not yet implemented

# export definition
# origin command line
EXPORT=40
  NAMES[$EXPORT]="NFSEXPORT"
 VALUES[$EXPORT]="false"
SYNTAXS[$EXPORT]="nfsexport="
# checks if this value is a remote export
IS_EXPORT=41
 NAMES[$IS_EXPORT]="IS_EXPORT"
VALUES[$IS_EXPORT]="false"
CHECK1[$IS_EXPORT]=$IS_EXPORT
# checks if this value is an exported directory
IS_EXPORTED=42
 NAMES[$IS_EXPORTED]="IS_EXPORTED"
VALUES[$IS_EXPORTED]="false"
#CHECK1[$IS_EXPORTED]=$IS_EXPORTED !! not implemented this time

# nfsport, the tcp port on which the nfs service is available
# origin command line
PORT=50
  NAMES[$PORT]="NFSPORT"
 VALUES[$PORT]="2049"
SYNTAXS[$PORT]="nfsport="
# checks if the remote host has a port
HAS_PORT=51
 NAMES[$HAS_PORT]="HAS_PORT"
VALUES[$HAS_PORT]="false"
CHECK1[$HAS_PORT]=$HAS_PORT

# nfsservice
# origin, check
SERVICE=60
 NAMES[$SERVICE]="SERVICE"
VALUES[$SERIVCE]="false"
# checks if local host has service
HAS_SERVICE=61
 NAMES[$HAS_SERVICE]="HAS_SERVICE"
VALUES[$HAS_SERVICE]="false"
#CHECK1[$HAS_SERVICE]=$HAS_SERVICE !! not implemented this time

# directory logic
# 1 check if given value represents a single name (and not a collection)
# 2 create directory
# 3 check if directory exist
# --> mountpoint exist

# local mountpoint
# used to mount the device onto
# origin: given on command line

# read from command line
MOUNT=70
   NAMES[$MOUNT]="MOUNT"
  VALUES[$MOUNT]="false"
 SYNTAXS[$MOUNT]="mount="
# check mount designates a directory
IS_DIRECTORY=71
 NAMES[$IS_DIRECTORY]="IS_DIRECTORY"
VALUES[$IS_DIRECTORY]="false"
CHECK1[$IS_DIRECTORY]=$IS_DIRECTORY

# create directory
DIRECTORY_CREATE=72
 NAMES[$DIRECTORY_CREATE]="DIRECTORY_CREATE"
VALUES[$DIRECTORY_CREATE]="false"
CHECK1[$DIRECTORY_CREATE]=$DIRECTORY_CREATE

# check if directory exist
DIRECTORY_EXIST=73
 NAMES[$DIRECTORY_EXIST]="DIRECTORY_EXIST"
VALUES[$DIRECTORY_EXIST]="false"
CHECK1[$DIRECTORY_EXIST]=$DIRECTORY_EXIST

# checks if this mount is already mounted
# will not mount again if it is already mounted
# origin: must be checked
ALREADY_MOUNTED=80
 NAMES[$ALREADY_MOUNTED]="ALREADY_MOUNTED"
VALUES[$ALREADY_MOUNTED]="false"
CHECK1[$ALREADY_MOUNTED]=$ALREADY_MOUNTED

# check if this mount is mounted
# used for actions upon a mounted volume
# origin: must be checked
IS_MOUNTED=90
 NAMES[$IS_MOUNTED]="IS_MOUNTED"
VALUES[$IS_MOUNTED]="false"
CHECK3[$IS_MOUNTED]=$IS_MOUNTED

# nfssize, the expected volume size, once it is mounted
# origin command line
SIZE=100
   NAMES[$SIZE]="SIZE"
  VALUES[$SIZE]="false"
 SYNTAXS[$SIZE]="nfssize="
# check mount designates a directory
IS_SIZE=101
 NAMES[$IS_SIZE]="IS_SIZE"
VALUES[$IS_SIZE]="false"
CHECK2[$IS_SIZE]=$IS_SIZE

# must be root to be able to act
# origin: must be checked
ROOT=110
 NAMES[$ROOT]="ROOT"
VALUES[$ROOT]="false"
CHECK1[$ROOT]=$ROOT

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
   if [ $DO_EXIT = "true" ]; then
           exit $RETVAL
   fi
}

getNameValueFromId() {
        RETVAL=$ID
        NAME=${NAMES[$ID]}
        VALUE=${VALUES[$ID]}
}

readCommandLineParameter() {
        MES="      parameter $COUNT $PARAMETER"
        echoIt
        # read single word parameter
        for NAME in "${COMMANDS[@]}"
        do
                if [ $NAME = $PARAMETER ]; then
                        COMMAND=$PARAMETER
                fi
        done
        # read key=value parameter
        for ID in "${!SYNTAXS[@]}"
        do
                getNameValueFromId
                # if the value is not yet set
                if [ $VALUE = "false" ]; then
                        SYNTAX=${SYNTAXS[$ID]}
                        # if this parameter is the syntax
                        echo $PARAMETER | grep $SYNTAX > /dev/null
                        if [ $? -eq 0 ]; then
                                # then set the value
                                VALUES[$ID]=$(echo $PARAMETER | gawk -F '=' '{print $2}')
                                return
                        fi
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

hasCommandLineParameters() {
        # check if the command line parameters have values
        MES="hasCommandLineParameters: each checked command line parameter must have a value"
        echoIt
        # enumerate the command line parameter names
        for ID in "${!SYNTAXS[@]}"
        do
                getNameValueFromId
                # if the command line set return value is not zero, check it
                if [ $VALUE = "false" ]; then
                        MES="command line parameter '$NAME' has no value"
                        loggerExit
                fi
		MES="   ($ID) ($NAME) has value ${VALUES[$ID]}"
		echoIt
        done
        MES=""
        echoIt
}


checkParameters() {
        case $ID in
                $HOST_ONLINE) # checks if the host is online
			if [ $VALUE = "false" ]; then
				MES="      ${VALUES[$HOST]} online ?"
				echoIt
                	        ping -c 1 ${VALUES[$HOST]} > /dev/null
                        	if [ ! $? -eq 0 ]; then
                                	MES="${VALUES[$HOST]} is not online"
	                                loggerExit
        	                fi
				VALUES[$HOST_ONLINE]="true"
				MES="      ${VALUES[$HOST]} is online"
				echoIt
			fi
                ;;
		$IS_EXPORT) # checks if the export is exported
			if [ $VALUE = "false" ]; then
				MES="      ${VALUES[$HOST]}:${VALUES[$EXPORT]} is exported ?"
				echoIt
				showmount -e ${VALUES[$HOST]} | grep ${VALUES[$EXPORT]} > /dev/null
				if [ ! $? -eq 0 ]; then
					MES="${VALUES[$HOST]}:${VALUES[$EXPORT]} is not exported"
					loggerExit
				fi
				VALUES[$IS_EXPORT]="true"
				MES="      ${VALUES[$HOST]}:${VALUES[$EXPORT]} is exported"
                                echoIt
			fi
 		;;

                $IS_DIRECTORY)
                        if [ $VALUE = "false" ]; then
                                # check if this value designates a directory
                                MES="      ${VALUES[$MOUNT]} designates a directory ?"
                                echoIt
                                        WC=$(echo ${VALUES[$MOUNT]} | wc -w)
                                if [ ! $WC -eq 1 ]; then
                                        MES="${VALUES[$MOUNT]} does not designate a directory"
                                        loggerExit
                                fi
                                VALUES[$IS_DIRECTORY]="true"
				MES="      ${VALUES[$MOUNT]} designates a directory !"
				echoIt
                        fi
                ;;

                $DIRECTORY_EXIST)
                        if [ $VALUE = "false" ]; then
                                # check if directory exists,
                                MES="       directory ${VALUES[$MOUNT]} exist ?"
                                echoIt
                                if [ ! -d ${VALUES[$MOUNT]} ]; then
                                        MES="${VALUES[$MOUNT]} does not exist"
                                        loggerExit
                                fi
                                VALUES[$DIRECTORY_EXIST]="true"
                                MES="      ${VALUES[$MOUNT]} directory exist !"
                                echoIt
                        fi
                ;;

               $DIRECTORY_CREATE)
                        if [ $VALUE = "false" ]; then
                                # create directory
                                MES="      create directory ${VALUES[$MOUNT]}"
                                echoIt
                                if [ ! -d ${VALUES[$MOUNT]} ]; then
                                        mkdir ${VALUES[$MOUNT]} > /dev/null 2> /dev/null
                                        if [ ! -d ${VALUES[$MOUNT]} ]; then
                                                MES="could not create directory ${VALUES[$MOUNT]}"
                                                loggerExit
                                        fi
                                        VALUES[$DIRECTORY_CREATE]="true"
                                        MES="         ${VALUES[$MOUNT]} directory created"
                                        echoIt
                                fi
                        fi
                ;;

                $ALREADY_MOUNTED)
                        if [ $VALUE = "false" ]; then
                                MES="      ${VALUES[$MOUNT]} already mounted ?"
                                echoIt
                                df -h | grep ${VALUES[$MOUNT]} > /dev/null
                                if [ $? -eq 0 ]; then
                                        MES="${VALUES[$MOUNT]} already mounted"
                                        loggerExit
                                fi
                                VALUES[$ALREADY_MOUNTED]="true"
                                MES="         ${VALUES[$MOUNT]} not mounted"
                                echoIt
                        fi
                ;;

                $IS_MOUNTED)
                        if [ $VALUE = "false" ]; then
                                MES="      ${VALUES[$MOUNT]} mounted ?"
                                echoIt
                                df -h | grep ${VALUES[$MOUNT]} > /dev/null
                                if [ ! $? -eq 0 ]; then
                                        MES="${VALUES[$MOUNT]} is not mounted"
                                        loggerExit
                                fi
                                VALUES[$IS_MOUNTED]="true"
                                MES="         ${VALUES[$MOUNT]} is mounted"
                                echoIt
                        fi
                ;;

		$HAS_PORT)
			if [ $VALUE = "false" ]; then
				MES="      ${VALUES[$HOST]}:${VALUES[$PORT]} is available ?"
				echoIt
				nmap ${VALUES[$HOST]} | grep ${VALUES[$PORT]} > /dev/null
	                        if [ ! $? -eq 0 ]; then
        	                        MES="${VALUES[$HOST]}:${VALUES[$PORT]} is not available"
                	                loggerExit
	                        fi
				VALUES[$HAS_PORT]="true"
				MES="      ${VALUES[$HOST]}:${VALUES[$PORT]} is available"
				echoIt
			fi
		;;

                $IS_SIZE)
                        if [ $VALUE = "false" ]; then
                                MES="      ${VALUES[$MOUNT]} has ${VALUES[$SIZE]}"
                                echoIt
                                LINE=$(df -h | grep ${VALUES[$MOUNT]})
                                WC=$(echo $LINE | wc -w)
                                if [ $WC -eq 6 ]; then
                                        ISSIZE=$(echo $LINE | gawk '{print $2}')
                                        # size and nfsSize are treated as strings because ',' and 'T'
                                        if [ ! $ISSIZE = ${VALUES[$SIZE]} ]; then
                                                MES="warning: actual size $ISSIZE is not estimated size ${VALUES[$SIZE]}"
                                                logit
                                        fi
                                        VALUES[$IS_SIZE]=$ISSIZE
                                else
                                        MES="         ${VALUES[$MOUNT]} not mounted"
                                        echoIt
                                fi
                        fi
                ;;

                $ROOT)
                        if [ $VALUE = "false" ]; then
                                MES="      are we the root user ?"
                                echoIt
                                whoami | grep 'root' > /dev/null
                                if [ ! $? -eq 0 ]; then
                                        MES="this script needs to be the root user, use 'su' or 'sudo'"
                                        loggerExit
                                fi
                                VALUES[$ROOT]="true"
                                MES="         we are the root user !"
                                echoIt
                        fi
                ;;

        esac
}

# check the parameters before the script action
checks() {
        if [ ! ${#CHECKS[@]} -eq 0 ]; then
                MES="--> check ${CHECKS[0]}"
                echoIt
                for ID in "${CHECKS[@]}"
                do
                        getNameValueFromId
                        MES="   check ($ID) ($NAME)"
                        echoIt
                        checkParameters
                done
                MES=""
                echoIt
        fi
}

usage() {
        echo "rmount.sh, mount given host:export upon given mountpoint"
        echo "commands are:"
        echo "  -->   mount, mount the export onto the mountpoint (default)"
        echo "  --> unmount, unmount the mountpoint"
        echo "  -->    free, show used and free space on given mountpoint"
        echo "  -->    show, do nothing, show given parameter values"
        echo "  --> silence, do not echo each action"
        echo "  -->   usage, show this message"
        echo ""
        echo "parameters are:"
        echo "  -->       tag=, the TAG to use for the 'logger' command, see /var/log/syslog"
        echo "  -->   nfshost=, the host providing the NFS service"
        echo "  --> nfsexport=, the exported directory"
        echo "  -->  nfsmount=, the mountpoint to mount the export upon"
        echo "  -->   nfsport=, optional, the port the NFS service is provided"
        echo "  -->   nfssize=, optional, the expected size once the exported volume is mounted"
        echo
        echo "the script needs to run as 'root', be 'root' or use 'sudo'"
        echo
        echo "example:"
        echo "sudo rmount.sh silence mount tag='DATA' nfshost=ch3snas nfsexport=/mnt/HD_a2/data nfsmount=/data nfsport=2049 nfssize=1,8T"
}

# show all values
showValues() {
        echo "showValues"
        if [ $SILENCE = 'silence' ] || [ $SILENCE = 'SILENCE' ]; then
                echo "      silenced"
        fi
        echo "" | gawk '{printf("\t\t%3s %20s %50s %10s\n","ID","NAME","VALUE","SYNTAX");}'
        for ID in "${!NAMES[@]}"
        do
                getNameValueFromId
                SYNTAX=${SYNTAXS[$ID]}
                if [ ! -z $SYNTAX ]; then
                        TMP="$ID:$NAME:$VALUE:$SYNTAX"
                        echo "$TMP" | gawk -F ':' '{printf("\t\t%3d %20s %50s %10s\n",$1,$2,$3,$4);}'

                else
                        TMP="$ID:$NAME:$VALUE"
                        echo "$TMP" | gawk -F ':' '{printf("\t\t%3d %20s %50s\n",$1,$2,$3);}'

                fi
        done
        MES=""
        echoIt
}

showChecks() {
        if [ ! ${#CHECKS[@]} -eq 0 ]; then
                echo "--> checks ${CHECKS[0]}"
                for ID in "${CHECKS[@]}"
                do
                        echo "$ID ${NAMES[$ID]}" | gawk '{printf("\t%d %s\n",$1,$2);}'
                done
        fi
}

# be silent, will only use logger (and problably some difficult to avoid empty lines)
SILENCE=$1
if [ -z $SILENCE ]; then SILENCE="---"; fi
if [ $SILENCE = "silence" ]; then shift; fi
if [ $SILENCE = "SILENCE" ]; then shift; fi
PARAMS=("$@")

TAG="RMOUNT"
MES="$SCRIPT version $VERSION from $DATE"
logit

if [ ! -x /usr/bin/isexecutable.sh ]; then
	RETVAL=$NO_ISEXECUTABLE
	MES="isexecutable not installed"
	loggerExit
fi

isexecutable.sh silence $TAG "nmap" "ping" "mount" "showmount" "umount" "df" "whoami" "mkdir"
if [ ! $? -eq 0 ]; then
	RETVAL=$NO_PROGRAM
	MES="one or more programs not installed"
	loggerExit
fi
readCommandLineParameters
if [ ! -z $COMMAND ]; then VALUES[$COMMAND_ID]=$COMMAND; fi

# set default values if needed
if [ -z ${VALUES[$PORT]} ];  then VALUES[$PORT]=2049; fi
if [ -z ${VALUES[$TAG_ID]} ]; then VALUES[$TAG_ID]="LMOUNT"; fi
# if a tag was given then use it
TAG=${VALUES[$TAG_ID]}
# problably add SERVICE at a later time

case $COMMAND in
    mount)
	hasCommandLineParameters
	CHECKS=(${CHECK1[@]})
        checks
	mount ${VALUES[$HOST]}:${VALUES[$EXPORT]} ${VALUES[$MOUNT]}
	if [ ! $? -eq 0 ]; then
	        MES="Some error while mounting ${VALUES[$HOST]}:${VALUES[$EXPORT]} onto ${VALUES[$MOUNT]}"
        	loggerExit
	fi
	CHECKS=(${CHECK2[@]})
        checks
	MES="${VALUES[$MOUNT]} mounted"
	echoIt
    ;;
    unmount)
	hasCommandLineParameters
	CHECKS=(${CHECK3[@]})
        checks
	umount ${VALUES[$MOUNT]}
        if [ ! $? -eq 0 ]; then
                MES="Some error while unmounting ${VALUES[$MOUNT]}"
                loggerExit
        fi
        MES="${VALUES[$MOUNT]} unmounted"
        echoIt
    ;;
    show)
        DO_EXIT="false"
        CHECKS=(${CHECK1[@]})
        checks
        CHECKS=(${CHECK2[@]})
        checks
        CHECKS=(${CHECK3[@]})
        checks
        CHECKS=(${CHECK4[@]})
        checks
        showValues
    ;;
    checks)
        DO_EXIT="false"
        CHECKS=(${CHECK1[@]})
        showChecks
        CHECKS=(${CHECK2[@]})
        showChecks
        CHECKS=(${CHECK3[@]})
        showChecks
        CHECKS=(${CHECK4[@]})
        showChecks
    ;;
    free)
	hasCommandLineParameters
        CHECKS=(${CHECK3[@]})
        checks
	df -h | grep ${VALUES[$MOUNT]}
    ;;
    exports)
	hasCommandLineParameters
	showmount -e ${VALUES[$HOST]}
    ;;
    usage)
	usage
    ;;
    *)  echo "$SCRIPT version $VERSION missing command and parameters"
	usage
    ;;
esac

