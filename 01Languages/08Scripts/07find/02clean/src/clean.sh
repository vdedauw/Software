#!/bin/bash
#
# clean.sh
# Version 1.1
# clean.sh
# remove redundant files from a given path
# usage: clean.sh [TAG] directory
#
# if one wants the script to be silent argument 1 must be 'silence' of 'SILENCE'
#
# argument    example                description                default
# TAG         tag=thetag             TAG for logger             CLEAN     optional
# DIR         dir=directory          the directory to clean
#
# history
# 0.0.2 looki?? and has?? methods
# 0.0.3 added program and argument arrays
# 0.0.4 added syntax array
# 0.0.5 added verbosity
# 0.0.6 added showArgument
# 0.0.7 removed verbosity, because it did not work
# 0.0.8 now working with associative arrays for syntax and todo


SCRIPT="clean.sh"
VERSION="0.0.8"
DATE="2019/05/08"

RETVAL=0
NO_DIR=1

# define local vars
TAG="CLEAN"
OPTIONS=

echoIt() {
   if [ $SILENCE = "silence" ]; then return; fi
   if [ $SILENCE = "SILENCE" ]; then return; fi
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
		"tag=") TAG=$VALUE ;;
                "dir=") DIR=$VALUE ;;
        esac
}

# for each incoming argument
# look in the todos array
# when found remove element in todos
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
        case $SYNTAX in
		"tag=") return ;;
        esac
        MES="checking argument $SYNTAX"
        case $SYNTAX in
                "dir=")    RETVAL=$NO_DIR;    VALUE=$DIR ;;
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
        esac
        MES="$SYNTAX $VALUE"
        echoIt
}

SILENCE=$1

# define arrays
PROGRAMS=("gawk" "grep" "find.sh")
ARGUMENTS=("$@")
#define the syntax arrays
declare -A SYNTAXS
declare -A TODOS
SYNTAXS=([tag]="tag=" [dir]="dir=")
TODOS=([tag]="tag=" [dir]="dir=")

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
for ARGUMENT in "${ARGUMENTS[@]}"
do
        lookiArgument
        COUNT=$((COUNT+1))
done
MES=""
echoIt

# if no tag reset to default
if [ -z $TAG ]; then TAG="CLEAN"; fi

# say hello world
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
MES=""
echoIt

echo "tag = $TAG"

find.sh $SILENCE tag=$TAG dir=$DIR name="*bak" action="rm"
find.sh $SILENCE tag=$TAG dir=$DIR name="*~" action="rm"
find.sh $SILENCE tag=$TAG dir=$DIR name="*conflicting" action="rm"
find.sh $SILENCE tag=$TAG dir=$DIR name="*dropbox.attr" action="rm"

MES="$DIR cleaned"
logit

