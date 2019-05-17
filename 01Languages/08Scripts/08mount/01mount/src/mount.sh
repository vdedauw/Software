#!/bin/bash
#
# Programmer: De Dauw Valentijn
#       Date: 2019/05/06
#     Target: general mount script
#             mounting an nfs volume on a mountpoint
#      Usage: mount.sh arguments
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
#     mount.sh silence mount tag="CH3SNAS" nfshost="ch3snas" nfsexport="/mnt/HD_a2/data" nfsmount="/data" nfsport=2048 nfssize="1.8T"
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

SCRIPT="mount.sh"
VERSION="0.1.3"
DATE="2019/05/15"
MES=" "

# return value
# when 0 the parameter is not checked if set
RETVAL=0
# command line parameter not set return values
NO_TAG=1
NO_COMMAND=2
NO_HOST=3
NO_EXPORT=4
NO_DIRECTORY=5
NO_MOUNT=6
NO_PORT=7
NO_SIZE=8
NO_ROOT=9

# return values indicating incorrect command line values are the same as the check numbers
# as a documentation feature they are repeated as an error name
TNAME="tag"
IS_TAG=1                 # dummy value, no check for 'tag'

DOMAIN="domain"
IS_DNS_DOMAIN=2          # checks if domain is a local dns domain

HOST="nfshost"
HOST_ONLINE=10           # checks if the host is online
NOT_ONLINE=10
HOST_IN_DNS=11           # checks if the host in in the (local) dns database
UNKNOWN_HOST=11

EXPORT="nfsexport"
IS_EXPORT=20             # checks if this value is an remote export
NOT_EXPORTED=20
IS_EXPORTED=21           # checks if this value is an exported directory
NOT_EXPORTED=21

# this is also 'nfsmount', mount is a directory
IS_DIRECTORY=30          # checks if this value is an existing directory
DIR_NOT_EXIST=30
NEW_DIRECTORY=31         # creates this directory
DIR_CANNOT_CREATE=31

MOUNT="nfsmount"
IS_MOUNTED=40            # checks if this value is mounted
ALREADY_MOUNTED=40
IS_EXPORTED=41           # checks if this value is exported
NOT_EXPORTED=41

PORT="nfsport"
HAS_PORT=50              # checks if the remote host has a port
NO_REMOTE_PORT=50

IS_SERVICE=51            # checks if the local host has a service
NO_SERVICE=51

SIZE="nfssize"
IS_SIZE=60               # checks if the volume has the expected size
INCORRECT_SIZE=60

ROOT="root"
IS_ROOT=70               # checks if the current user is root

# define local vars
TAG="MOUNT"

# define arrays
PROGRAMS=("gawk" "grep" "nmap" "ping" "mount" "showmount" "umount" "df" "whoami")
PARAMS=("$@")
OPTIONS=
COMMANDS=("silence" "mount" "unmount" "show" "free" "exports" "usage")

declare -A SYNTAXS
SYNTAXS=([$TNAME]="tag=" [$HOST]="nfshost=" [$EXPORT]="nfsexport=" [$MOUNT]="nfsmount=" [$PORT]="nfsport=" [$SIZE]="nfssize=")
declare -A VALUES
declare -A RETVALS
RETVALS=([$TNAME]=$NO_TAG [$HOST]=$NO_HOST [$EXPORT]=$NO_EXPORT [$MOUNT]=$NO_DIRECTORY [$PORT]=$NO_PORT [$SIZE]=$NO_SIZE)
declare -A HASPARAM
HASPARAM=([$TNAME]="N" [$HOST]="Y" [$EXPORT]="Y" [$MOUNT]="Y" [$PORT]="Y" [$SIZE]="N")

# before cycle
declare -A BEFORE_RETVALS
BEFORE_RETVALS=([$HOST]=$NOT_ONLINE [$EXPORT]=$NOT_EXPORTED [$MOUNT]=$CANNOT_CREATE [$PORT]=$NO_REMOTE_PORT [$SIZE]=$INCORRECT_SIZE [$ROOT]=$NO_ROOT)
declare -A BEFORE_CHECKS
BEFORE_CHECKS=([$HOST]=$HOST_ONLINE [$EXPORT]=$IS_EXPORT [$MOUNT]=$IS_DIRECTORY [$PORT]=$HAS_PORT [$SIZE]=$CHECK_SIZE [$ROOT]=$IS_ROOT)
# middle cycle
declare -A MIDDLE_RETVALS
MIDDLE_RETVALS=([$MOUNT]=$ALREADY_MOUNTED )
declare -A MIDDLE_CHECKS
MIDDLE_CHECKS=([$MOUNT]=$IS_MOUNTED)
# final cycle
declare -A AFTER_RETVALS
AFTER_RETVALS=([$SIZE]=$INCORRECT_SIZE)
declare -A AFTER_CHECKS
AFTER_CHECKS=([$SIZE]=$IS_SIZE)
declare -A MOUNT_RETVALS
MOUNT_RETVALS=([$MOUNT]=$NOT_DIRECTORY [$ROOT]=$NO_ROOT)
declare -A MOUNT_CHECKS
MOUNT_CHECKS=([$MOUNT]=$IS_DIRECTORY [$ROOT]=$IS_ROOT)

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

# check if a program is installed
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
        for NAME in "${COMMANDS[@]}"
        do
		if [ $NAME = $PARAMETER ]; then
			COMMAND=$PARAMETER
		fi
        done
	# read key=value parameter
        for NAME in "${!SYNTAXS[@]}"
        do
	        # if the value is not yet set
                if [ -z ${VALUES[$NAME]} ]; then
         		SYNTAX=${SYNTAXS[$NAME]}
               		# if this parameter is the syntax
                	echo $PARAMETER | grep $SYNTAX > /dev/null
                	if [ $? -eq 0 ]; then
                		# then set the value
                        	VALUES[$NAME]=$(echo $PARAMETER | gawk -F = '{print $2}')
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
        for NAME in "${!SYNTAXS[@]}"
        do
                RETVAL=${RETVALS[$NAME]}
                PARAM=${HASPARAM[$NAME]}
		SYNTAX=${SYNTAXS[$NAME]}
                VALUE=${VALUES[$NAME]}
                # if the command line set return value is not zero, check it
                if [ $PARAM = "Y" ]; then
                        MES="      has parameter $NAME value='$VALUE'"
                        echoIt
                        if [ -z $VALUE ]; then
                                MES="command line parameter '$SYNTAX' has no value"
                                loggerExit
                        fi
                fi
        done
        MES=""
        echoIt
}

checkCommandLineParameter() {
        if [ -z $CHECK ]; then return; fi
        # if HASCHECK indicates it, check it
        MES="      checking $NAME value=$VALUE"
        echoIt
        case $CHECK in
                $HOST_ONLINE) # checks if the host is online
                        ping -c 1 ${VALUES[$HOST]} > /dev/null
                        if [ ! $? -eq 0 ]; then
                                MES="host ${VALUES[$HOST]} not online"
                                loggerExit
                        fi
                ;;
		$IS_EXPORT)
			showmount -e ${VALUES[$HOST]} | grep ${VALUES[$EXPORT]} > /dev/null
			if [ ! $? -eq 0 ]; then
				MES="host $NFSHOST has not an export named $NFSEXPORT"
				loggerExit
			fi
 		;;
                $IS_DIRECTORY)
                        # check if directory exists, if not --> could not create it
                        if [ ! -d ${VALUES[$MOUNT]} ]; then
				mkdir ${VALUES[$MOUNT]}
                        fi
                        if [ ! -d ${VALUES[$MOUNT]} ]; then
                                MES="directory ${VALUES[$MOUNT]} cannot be created"
				loggerExit
                        fi
                ;;
		$HAS_PORT)
			nmap ${VALUES[$HOST]} | grep ${VALUES[$PORT]} > /dev/null
                        if [ ! $? -eq 0 ]; then
                                MES="host ${VALUES[$HOST]} has not port ${VALUES[$PORT]}"
                                loggerExit
                        fi
		;;
		$IS_SIZE)
			LINE=$(df -h | grep ${VALUES[$MOUNT]})
			ISSIZE=$(echo $LINE | gawk '{print $2}')
			# size and nfsSize are treated as strings because ',' and 'T'
		        if [ ! $ISSIZE = ${VALUES[$SIZE]} ]; then
                		MES1="Warning size $ISSIZE is not equal to nfsSize ${VALUES[$SIZE]}"
		                logit
		        fi
		;;
		$IS_ROOT)
			whoami | grep 'root' > /dev/null
			if [ ! $? -eq 0 ]; then
				MES="$SCRIPT user needs to be 'root'"
				loggerExit
			fi
		;;
		$IS_MOUNTED)
			df -h | grep ${VALUES[$MOUNT]} > /dev/null
			if [ $? -eq 0 ]; then
				MES="${VALUES[$MOUNT]} already mounted, use 'mount.sh unmount' first"
				loggerExit
			fi
		;;
        esac
}

# run before 'mount' program line value checks
beforeChecks() {
        MES="beforeChecks"
        echoIt
        for NAME in "${!BEFORE_CHECKS[@]}"
        do
        	RETVAL=${BEFORE_RETVALS[$NAME]}
		CHECK=${BEFORE_CHECKS[$NAME]}
		VALUE=${VALUES[$NAME]}
                checkCommandLineParameter
        done
        MES=""
        echoIt
}

# run before 'mount' program line status checks
middleChecks() {
        MES="middleChecks"
        echoIt
        for NAME in "${!MIDDLE_CHECKS[@]}"
        do
                RETVAL=${MIDDLE_RETVALS[$NAME]}
                CHECK=${MIDDLE_CHECKS[$NAME]}
                VALUE=${VALUES[$NAME]}
                checkCommandLineParameter
        done
        MES=""
        echoIt
}

# run after command line value checks
afterChecks() {
        MES="afterChecks"
        echoIt
        for NAME in "${!AFTER_CHECKS[@]}"
        do
                RETVAL=${AFTER_RETVALS[$NAME]}
                CHECK=${AFTER_CHECKS[$NAME]}
                VALUE=${VALUES[$NAME]}
                checkCommandLineParameter
        done
        MES=""
        echoIt
}

# checks before executing the 'umount' program
checkMount() {
        MES="mountChecks"
        echoIt
        for NAME in "${!MOUNT_CHECKS[@]}"
        do
                RETVAL=${MOUNT_RETVALS[$NAME]}
                CHECK=${MOUNT_CHECKS[$NAME]}
                VALUE=${VALUES[$NAME]}
                checkCommandLineParameter
        done
        MES=""
        echoIt
}

# show all values
showValues() {
        MES="showValues"
        echoIt
	if [ $SILENCE = 'silence' ] || [ $SILENCE = 'SILENCE' ]; then
		echo "      silenced"
	fi
        if [ ! -z $COMMAND ]; then echo "      command $COMMAND"; fi
        for NAME in "${!SYNTAXS[@]}"
        do
                echo "      $NAME ${VALUES[$NAME]}"
        done
        MES=""
        echoIt
}

# be silent, will only use logger (and problably some difficult to avoid empty lines)
SILENCE=$1

MES="$SCRIPT version $VERSION from $DATE"
logit

lookiPrograms
readCommandLineParameters

# set default values if needed
if [ -z ${VALUES[$TNAME]} ]; then VALUES[$TNAME]="MOUNT"; fi
if [ -z $COMMAND ];          then COMMAND='mount'; fi
if [ -z ${VALUES[$PORT]} ];  then VALUES[$PORT]=2049; fi

hasCommandLineParameters

case $COMMAND in
    mount)
	beforeChecks
	middleChecks
	mount ${VALUES[$HOST]}:${VALUES[$EXPORT]} ${VALUES[$MOUNT]}
	if [ ! $? -eq 0 ]; then
	        MES="Some error while mounting ${VALUES[$HOST]}:${VALUES[$EXPORT]} onto ${VALUES[$MOUNT]}"
        	loggerExit
	fi
	afterChecks
	MES="${VALUES[$MOUNT]} mounted"
	echoIt
    ;;
    unmount)
	checkMount
	umount ${VALUES[$MOUNT]}
        if [ ! $? -eq 0 ]; then
                MES="Some error while unmounting ${VALUES[$MOUNT]}"
                loggerExit
        fi
        MES="${VALUES[$MOUNT]} unmounted"
        echoIt
    ;;
    show)
	showValues
    ;;
    free)
	checkMount
	df -h | grep ${VALUES[$MOUNT]}
    ;;
    exports)
	showmount -e ${VALUES[$HOST]}
    ;;
    usage)
	echo "mount.sh, mount given host:export upon given mountpoint"
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
	echo "sudo mount.sh silence mount tag='DATA' nfshost=ch3snas nfsexport=/mnt/HD_a2/data nfsmount=/data nfsport=2049 nfssize=1,8T"
    ;;
    *)  echo "$SCRIPT version $VERSION missing command and parameters"
	echo "   use 'mount.sh usage' to learn more"
    ;;
esac

