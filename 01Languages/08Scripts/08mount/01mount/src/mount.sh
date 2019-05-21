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
# 0.1.5 added checks individual message
# 0.1.6 define arrays and parameter values close to each other, improves readability
# 0.1.7 for checks: use regular array, rather then associative arrays

SCRIPT="mount.sh"
VERSION="0.1.7"
DATE="2019/05/15"
MES=" "

# return value, default value 0
RETVAL=0

declare -A SYNTAXS
declare -A VALUES
declare -A RETVALS
declare -A HASPARAM
declare -A CHECK1
declare -A ERROR1
declare -A CHECK2
declare -A ERROR2
declare -A CHECK3
declare -A ERROR3
declare -A CHECK4
declare -A ERROR4
declare -A CHECK5
declare -A ERROR5

# return values indicating incorrect command line values are the same as the check numbers
# as a documentation feature they are repeated as an error name
TNAME="tag"
IS_TAG=1                 # dummy value, no check for 'tag'
NO_TAG=1
 SYNTAXS+=([$TNAME]="tag=")
 RETVALS+=([$TNAME]=$NO_TAG)
HASPARAM+=([$TNAME]="N")

# the command for this script
CNAME="command"
NO_COMMAND=10

# local domain definitions
DOMAIN="domain"
NO_DOMAIN=10
LOCAL_DNS_DOMAIN=11    # checks if domain is a local dns domain
NO_LOCAL_DOMAIN=11
 SYNTAXS+=([$DOMAIN]="domain=")
 RETVALS+=([$DOMAIN]=$NO_DOMAIN)
HASPARAM+=([$DOMAIN]="N")

# host definitions
HOST="nfshost"
NO_HOST=20
# checks if the host is online
HOST_ONLINE_TITLE="is host online ?"
HOST_ONLINE_MESSAGE="host not online !"
HOST_ONLINE_ERROR=21
# checks if the host in in the (local) dns database
HOST_DOMAIN="host in local domain ?"
HOST_DOMAIN_MESSAGE="host not in local domain !"
HOST_DOMAIN_ERROR=22

 SYNTAXS+=([$HOST]="nfshost=")
 RETVALS+=([$HOST]=$NO_HOST)
HASPARAM+=([$HOST]="Y")
  CHECK1+=([$HOST_ONLINE_TITLE]=$HOST_ONLINE_MESSAGE)
  ERROR1+=([$HOST_ONLINE_TITLE]=$HOST_ONLINE_ERROR)

# export definitions
EXPORT="nfsexport"
NO_EXPORT=30
# checks if this value is a remote export
IS_EXPORT_TITLE="is remote export ?"
IS_EXPORT_MESSAGE="is not a remote export !"
IS_EXPORT_ERROR=31
# checks if this value is an exported directory
IS_EXPORTED_TITLE="is exported ?"
IS_EXPORTED_MESSAGE="is not exported !"
IS_EXPORTED_ERROR=32

 SYNTAXS+=([$EXPORT]="nfsexport=")
 RETVALS+=([$EXPORT]=$NO_EXPORT)
HASPARAM+=([$EXPORT]="Y")
 CHECK1+=([$IS_EXPORT_TITLE]=$IS_EXPORT_MESSAGE)
 ERROR1+=([$IS_EXPORT_TITLE]=$IS_EXPORT_ERROR)

MOUNT="nfsmount"
NO_MOUNT=40
# checks if this value is a directory
IS_DIRECTORY_TITLE="is directory ?"
IS_DIRECTORY_MESSAGE="is not directory !"
IS_DIRECTORY_ERROR=41
# creates this directory
NEW_DIRECTORY_TITLE="create directory."
NEW_DIRECTORY_MESSAGE="could not create directory !"
NEW_DIRECTORY_ERROR=42
# checks if this value is already mounted
ALREADY_MOUNTED_TITLE="already mounted ?"
ALREADY_MOUNTED_MESSAGE="already mounted ! Use mount.sh unmount first."
ALREADY_MOUNTED_ERROR=43
# checks if this value is mounted
IS_MOUNTED_TITLE="is mounted ?"
IS_MOUNTED_MESSAGE="not mounted !"
IS_MOUNTED_ERROR=44

 SYNTAXS+=([$MOUNT]="nfsmount=")
 RETVALS+=([$MOUNT]=$NO_MOUNT)
HASPARAM+=([$MOUNT]="Y")
  CHECK1+=([$IS_DIRECTORY_TITLE]=$IS_DIRECTORY_MESSAGE)
  ERROR1+=([$IS_DIRECTORY_TITLE]=$IS_DIRECTORY_ERROR)
  CHECK2+=([$NEW_DIRECTORY_TITLE]=$NEW_DIRECTORY_MESSAGE)
  ERROR2+=([$NEW_DIRECTORY_TITLE]=$NEW_DIRECTORY_ERROR)
  CHECK3+=([$ALREADY_MOUNTED_TITLE]=$ALREADY_MOUNTED_MESSAGE)
  ERROR3+=([$ALREADY_MOUNTED_TITLE]=$ALREADY_MOUNTED_ERROR)
  CHECK4+=([$IS_MOUNTED_TITLE]=$IS_MOUNTED_MESSAGE)
  ERROR4+=([$IS_MOUNTED_TITLE]=$IS_MOUNTED_ERROR)

PORT="nfsport"
NO_PORT=50
# checks if the remote host has a port
HAS_PORT_TITLE="has remote port ?"
HAS_PORT_MESSAGE="host has no remote port !"
HAS_PORT_ERROR=51

 SYNTAXS+=([$PORT]="nfsport=")
 RETVALS+=([$PORT]=$NO_PORT)
HASPARAM+=([$PORT]="Y")
  CHECK1+=([$HAS_PORT_TITLE]=$HAS_PORT_MESSAGE)
  ERROR1+=([$HAS_PORT_TITLE]=$HAS_PORT_ERROR)

SERVICE="nfsservice"
NO_SERVICE=60
# checks if the local host has a service
HAS_SERVICE_TITLE="has service ?"
HAS_SERVICE_MESSAGE="has no service !"
HAS_SERVICE_ERROR=61

SIZE="nfssize"
NO_SIZE=70
# checks if the volume has the expected size
IS_SIZE_TITLE="is size ?"
IS_SIZE_MESSAGE="warning sizes not equal !"
IS_SIZE_ERROR=71

 SYNTAXS+=([$SIZE]="nfssize=")
 RETVALS+=([$SIZE]=$NO_SIZE)
HASPARAM+=([$SIZE]="N")
  CHECK5+=([$IS_SIZE_TITLE]=$IS_SIZE_MESSAGE)
  ERROR5+=([$IS_SIZE_TITLE]=$IS_SIZE_ERROR)

ROOT="root"
NO_ROOT=80
# checks if the current user is root
IS_ROOT_TITLE="user is root user ?"
IS_ROOT_MESSAGE="$SCRIPT user needs to be root !"
IS_ROOT_ERROR=81
 CHECK1+=([$IS_ROOT_TITLE]=$IS_ROOT_MESSAGE)
 ERROR1+=([$IS_ROOT_TITLE]=$IS_ROOT_ERROR)

# define local vars
TAG="MOUNT"

# define arrays
PROGRAMS=("gawk" "grep" "nmap" "ping" "mount" "showmount" "umount" "df" "whoami")
PARAMS=("$@")
OPTIONS=
COMMANDS=("silence" "mount" "unmount" "show" "free" "exports" "usage")

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
	WC=$(echo $TITLE | wc -w)
        if [ $WC -eq 0 ]; then return; fi
        # if HASCHECK indicates it, check it

        case $TITLE in
                $HOST_ONLINE_TITLE) # checks if the host is online
			MES="      ${VALUES[$HOST]} $TITLE"
			echoIt
                        ping -c 1 ${VALUES[$HOST]} > /dev/null
                        if [ ! $? -eq 0 ]; then
                                MES="${VALUES[$HOST]} $MESSAGE"
                                loggerExit
                        fi
                ;;
		$IS_EXPORT_TITLE)
			MES="      ${VALUES[$HOST]}:${VALUES[$EXPORT]} $TITLE"
			echoIt
			showmount -e ${VALUES[$HOST]} | grep ${VALUES[$EXPORT]} > /dev/null
			if [ ! $? -eq 0 ]; then
				MES="${VALUES[$HOST]}:${VALUES[$EXPORT]} $MESSAGE"
				loggerExit
			fi
 		;;
                $IS_DIRECTORY_TITLE)
                        # check if directory exists, if not --> could not create it
			MES="      ${VALUES[$MOUNT]} $TITLE"
			echoIt
                        if [ ! -d ${VALUES[$MOUNT]} ]; then
                                MES="${VALUES[$MOUNT]} $MESSAGE"
				loggerExit
                        fi
		;;
                $NEW_DIRECTORY_TITLE)
                        # check if directory exists, if not --> could not create it
                        MES="      ${VALUES[$MOUNT]} $TITLE"
                        echoIt
			mkdir ${VALUES[$MOUNT]} > /dev/null 2> /dev/null
                        if [ ! -d ${VALUES[$MOUNT]} ]; then
                                MES="${VALUES[$MOUNT]} $MESSAGE"
                                loggerExit
                        fi
                ;;
                $ALREADY_MOUNTED_TITLE)
                        MES="      ${VALUES[$MOUNT]} $TITLE"
                        echoIt
                        df -h | grep ${VALUES[$MOUNT]} > /dev/null
                        if [ $? -eq 0 ]; then
                                MES="${VALUES[$MOUNT]} $MESSAGE"
                                loggerExit
                        fi
                ;;
                $IS_MOUNTED_TITLE)
                        MES="      ${VALUES[$MOUNT]} $TITLE"
                        echoIt
                        df -h | grep ${VALUES[$MOUNT]} > /dev/null
                        if [ ! $? -eq 0 ]; then
                                MES="${VALUES[$MOUNT]} $MESSAGE"
                                loggerExit
                        fi
                ;;
		$HAS_PORT_TITLE)
			MES="      ${VALUES[$HOST]}:${VALUES[$PORT]} $TITLE"
			echoIt
			nmap ${VALUES[$HOST]} | grep ${VALUES[$PORT]} > /dev/null
                        if [ ! $? -eq 0 ]; then
                                MES="${VALUES[$HOST]}:${VALUES[$PORT]} $MESSAGE"
                                loggerExit
                        fi
		;;
		$IS_SIZE_TITLE)
			MES="      ${VALUES[$SIZE]} $TITLE"
			echoIt
			LINE=$(df -h | grep ${VALUES[$MOUNT]})
			ISSIZE=$(echo $LINE | gawk '{print $2}')
			# size and nfsSize are treated as strings because ',' and 'T'
		        if [ ! $ISSIZE = ${VALUES[$SIZE]} ]; then
                		MES1="$ISSIZE ${VALUES[$SIZE]} $MESSAGE"
		                logit
		        fi
		;;
		$IS_ROOT)
			MES="      $TITLE"
			echoIt
			whoami | grep 'root' > /dev/null
			if [ ! $? -eq 0 ]; then
				MES="$MESSAGE"
				loggerExit
			fi
		;;
        esac
}

# run before 'mount' program line value checks
checks1() {
        MES="checks1"
        echoIt
        for TITLE in "${!CHECK1[@]}"
        do
		MESSAGE=${CHECK1[$TITLE]}
        	RETVAL=${ERROR1[$TITLE]}
                checkCommandLineParameter
        done
        MES=""
        echoIt
}

# run before 'mount' program line status checks
checks2() {
        MES="checks2"
        echoIt
        for TITLE in "${!CHECK2[@]}"
        do
		MESSAGE=${CHECK2[$TITLE]}
                RETVAL=${ERROR2[$TITLE]}
                checkCommandLineParameter
        done
        MES=""
        echoIt
}

# run before 'mount' program line status checks
checks3() {
        MES="checks3"
        echoIt
        for TITLE in "${!CHECK3[@]}"
        do
		MESSAGE=${CHECK3[$TITLE]}
                RETVAL=${ERROR3[$TITLE]}
                checkCommandLineParameter
        done
        MES=""
        echoIt
}


# run before command
checks4() {
        MES="checks4"
        echoIt
        for TITLE in "${!CHECK4[@]}"
        do
		MESSAGE=${CHECK4[$TITLE]}
                RETVAL=${ERROR4[$TITLE]}
                checkCommandLineParameter
        done
        MES=""
        echoIt
}

# run after command line value checks
checks5() {
        MES="checks5"
        echoIt
        for TITLE in "${!CHECK5[@]}"
        do
                MESSAGE=${CHECK5[$TITLE]}
                RETVAL=${ERROR5[$TITLE]}
                checkCommandLineParameter
        done
        MES=""
        echoIt
}

usage() {
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
# problably add SERVICE at a later time

case $COMMAND in
    mount)
	hasCommandLineParameters
	checks1
	checks2
	checks3
	mount ${VALUES[$HOST]}:${VALUES[$EXPORT]} ${VALUES[$MOUNT]}
	if [ ! $? -eq 0 ]; then
	        MES="Some error while mounting ${VALUES[$HOST]}:${VALUES[$EXPORT]} onto ${VALUES[$MOUNT]}"
        	loggerExit
	fi
	checks5
	MES="${VALUES[$MOUNT]} mounted"
	echoIt
    ;;
    unmount)
	hasCommandLineParameters
	checks4
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
	hasCommandLineParameters
	checks4
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

