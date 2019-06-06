#!/bin/bash
#
# Programmer: De Dauw Valentijn
#       Date: 2019/05/06
#     Target: general mount script
#             mounting a block device volume on a mountpoint
#      Usage: lmount.sh arguments
#
# name        example                                    syntax      description                                     default
# TAG         tag=thetag                                  tag=       TAG for logger                                  MOUNT     optional
# SILENCE     silence                                                when set the script will not echo               optional !!! only $1
# SERIAL      serial="123456789"                          serial=    the short serial number from udevadm parmaeters
# LABEL       label="14iso"                               label=     the volume label
# UUID        uuid="dcda2c1c-98d4-423c-8701-3ab75a832dd8" uuid=      the UUID of the partition to mount
# MOUNT       mount=/data                                 mount=     the mountpoint to mount onto
# SIZE        size=1.8T                                   size=      the expected size when mounted                  not checked when empty
# DEVICES                                                            the non-virtual block devices on this host
#
# example:
#     lmount.sh $SILENCE tag=$TAG serial="TOSHIBA_TransMemory_0023242CA148EE41A000171D-0:0" label="14iso" mount="/14iso" size="32G"
#
# !! the script must be run as 'root', use sudo or su
#
# history
# 0.1.9 creation
# 0.2.1 external and internal parameters
# 0.2.2 using normal arrray (not associative)
# 0.2.3 some beautifying in device holding

SCRIPT="lmount.sh"
VERSION="0.2.3"
DATE="2019/06/03"
MES=" "

# return value, default value 0
RETVAL=0
NO_ISEXECUATBLE=-1
NO_PROGRAM=-2

DO_EXIT="true"

# define arrays
OPTIONS=
COMMANDS=("mount" "unmount" "show" "checks" "free" "usage" "uuids" "serials")

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
# ID 1,2,3,4 are not used as check, but as 'check serie' identifier
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

# devices logic
# 1 collect non-virtual devices
# 2 check if device with given serial is present
# 3 check select device with given UUID
# 4 check if DEVICE has given label
# --> device to mount selected

# all non virtual devices
# origin: must be collected

DEVICES=20
# collect the non-virtual devices
declare -a COLLECTED
 NAMES[$DEVICES]="DEVICES"
VALUES[$DEVICES]="false"
CHECK1[$DEVICES]=$DEVICES
# the actual device to mount
DEVICE=21
 NAMES[$DEVICE]="DEVICE"
VALUES[$DEVICE]="false"

# local device serial number
# used to check if present in the devices collection
# origin: given on command line

# read from the comand line
SERIAL=30
   NAMES[$SERIAL]="SERIAL"
  VALUES[$SERIAL]="false"
 SYNTAXS[$SERIAL]="serial="
# serial device holder
SERIAL_DEVICE=31
   NAMES[$SERIAL_DEVICE]="SERIAL_DEVICE"
  VALUES[$SERIAL_DEVICE]="false"
# check if there is a device with serial
SERIAL_PRESENT=32
 NAMES[$SERIAL_PRESENT]="SERIAL_PRESENT"
VALUES[$SERIAL_PRESENT]="false"
CHECK1[$SERIAL_PRESENT]=$SERIAL_PRESENT

# uuid for the volume
# used to check if present in the devices collection
# origin: given on command line

# read from the command line
UUID=40
   NAMES[$UUID]="UUID"
  VALUES[$UUID]="false"
 SYNTAXS[$UUID]="uuid="
# uuid device holder
UUID_DEVICE=41
   NAMES[$UUID_DEVICE]="UUID_DEVICE"
  VALUES[$UUID_DEVICE]="false"
# check if volume with UUID present
UUID_PRESENT=42
 NAMES[$UUID_PRESENT]="UUID_PRESENT"
VALUES[$UUID_PRESENT]="false"
CHECK1[$UUID_PRESENT]=$UUID_PRESENT

# local volume label
# used to check if device with UUID contains label
# origin: given on the command line

# read from the command line
LABEL=50
   NAMES[$LABEL]="LABEL"
  VALUES[$LABEL]="false"
 SYNTAXS[$LABEL]="label="
# label device holder
LABEL_DEVICE=51
   NAMES[$LABEL_DEVICE]="LABEL_DEVICE"
  VALUES[$LABEL_DEVICE]="false"
# check if label is present in volume with UUID
LABEL_PRESENT=52
 NAMES[$LABEL_PRESENT]="LABEL_PRESENT"
VALUES[$LABEL_PRESENT]="false"
CHECK1[$LABEL]=$LABEL_PRESENT

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

# expected size after mount (optional)
# origin: given on the command line
# read from the command line
SIZE=100
   NAMES[$SIZE]="SIZE"
  VALUES[$SIZE]="false"
 SYNTAXS[$SIZE]="size="
# checks it the mounted volume size is given size
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
                if [ $VALUE = "not readed" ]; then
	                MES="command line parameter '$NAME' has no value"
                        loggerExit
                fi
        done
        MES=""
        echoIt
}

checkParameters() {
        case $ID in
		$DEVICES)
			if [ $VALUE = "false" ];then
	                        MES="      collect all non-virtual block devices"
        	                echoIt
				# collect all block devices
				DEVS=($(find /dev/* -type b))
				COUNT=0
				for DEV in "${DEVS[@]}"
				do
					MES="         collecting device $DEV"
					echoIt
					udevadm info --query=all --name=$DEV | grep '/devices/virtual' > /dev/null
					# collect only real block devices, exclude virtual devices
					if [ ! $? -eq 0 ]; then
						MES="         --> device $COUNT, $DEV collected"
						echoIt
						COLLECTED[$COUNT]=$DEV
						COUNT=$(($COUNT+1))
					fi
				done
				VALUES[$DEVICES]="true"
				MES="         --> Collection ${COLLECTED[@]}"
				echoIt
				if [ ${VALUES[$DEVICES]} = "false" ]; then
					MES="no block device found"
					loggerExit
				fi
			fi
		;;

		$SERIAL_PRESENT)
			if [ $VALUE = "false" ]; then
	                        MES="      check if serial ${VALUES[$SERIAL]} is present"
        	                echoIt
				# checks if there is a device with this serial number
				# udevadm info --query=all --name=/dev/sdb | grep ID_SERIAL > /dev/null
			        for DEV in "${COLLECTED[@]}"
				do
					MES="         checking $DEV for serial '${VALUES[$SERIAL]}'"
					echoIt
					udevadm info --query=all --name=$DEV | grep ${VALUES[$SERIAL]} > /dev/null
					if [ $? -eq 0 ];then
						MES="            --> $DEV has serial ${VALUES[$SERIAL]}"
						echoIt
						VALUES[$SERIAL_PRESENT]="true"
						VALUES[$SERIAL_DEVICE]=$DEV
					fi
				done
                	        if [ ${VALUES[$SERIAL_PRESENT]} = "false" ]; then
                        	        MES="device with serial ${VALUES[$SERIAL]} not found"
	                                loggerExit
        	                fi
			fi
                ;;

                $LABEL_PRESENT)
			if [ $VALUE = "false" ]; then
	                        MES="      check label ${VALUES[$LABEL]} is present"
        	                echoIt
        	                # checks if DEVICE has label
                	        e2label ${VALUES[$UUID_DEVICE]} | grep ${VALUES[$LABEL]} > /dev/null
                        	if [ ! $? -eq 0 ];then
					MES="label ${VALUES[$LABEL]} not present on device ${VALUES[$UUID_DEVICE]}"
					loggerExit
        	                fi
				VALUES[$LABEL_DEVICE]=${VALUES[$UUID_DEVICE]}
				VALUES[$LABEL_PRESENT]="true"
				MES="         device ${VALUES[$UUID_PRESENT]} has label ${VALUES[$LABEL]}"
				echoIt
				VALUES[$DEVICE]=${VALUES[$LABEL_DEVICE]}
			fi
                ;;

                $UUID_PRESENT)
			if [ $VALUE = "false" ]; then
	                        MES="      check for device with UUID ${VALUES[$UUID]}"
        	                echoIt
                	        # select DEVICE with UUID
				DEV=$(blkid -U ${VALUES[$UUID]})
                      		if [ ! -z $DEV ];then
	                              	MES="         --> device $DEV with UUID ${VALUES[$UUID]} found"
                                        echoIt
					VALUES[$UUID_PRESENT]="true"
					VALUES[$UUID_DEVICE]=$DEV
                	        fi
				if  [ ${VALUES[$UUID_PRESENT]} = "false" ]; then
                	                MES="device with UUID ${VALUES[$UUID]} not found"
					loggerExit
				fi
			fi
                ;;

                $IS_DIRECTORY)
			if [ $VALUE = "false" ]; then
	                        # check if this value designates a directory
        	                MES="      check if ${VALUES[$MOUNT]} designates a directory"
                	        echoIt
					WC=$(echo ${VALUES[$MOUNT]} | wc -w)
        	                if [ ! $WC -eq 1 ]; then
                	                MES="${VALUES[$MOUNT]} does not designate a directory"
                        	        loggerExit
	                        fi
				VALUES[$IS_DIRECTORY]="true"
			fi
                ;;

                $DIRECTORY_EXIST)
			if [ $VALUE = "false" ]; then
	                        # check if directory exists,
				MES="      check directory ${VALUES[$MOUNT]} exist"
				echoIt
	                        if [ ! -d ${VALUES[$MOUNT]} ]; then
        	                        MES="${VALUES[$MOUNT]} does not exist"
					loggerExit
	                        fi
				VALUES[$DIRECTORY_EXIST]="true"
				MES="         ${VALUES[$MOUNT]} directory exist"
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
	                        MES="      check ${VALUES[$MOUNT]} already mounted"
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
	                        MES="      is ${VALUES[$MOUNT]} mounted"
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
				MES="      are we the root user"
				echoIt
				whoami | grep 'root' > /dev/null
				if [ ! $? -eq 0 ]; then
					MES="this script needs to be the root user, use 'su' or 'sudo'"
					loggerExit
				fi
				VALUES[$ROOT]="true"
				MES="         we are the root user"
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
        echo "lmount.sh, mount given 'device by serial and uuid with label' upon given mountpoint"
        echo "commands are:"
        echo "  -->   mount, mount the export onto the mountpoint (default)"
        echo "  --> unmount, unmount the mountpoint"
        echo "  -->    free, show used and free space on given mountpoint"
        echo "  -->    show, do nothing, show given parameter values"
	echo "  -->  checks, show the check parameter order"
	echo "  -->   uuids, show all devices with uuid"
        echo "  --> silence, do not echo messages"
        echo "  -->   usage, show this message"
        echo ""
        echo "parameters are:"
        echo "  -->       tag=, the TAG to use for the 'logger' command, see /var/log/syslog"
        echo "  -->    serial=, the serial number of the device where the volume resides"
        echo "  -->     label=, the label of the volume to mount"
        echo "  -->      uuid=, the UUID of the volume to mount, possibly the device uuid or a partition uuid"
        echo "  -->     mount=, the mountpoint to mount the volume upon"
        echo "  -->      size=, optional, the expected size once the volume is mounted"
        echo
        echo "the script needs to run as 'root', be 'root' or use 'sudo'"
        echo
        echo "example:"
	TAG="tag='14ISO'"
	SERIAL="serial='TOSHIBA_TransMemory_0023242CA148EE41A000171D-0:0'"
	UUID="uuid='85462c8d-05af-4428-babe-970368d96283'"
	LABEL="label=14iso"
	MOUNT="mount=/14iso"
	SIZE="size=32G"
        echo "sudo lmount.sh silence mount $TAG $SERIAL $UUID $LABEL $MOUNT"
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

TAG="LMOUNT"
MES="version $VERSION from $DATE"
logit

if [ ! -x /usr/bin/isexecutable.sh ]; then
	RETVAL=$NO_ISEXECUTABLE
	MES="isexecutable not installed"
	loggerExit
fi

isexecutable.sh silence $TAG "mount" "umount" "find" "udevadm" "whoami" "df" "mkdir" "e2label"
if [ ! $? -eq 0 ]; then
	RETVAL=$NO_PROGRAM
	MES="one or more programs not installed"
	loggerExit
fi
readCommandLineParameters
if [ ! -z $COMMAND ]; then VALUES[$COMMAND_ID]=$COMMAND; fi

# set default values if needed
if [ -z ${VALUES[$TAG_ID]} ]; then VALUES[$TAG_ID]="LMOUNT"; fi
# if a tag was given then use it
TAG=${VALUES[$TAG_ID]}
# problably add SERVICE at a later time

case $COMMAND in
    mount)
	hasCommandLineParameters
	CHECKS=(${CHECK1[@]})
        checks
	mount ${VALUES[$DEVICE]} ${VALUES[$MOUNT]}
	if [ ! $? -eq 0 ]; then
	        MES="Some error while mounting ${VALUES[$DEVICE]} onto ${VALUES[$MOUNT]}"
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
	checks # is mounted
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
	CHECKS=(${CHECK3[@]}) # is mounted
	checks
	df -h | grep ${VALUES[$MOUNT]}
    ;;
    uuids)
        blkid
    ;;
    usage)
	usage
    ;;
    *)  echo "$SCRIPT version $VERSION missing command and parameters"
	usage
    ;;
esac

