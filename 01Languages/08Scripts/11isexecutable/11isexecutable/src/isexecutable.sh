#!/bin/bash
# programmer: De Dauw Valentijn
#       date: 2019/05/06
#     script: isexecutable.sh
#    purpose: checks if given param is an installed program
#
#
# arguments                          default
# SILENCE     silence                silences the script, no echo
# TAG         thetag                 the tag for the 'logger'
# EXDCUTABLES rsync lftp             a series of executable names to check 
#
# both TAG and EXECUTABLES must be present, if not NO_PARAMETERS is returned
#
# returns not 0 if either one of the executables is not executable of not found
#
# history
# 0.0.1 creation
# 0.0.2 use a series of executables instead of a single one
#       use shift to get rid of silence and tag

SCRIPT="isexecutable.sh"
VERSION="0.0.1"
DATE="2019/05/26"
TAG="ISEXECUTABLE"

RETVAL=0
NO_PARAMETERS=1
NO_EXECUTABLES=2
DOES_NOT_EXIST=3
NOT_EXECUTABLE=4
NO_GAWK=5
NO_GREP=6

echoIt() {
   if [ -z $SILENCE ]; then SILENCE="---"; fi
   if [ $SILENCE = 'silence' ]; then return; fi
   if [ $SILENCE = 'SILENCE' ]; then return; fi
   echo "$MES"
}

# produce a log message in the logger and on screen
logit()
{
   MES="$SCRIPT $MES"
   logger -t $TAG "$MES"
   echoIt
}

# log something and then exit abnormaly
loggerExit()
{
   SILENCE="---"
   logit
   exit $RETVAL
}

isProgram() {
        MES="      checking executable $PROGRAM"
	echoIt

	whereis $PROGRAM | grep /$PROGRAM > /dev/null
	if [ ! $? -eq 0 ]; then
        	RETVAL=$DOES_NOT_EXIST
        	MES="Executable $PROGRAM does not exist"
        	loggerExit
	fi

	FILES=$(whereis $PROGRAM)
	for FILE in $FILES
	do
        	EXE=$(echo $FILE | gawk -F '/' '{print $NF}')
        	if [ $EXE = $PROGRAM ]; then
                	if [ ! -x $FILE ]; then
                        	RETVAL=$NOT_EXECUTABLE
                        	MES="$PROGRAM is not executable"
                        	loggerExit
                	fi
        	fi
	done
}

if [ ! -x /bin/grep ]; then
        # if grep not found, problably 'logger' does not exist either, just error exit
        exit $NO_GREP
fi

SILENCE=$1
# if silence, get rid of it
if [ -z $SILENCE ]; then SILENCE="---"; fi
if [ $SILENCE = "silence" ]; then shift; fi
if [ $SILENCE = "SILENCE" ]; then shift; fi
TAG=$1
if [ -z $TAG ]; then
	MES="no parameters"
	RETVAL=$NO_PARAMETERS
	loggerExit
fi
# get rid of TAG
shift

# check if we have gawk
PROGRAM="gawk"
isProgram
PROGRAM="grep"
isProgram

# the other parameters are all programs to check
PROGRAMS=("$@")

MES="Checking programs"
echoIt
for PROGRAM in "${PROGRAMS[@]}"
do
	isProgram
done


