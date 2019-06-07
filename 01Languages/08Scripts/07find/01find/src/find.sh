#!/bin/bash
# programmer: De Dauw Valentijn
#       date: 2019/05/08
#    purpose: general rsync script
#
#
# arguments                          description                            default
# only first  'silence'              no echo will done
#             'SILENCE'
# TAG         tag=thetag             TAG for logger                         FIND     optional
# DIR         dir=directory          the directory to look in
# NAME        name=*back             filename to look for
# ACTION      action=action          action to perform on each single file
#
# !!! when one does not want all the echoes, argument 1 must be 'silence'
#
# arguments are decoded using their name part, example: name= for the name
#
# example: remove all '.bak' files from /data/Software
#     find.sh tag="CLEANING_SOFTWARE" dir="/data/Software" name="*.bak" action="rm"
#
# history
# 0.0.2 looki?? and has?? methods
# 0.0.3 added program and argument arrays
# 0.0.4 added syntax array
# 0.0.5 added verbosity
# 0.0.6 added showArgument
# 0.0.7 removed verbosity, because it did not work
# 0.0.8 now working with associative arrays for syntax and todo
# 0.1.5 new system, associative arrays, commands array, ...
# 0.1.6 added count, execute
# 0.1.7 in check?, use associative arrays for ?_title, ?_message, ?_error
# 0.1.8 isexecutable implemented
# 0.2.3 complte rewrite
# 0.2.4 removed some serious bugs

SCRIPT="find.sh"
TAG="FIND"
VERSION="0.2.4"
DATE="2019/06/07"

# return value, default value 0
RETVAL=0
NO_ISEXECUATBLE=-1
NO_PROGRAM=-2

DO_EXIT="true"

# define arrays
OPTIONS=
COMMANDS=("find" "count" "execute" "checks" "show" "usage")

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

# pattern for the find -name option
# origin: command line parameters
PATTERN=20
   NAMES[$PATTERN]="PATTERN"
  VALUES[$PATTERN]="false"
 SYNTAXS[$PATTERN]="pattern="
# checks if pattern is a string ?? (will not be checked in bash)
PATTERN_STRING=21
VALUES[$PATTERN_STRING]="false"
CHECK1[$PATTERN_STRING]=$PATTERN_STRING

# directory path to recursively search in
# origin: command line parameters
DIRECTORY=30
   NAMES[$DIRECTORY]="DIRECTORY"
  VALUES[$DIRECTORY]="false"
 SYNTAXS[$DIRECTORY]="directory="
#
# check mount designates a directory
IS_DIRECTORY=31
 NAMES[$IS_DIRECTORY]="IS_DIRECTORY"
VALUES[$IS_DIRECTORY]="false"
CHECK1[$IS_DIRECTORY]=$IS_DIRECTORY
# check if directory exist
DIRECTORY_EXIST=32
 NAMES[$DIRECTORY_EXIST]="DIRECTORY_EXIST"
VALUES[$DIRECTORY_EXIST]="false"
CHECK1[$DIRECTORY_EXIST]=$DIRECTORY_EXIST

# the action to perform on each found file
# origin: command line parameters
ACTION=40
   NAMES[$ACTION]="ACTION"
  VALUES[$ACTION]="false"
 SYNTAXS[$ACTION]="action="
# checks if action exists either as a script or a program
ACTION_EXCUTABLE=41
 NAMES[$ACTION_EXCUTABLE]="ACTION_EXCUTABLE"
VALUES[$ACTION_EXCUTABLE]="false"
CHECK2[$ACTION_EXCUTABLE]=$ACTION_EXCUTABLE

echoIt() {
   if [ -z $SILENCE ]; then SILENCE="---"; fi
   if [ $SILENCE = 'silence' ]; then return; fi
   if [ $SILENCE = 'SILENCE' ]; then return; fi
   echo "$MES"
}

logit() {
   MES="$SCRIPT $MES"
   logger -t $TAG "$MES"
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

		$IS_DIRECTORY)
                        if [ $VALUE = "false" ]; then
                                # check if this value designates a directory
                                MES="      check if ${VALUES[$DIRECTORY]} designates a directory"
                                echoIt
                                        WC=$(echo ${VALUES[$DIRECTORY]} | wc -w)
                                if [ ! $WC -eq 1 ]; then
                                        MES="${VALUES[$DIRECTORY]} does not designate a directory"
                                        loggerExit
                                fi
                                VALUES[$IS_DIRECTORY]="true"
                        fi
               ;;

               $DIRECTORY_EXIST)
                        if [ $VALUE = "false" ]; then
                                # check if directory exists,
                                MES="      check directory ${VALUES[$DIRECTORY]} exist"
                                echoIt
                                if [ ! -d ${VALUES[$DIRECTORY]} ]; then
                                        MES="${VALUES[$DIRECTORY]} does not exist"
                                        loggerExit
                                fi
                                VALUES[$DIRECTORY_EXIST]="true"
                                MES="         ${VALUES[$DIRECTORY]} directory exist"
                                echoIt
                        fi
                ;;

		$ACTION_EXECUTABLE)
			# check if action is a valid command, ... installed program or script
			if [ $VALUE = "false" ]; then
				MES="      ${VALUES[$ACTION]} exist and is executable ?"
				echoIt

				isexecutable.sh SILENCE $TAG ${VALUES[ACTION]}
				if [ $? -eq 0 ]; then
					MES="      ${VALUES[$ACTION]} exist and is executable"
					echoIt
					VALUES[$ACTION_EXECUTABLE="true"]
				fi

				if [ ${VALUES[$ACTION_EXECUTABLE]} = "false" ];then
					MES="      action ${VALUES[$ACTION_EXECUTABLE]} is not executable"
					loggerExit
				fi
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
        echo "$SCRIPT version $VERSION from $DATE"
        echo
        echo "usage: $SCRIPT silence command  directory='path' pattern='search pattern' action='command'"
        echo
        echo "   commands are"
        echo "    silence, be silent do not show program and parameter checking"
        echo "       find, find files"
        echo "      count, count files"
        echo "    execute, execute an action on each file"
        echo "       show, show command and parameter values"
        echo "      usage, show this message"
        echo
	echo "   parameters are"
	echo "          tag=, the tag used for the 'logger' command, see /var/sys/syslog"
        echo "         name=, the name (pattern) the search for"
	echo "    directory=, the path to recusively search in"
	echo "       action=, optional, the action to perform on each found file"
        echo
#        echo "   options are" # see man find
#	echo ""
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

disableExitChecks() {
        DO_EXIT="false"
        CHECKS=(${CHECK1[@]})
        checks
        CHECKS=(${CHECK2[@]})
        checks
        CHECKS=(${CHECK3[@]})
        checks
        CHECKS=(${CHECK4[@]})
        checks
}

# no echo when SILENCE='silence' or 'SILENCE'
SILENCE=$1
if [ -z $SILENCE ]; then SILENCE="---"; fi
if [ $SILENCE = "silence" ]; then shift; fi
if [ $SILENCE = "SILENCE" ]; then shift; fi
PARAMS=("$@")

TAG="FIND"
MES="version $VERSION from $DATE"
logit

if [ ! -x /usr/bin/isexecutable.sh ]; then
        RETVAL=$NO_ISEXECUTABLE
        MES="isexecutable not installed"
        loggerExit
fi

isexecutable.sh silence $TAG "find" "wc"
if [ ! $? -eq 0 ]; then
        RETVAL=$NO_PROGRAM
        MES="one or more programs not installed"
        loggerExit
fi
readCommandLineParameters

# set defaults
if [ -z ${VALUES[$TNAME]} ]; then VALUES[$TNAME]="FIND"; fi
# if a TAG was given then use it
TAG=${VALUES[$TNAME]}

case $COMMAND in
	find)
		hasCommandLineParameters
	        CHECKS=(${CHECK1[@]})
        	checks
		find ${VALUES[$DIRECTORY]} -name "${VALUES[$PATTERN]}" -type f 2> /dev/null
	;;
	count)
		hasCommandLineParameters
                CHECKS=(${CHECK1[@]})
                checks
		find ${VALUES[$DIRECTORY]} -name "${VALUES[$PATTERN]}" -type f 2> /dev/null | wc -l
	;;
	execute)
		HASPARAM[$ACTION]="Y"
		hasCommandLineParameters
                CHECKS=(${CHECK1[@]})
                checks
		# check action
                CHECKS=(${CHECK2[@]})
                checks
		find ${VALUES[$DIRECTORY]} -name "${VALUES[$PATTERN]}" -type f -exec ${VALUES[$ACTION]} {} \; 2> /dev/null
	;;
	show)
		disableExitChecks
		showValues
	;;
	checks)
		disableExitChecks
		showChecks
	;;
	usage)
		usage
	;;
	*)
		usage
	;;
esac

