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

SCRIPT="find.sh"
VERSION="0.0.8"
DATE="2019/05/08"

RETVAL=0
NO_DIR=1
NO_NAME=2
NO_ACTION=3

# define local vars
TAG="FIND"
OPTIONS=

echoIt() {
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
                "tag=")    TAG=$VALUE ;;
		"dir=")    DIR=$VALUE ;;
                "name=")   NAME=$VALUE ;;
		"action=") ACTION=$VALUE ;;
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

hasArgument() {
	if [ $SYNTAX = "tag=" ]; then return; fi
	MES="checking argument $SYNTAX"
	case $SYNTAX in
		"dir=")    RETVAL=$NO_DIR;    VALUE=$DIR ;;
		"name=")   RETVAL=$NO_NAME;   VALUE=$NAME ;;
		"action=") RETVAL=$NO_ACTION; VALUE=$ACTION ;;
	esac
	MES="$MES $VALUE"
        echoIt
	if [ -z $VALUE ]; then
		MES="$SYNTAX undefined"
		loggerExit
	fi
        case $SYNTAX in
                "dir=")
		        if [ ! -d $DIR ]; then
        		        MES="directory $DIR does not exist"
		                loggerExit
			fi
		;;
        esac
}

showArgument() {
        case $SYNTAX in
		"tag=")    VALUE=$TAG ;;
		"dir=")    VALUE=$DIR ;;
		"name=")   VALUE=$NAME ;;
		"action=") VALUE=$ACTION ;;
        esac
	MES="$SYNTAX $VALUE"
        echoIt
}

# no echo when SILENCE='silence' or 'SILENCE'
SILENCE=$1

# define arrays
PROGRAMS=("gawk" "grep" "find")
ARGS=("$@")
#define the syntax arrays
declare -A SYNTAXS
declare -A TODOS
SYNTAXS=([tag]="tag=" [dir]="dir=" [name]="name=" [action]="action=")
TODOS=([tag]="tag=" [dir]="dir=" [name]="name=" [action]="action=")

MES="checking programs"
echoIt
for PROGRAM in "${PROGRAMS[@]}"
do
        lookiProgram
done
MES=""
echoIt

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

# no tag, reset to default
if [ -z $TAG ]; then TAG="FIND"; fi

# we are alive
MES="$SCRIPT version $VERSION from $DATE"
logit
MES=""
echoIt

MES="checking arguments"
echoIt
for SYNTAX in "${SYNTAXS[@]}"
do
        hasArgument
done
MES=""
echoIt

MES="settings are"
echoIt
for SYNTAX in "${SYNTAXS[@]}"
do
        showArgument
done

find $DIR -name $NAME -exec $ACTION {} \;

MES="$NAME $ACTION"
logit
