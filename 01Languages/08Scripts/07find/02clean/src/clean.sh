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
# 0.1.5 new system, see mount.sh
# 0.1.6 uses WC -w for has parameter instead of -z

SCRIPT="clean.sh"
VERSION="0.1.5"
DATE="2019/05/08"

RETVAL=0

# define local vars
TAG="CLEAN"
OPTIONS=

# return values indicating incorrect command line values are the same as the check numbers
# as a documentation feature they are repeated as an error name
TNAME="tag"
IS_TAG=1                 # dummy value, no check for 'tag'

# this is the directory
DIRECTORY="directory"
NO_DIRECTORY=10          # retval for no parameter
IS_DIRECTORY=10          # checks if this value is an existing directory
DIR_NOT_EXIST=10         # retval for not exist

# define arrays
PROGRAMS=("gawk" "grep" "find.sh")
PARAMS=("$@")

declare -A SYNTAXS
SYNTAXS=([$TNAME]="tag=" [$DIRECTORY]="directory=")
declare -A VALUES
declare -A RETVALS
RETVALS=([$TNAME]=$NO_TAG [$DIRECTORY]=$NO_DIRECTORY)
declare -A HASPARAM
HASPARAM=([$TNAME]="N" [$DIRECTORY]="Y")

# before cycle
declare -A BEFORE_RETVALS
BEFORE_RETVALS=([$DIRECTORY]=$DIR_NOT_EXIST)
declare -A BEFORE_CHECKS
BEFORE_CHECKS=([$DIRECTORY]=$IS_DIRECTORY)

echoIt() {
   if [ -z $SILENCE ]; then SILENCE="---"; fi
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
			WC=$(echo $VALUE | wc -w)
                        if [ $WC -eq 0 ]; then
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
        case $CHECK in
                $IS_DIRECTORY)
                        # check if directory exists, if not --> could not create it
                        MES="      is directory: ${VALUES[$DIRECTORY]}"
                        echoIt
                        WC=$(echo ${VALUES[$DIRECTORY]} | wc -w)
                        if [ ! $WC -eq 1 ]; then
                                MES="parameter directory value '${VALUES[$DIRECTORY]}' does not designate a directory"
                                loggerExit
                        fi
                        if [ ! -d ${VALUES[$DIRECTORY]} ]; then
                                MES="directory ${VALUES[$DIRECTORY]} does not exist"
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

SILENCE=$1

lookiPrograms
readCommandLineParameters
hasCommandLineParameters
beforeChecks

# define default values
if [ -z ${VALUES[$TNAME]} ]; then VALUES[$TNAME]="CLEAN"; fi
# if a tag was given use it
TAG=${VALUES[$TNAME]}

MES="version $VERSION from $DATE"
logit

find.sh $SILENCE execute tag=$TAG directory=${VALUES[$DIRECTORY]} pattern="*bak" action="rm"
find.sh $SILENCE execute tag=$TAG directory=${VALUES[$DIRECTORY]} pattern="*~" action="rm"
find.sh $SILENCE execute tag=$TAG directory=${VALUES[$DIRECTORY]} pattern="*conflicting" action="rm"
find.sh $SILENCE execute tag=$TAG directory=${VALUES[$DIRECTORY]} pattern="*dropbox.attr" action="rm"

MES="${VALUES[$DIRECTORY]} cleaned"
logit

