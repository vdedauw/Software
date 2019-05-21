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

SCRIPT="find.sh"
TAG="FIND"
VERSION="0.1.7"
DATE="2019/05/19"

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

# define local vars
OPTIONS=

# define arrays
PROGRAMS=("gawk" "grep" "find" "wc")
PARAMS=("$@")
OPTIONS=
COMMANDS=("silence" "find" "count" "execute" "show" "usage")

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

# pattern for the find -name option
PATTERN="pattern"
NO_PATTERN=10
 SYNTAXS+=([$PATTERN]="pattern=")
 RETVALS+=([$PATTERN]=$NO_PATTERN)
HASPARAM+=([$PATTERN]="Y")
# checks if pattern is ?? (will not be checked in bash)
IS_PATTERN_TITLE="is string ?"
IS_PATTERN_MESSAGE="is not a string !"
IS_PATTERN_ERROR=11
CHECK1+=([$IS_PATTERN_TITLE]=$IS_PATTERN_MESSAGE)
ERROR1+=([$IS_PATTERN_TITLE]=$IS_PATTERN_ERROR)

# directory path to recursively search in
DIRECTORY="directory"
NO_DIRECTORY=20
 SYNTAXS+=([$DIRECTORY]="directory=")
 RETVALS+=([$DIRECTORY]=$NO_PATTERN)
HASPARAM+=([$DIRECTORY]="Y")
# check if directory exist
IS_DIRECTORY_TITLE="is directory ?"
IS_DIRECTORY_MESSAGE="directory does not exist!"
IS_DIRECTORY_ERROR=21
CHECK1+=([$IS_DIRECTORY_TITLE]=$IS_DIRECTORY_MESSAGE)
ERROR1+=([$IS_DIRECTORY_TITLE]=$IS_DIRECTORY_ERROR)

# the action to perform on each found file
ACTION="action"
NO_ACTION=30
 SYNTAXS+=([$ACTION]="action=")
 RETVALS+=([$ACTION]=$NO_ACTION)
HASPARAM+=([$ACTION]="N")
# checks if action exists either as a script or a program
HAS_ACTION_TITLE="is a command ?"
HAS_ACTION_MESSAGE="is not a command !"
HAS_ACTION_ERROR=31
CHECK2+=([$HAS_ACTION_TITLE]=$HAS_ACTION_MESSAGE)
ERROR2+=([$HAS_ACTION_TITLE]=$HAS_ACTION_ERROR)

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
        # if HASTITLE indicates it, check it
        case $TITLE in
                $IS_DIRECTORY_TITLE)
                        # check if directory exists, if not --> could not create it
                        MES="      ${VALUES[$DIRECTORY]} $TITLE"
                        echoIt
                        WC=$(echo ${VALUES[$DIRECTORY]} | wc -w)
                        if [ ! $WC -eq 1 ]; then
                                MES="parameter directory value '${VALUES[$DIRECTORY]}' does not designate a directory"
                                loggerExit
                        fi
                        if [ ! -d ${VALUES[$DIRECTORY]} ]; then
                                MES="${VALUES[$DIRECTORY]} $MESSAGE"
                                loggerExit
                        fi
                ;;
		$HAS_ACTION_TITLE)
			# check if action is a valid command, ... installed program or script
			MES="      ${VALUES[$ACTION]} $TITLE"
			echoIt
        	        WC=$(echo ${VALUES[$ACTION]} | wc -w)
               	        if [ ! $WC -eq 1 ]; then
                       	        MES="parameter action value '${VALUES[$ACTION]}' does not designate a command"
                                loggerExit
       	                fi
			whereis ${VALUES[$ACTION]} > /dev/null 2>/dev/null
			if [ ! $? -eq 0 ]; then
				MES="${VALUES[$ACTION]} $MESSAGE"
				loggerExit
			fi
		;;
	esac
}

# run before 'find' program line value checks
check1() {
        MES="check1"
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

# run before 'find' program line value checks
check2() {
        MES="check2"
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

# no echo when SILENCE='silence' or 'SILENCE'
SILENCE=$1

MES="version $VERSION from $DATE"
logit

lookiPrograms
readCommandLineParameters

# set defaults
if [ -z ${VALUES[$TNAME]} ]; then VALUES[$TNAME]="FIND"; fi
# if a TAG was given then use it
TAG=${VALUES[$TNAME]}

case $COMMAND in
	find)
		hasCommandLineParameters
		check1
		find ${VALUES[$DIRECTORY]} -name "${VALUES[$PATTERN]}" -type f 2> /dev/null
	;;
	count)
		hasCommandLineParameters
		check1
		find ${VALUES[$DIRECTORY]} -name "${VALUES[$PATTERN]}" -type f 2> /dev/null | wc -l
	;;
	execute)
		HASPARAM[$ACTION]="Y"
		hasCommandLineParameters
		check1
		check2
		find ${VALUES[$DIRECTORY]} -name "${VALUES[$PATTERN]}" -type f -exec ${VALUES[$ACTION]} {} \; 2> /dev/null
	;;
	show)
		showValues
	;;
	usage)
		usage
	;;
	*)
		usage
	;;
esac

