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
#     mount.sh tag="CH3SNAS" nfshost="ch3snas" nfsexport="/mnt/HD_a2/data" nfsmount="/data" nfsport=2048 nfssize="1.8T"
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
# 0.0.9 making sure echoIt does has an error

SCRIPT="mount.sh"
VERSION="0.0.9"
DATE="2019/05/06"
MES=" "

RETVAL=0
NO_HOST=1
NO_EXPORT=2
NO_MOUNTPOINT=3
ALREADY_MOUNTED=4
NO_NFS=5
NO_SIZE=6
NO_PORT=7

# define local vars
TAG="MOUNT"

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
        MES="check program $PROGRAM"
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

lookiArg() {
        echo $ARGUMENT | grep $TODO > /dev/null
        if [ $? -eq 0 ]; then
                VALUE=$(echo $ARGUMENT | gawk -F = '{print $2}')
        fi
        case $TODO in
                "tag=")       TAG=$VALUE ;;
                "nfshost=")   NFSHOST=$VALUE ;;
                "nfsexport=") NFSEXPORT=$VALUE ;;
                "nfsmount=")  NFSMOUNT=$VALUE ;;
		"NFSPORT=")   NFSPORT=$VALUE ;;
                "NFSSIEER=")  NFSSIZE=$VALUE ;;
        esac
}

lookiArgument() {
        MES="read argument $COUNT $ARGUMENT"
        echoIt
        for KEY in "${!TODOS[@]}"
        do
                TODO=${TODOS[$KEY]}
                VALUE=
                lookiArg
                if [ ! -z $VALUE ]; then
                        unset TODOS[$KEY]
                        return # stop looking
                fi
        done
}

hasSize() {
	if [ -z $NFSSIZE ]; then return; fi
	LINE=$(df -h | grep $NFSMOUNT)
	SIZE=$(echo $LINE | gawk '{print $2}')
	# size and nfsSize are treated as strings because ',' and 'T'
	if [ ! $SIZE = $NFSSIZE ];then
		MES1="Warning size $SIZE is not equal to nfsSize $NFSSIZE"
		logit
	fi
}

hasArgument() {
        if [ $SYNTAX = "tag=" ]; then return; fi
        if [ $SYNTAX = "nfssize=" ]; then return; fi
        MES="has argument $SYNTAX"
        case $SYNTAX in
                "nfshost=")    RETVAL=$NO_HOST;       VALUE=$NFSHOST ;;
                "nfsexport=")  RETVAL=$NO_EXPORT;     VALUE=$NFSEXPORT ;;
                "nfsmount=")   RETVAL=$NO_MOUNTPOINT; VALUE=$NFSMOUNT ;;
        esac
        MES="$MES $VALUE"
        echoIt
        if [ -z $VALUE ]; then
                MES="$SYNTAX undefined"
                loggerExit
        fi
}

checkArgument() {
	if [ $SYNTAX = "tag=" ]; then return; fi
        if [ $SYNTAX = "nfssize=" ]; then return; fi
	MES="checking argument $SYNTAX"
	echoIt
        case $SYNTAX in
                "nfshost=")
			RETVAL=$NO_HOST
		        ping -c 1 $NFSHOST > /dev/null
		        if [ ! $? -eq 0 ]; then
		                MES="host $NFSHOST not online"
		                loggerExit
		        fi
			RETVAL=$NO_NFS
        		# check if the nas server has NFS service
		        nmap $NFSHOST | grep $NFSPORT > /dev/null
		        if [ ! $? -eq 0 ]; then
		                MES="NFS server $NFSHOST has no NFS service on port $NFSPORT"
		                loggerExit
		        fi
		;;
                "nfsexport=")
		        RETVAL=$NO_EXPORT
		        showmount -e $NFSHOST | grep $NFSEXPORT > /dev/null
		        if [ ! $? -eq 0 ]; then
		                MES="export $NFSEXPORT not exported on host $NFSHOST"
		                loggerExit
		        fi
		;;
                "nfsmount=")
		        RETVAL=$ALREADY_MOUNTED
		        mount | grep $NFSMOUNT > /dev/null
		        if [ $? -eq 0 ]; then
		                MES="mountpoint $NFSMOUNT already mounted"
		                loggerExit
		        fi
			RETVAL=$NO_MOUNTPOINT
		        if [ ! -d $NFSMOUNT ]; then
		                mkdir $NFSMOUNT
		        fi
		        if [ ! -d $NFSMOUNT ]; then
		                MES="could not create mountpoint $NFSMOUNT"
		                loggerExit
		        fi
		;;
        esac
}

showArgument() {
        case $SYNTAX in
                "tag=")       VALUE=$TAG ;;
                "nfshost=")   VALUE=$NFSHOST ;;
                "nfsexport=") VALUE=$NFSEXPORT ;;
                "nfsmount=")  VALUE=$NFSMOUNT ;;
		"nfsport=")   VALUE=$NFSPORT ;;
		"nfssize=")   VALUE=$NFSSIZE ;;
                "verbose=")   VALUE=$VERBOSE ;;
        esac
        MES="$SYNTAX $VALUE"
        echoIt
}

SILENCE=$1

# define arrays
PROGRAMS=("gawk" "grep" "nmap" "ping" "mount" "showmount")
ARGS=("$@")
OPTIONS=
#define the syntax arrays
declare -A SYNTAXS
declare -A TODOS
SYNTAXS=([tag]="tag=" [nfshost]="nfshost=" [nfsexport]="nfsexport=" [nfsmount]="nfsmount=" [nfsport]="nfsport=" [nfssize]="nfssize=")
TODOS=([tag]="tag=" [nfshost]="nfshost=" [nfsexport]="nfsexport=" [nfsmount]="nfsmount=" [nfsport]="nfsport=" [nfssize]="nfssize=")

# check the programs this script us using
MES="checking programs"
echoIt
for PROGRAM in "${PROGRAMS[@]}"
do
        lookiProgram
done
MES=""
echoIt

# read the arguments from the command line
MES="reading arguments"
echoIt
COUNT=1
for ARGUMENT in "${ARGS[@]}"
do
        lookiArgument
        COUNT=$((COUNT+1))
done
MES=""
echoIt

if [ -z $TAG ]; then TAG="MOUNT"; fi
if [ -z $NFSPORT ]; then NFSPORT=2049; fi

# check if we are root
# we need tobe root for the mount command
whoami | grep 'root' > /dev/null
if [ ! $? -eq 0 ]; then
	MES="we need to be 'root' to run this script"
	loggerExit
fi

# we are alive
MES="$SCRIPT version $VERSION from $DATE"
logit
MES=""
echoIt

MES="has arguments"
echoIt
for SYNTAX in "${SYNTAXS[@]}"
do
        hasArgument
done
MES=""
echoIt

MES="check arguments"
echoIt
for SYNTAX in "${SYNTAXS[@]}"
do
        checkArgument
done
MES=""
echoIt

MES="settings are"
echoIt
for SYNTAX in "${SYNTAXS[@]}"
do
        showArgument
done

mount $NFSHOST:$NFSEXPORT $NFSMOUNT
if [ ! $? -eq 0 ]; then
	MES="Some error while mounting"
	loggerExit
fi

hasSize

MES="$NFSMOUNT mounted"
logit

