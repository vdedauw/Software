#!/bin/bash
# programmer: De Dauw Valentijn
#       date: 2019/05/06
#    purpose: general rsync script
#
#
# arguments                          default
# TAG         tag=thetag             RSYNC     optional
# SOURCE      source=/data/
# TARGET      target=/backup02/data
# DELETE      delete=false           TRUE      optional, makes sure existing files in target but not in source are NOT deleted
#
# arguments are decoded using their name part, example: source= for the source
#

SCRIPT="rsync.sh"
VERSION="0.0.4"
DATE="2019/05/06"

RETVAL=0
NO_SOURCE=1
NO_TARGET=2

# define local vars
TAG="RSYNC"
SYNTAXS=("tag=" "source=" "target=" "delete=")
PROGRAMS=("gawk" "grep" "rsync")
ARGUMENTSS=("$@")
OPTIONS="-rvlptog --stats --progress"

# produce a log message in the logger and on screen
logit()
{
   logger -t $TAG "$MES"
   echo "$MES"
}

# log something and then exit abnormaly
loggerExit()
{
   logit
   exit $RETVAL
}

lookiProgram() {
        MES="check program $PROGRAM"
        logit
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
        echo $ARGUMENT | grep $SYNTAX > /dev/null
        if [ $? -eq 0 ]; then
                VALUE=$(echo $ARGUMENT | gawk -F = '{print $2}')
        fi
        case $SYNTAX in
                "tag=") TAG=$VALUE
                        if [ -z $TAG ]; then TAG="RSYNC"; fi
                ;;
                "source=") SOURCE=$VALUE ;;
                "target=") TARGET=$VALUE ;;
		"delete=") DELETE=$VALUE
			DELETE="--delete"
			if [ $DELETE  = "false" ]; then DELETE=""; fi
			if [ $DELETE  = "FALSE" ]; then DELETE=""; fi
		;;
        esac
}

lookiArgument() {
        for SYNTAX in "${SYNTAXS[@]}"
        do
                lookiArg
        done
}

hasSource() {
        RETVAL=$NO_SOURCE
        if [ -z $SOURCE ]; then
                MES="SOURCE undefined"
                loggerExit
        fi
	if [ ! -d $SOURCE ]; then
		MES="Source path $SOURCE does not exist"
		loggerExit
	fi
}

hasTarget() {
        RETVAL=$NO_TARGET
        if [ -z $TARGET ]; then
                MES="TARGET undefined"
                loggerExit
        fi
	if [ ! -d $TARGET ]; then
		MES="Target path $TARGET does not exist"
		loggerExit
	fi
}

for PROGRAM in "${PROGRAMS[@]}"
do
        lookiProgram
done
echo

COUNT=1
for ARGUMENT in "${ARGS[@]}"
do
	lookiArgument
	COUNT=$(($COUNT + 1))
done
echo

hasSource
hasTarget

echo "$SCRIPT version $VERSION from $DATE"
echo "tag $TAG"
echo "source $SOURCE"
echo "target $TARGET"

rsync $OPTIONS $DELETE $SOURCE $TARGET
