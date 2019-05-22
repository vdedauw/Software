#!/bin/bash
# programmer: De Dauw Valentijn
#       date: 2019/05/18
#
# uses the fpt protocol to sync ftp server with client
# mainly used for: sync website from provider to local dir and vice versa
#
# tip when receiving lftp certificate error
# 1) create a new dir if not exists ~/lftp
# 2) create a new file ~/lftp/rc
#     contents one line: set ssl:verify-certificate no
#
# arguments                          description                            default
# TAG         tag=thetag             TAG for logger                         LFTP     optional
# VERBOSE     verbose=1              the verbosity level                    0        optional
# HOST        host=thehost
# LOCALDIR    localdir=thedir
# REMOTEDIR   remotedir=thedir
# FTPUSER     user=theuser           www-data
# FTPPASSWORD password=thepassword   www-datapw
#
# when FTPPASSWORD is empty and FTPUSER=anonymous, connection is made without paswword
#
# arguments are decoded using their name part, example: domain= for the domain
#
# history
# 0.0.2 looki?? and has?? methods
# 0.0.3 added program and argument arrays
# 0.0.4 added syntax array
# 0.0.5 added verbosity
# 0.0.6 added showArgument
# 0.1.5 new system, associative arrays, commands array, ...
# 0.1.7 in check?, use associative arrays for ?_title, ?_message, ?_error

SCRIPT="lftp.sh"
VERSION="0.1.7"
DATE="2019/05/22"

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

# define arrays
PROGRAMS=("gawk" "grep" "lftp" "nmap" "ping" "clean.sh")
PARAMS=("$@")
OPTIONS=
COMMANDS=("silence" "publish" "backup" "show" "usage")

# return values indicating incorrect command line values are the same as the check numbers
# as a documentation feature they are repeated as an error name
TAG="LFTP"		# default value
TNAME="tag"
IS_TAG=1                # dummy value, no check for 'tag'
NO_TAG=1
 SYNTAXS+=([$TNAME]="tag=")
 RETVALS+=([$TNAME]=$NO_TAG)
HASPARAM+=([$TNAME]="N")

DOMAIN="domain"	 	# the name for 'domain'
NO_DOMAIN=10
LOCAL_DOMAIN_TITLE="is local domain ?"			# checks if domain is a local dns domain
LOCAL_DOMAIN_MESAGE="domain is not a local domain !"	# domiain is not a local dns domain
LOCAL_DOMAIN_ERROR=11
 SYNTAXS+=([$DOMAIN]="domain=")
 RETVALS+=([$DOMAIN]=$NO_DOMAIN)
HASPARAM+=([$DOMAIN]="N")

HOST="host"		 # the name for 'host'
NO_HOST=20
HOST_ONLINE_TITLE="host online ?"	# checks if the host is online
HOST_ONLINE_MESSAGE="host not online !"
HOST_ONLINE_ERROR=21
HOST_DNS_TITLE="host in local dns ?"	# checks if the host is in de local dns database, only when domain is known
HOST_DNS_MESSAGE="host not in local dns !"
HOST_DNS_ERROR=22
 SYNTAXS+=([$HOST]="host=")
 RETVALS+=([$HOST]=$NO_HOST)
HASPARAM+=([$HOST]="Y")
CHECK1+=([$HOST_ONLINE_TITLE]=$HOST_ONLINE_MESSAGE)
ERROR1+=([$HOST_ONLINE_TITLE]=$HOST_ONLINE_ERROR)

PORT="port"		# the name for the port parameter
NO_PORT=30
HAS_PORT_TITLE="remote port open ?"		# checks of port open on host
HAS_PORT_MESSAGE="remote port not open !"
HAS_PORT_ERROR=31
LOCAL_PORT_TITLE="local port open ?"		# local host has open port
LOCAL_PORT_MESSAGE="no local port on host !"
LOCAL_PORT_ERROR=32
 SYNTAXS+=([$PORT]="port=")
 RETVALS+=([$PORT]=$NO_PORT)
HASPARAM+=([$PORT]="Y")
CHECK1+=([$HAS_PORT_TITLE]=$HAS_PORT_MESSAGE)
ERROR1+=([$HAS_PORT_TITLE]=$HAS_PORT_ERROR)
# no use for local port at this time

# this is local dir
LOCALDIR="localdir"		# the name for 'localdir'
NO_LOCALDIR=40       		# retval when this value is not set
IS_LOCALDIR_TITLE="value designates a directory ?"
IS_LOCALDIR_MESSAGE="value does not designate a directory !"
IS_LOCALDIR_ERROR=41
EXIST_LOCALDIR_TITLE="directory exist ?"
EXIST_LOCALDIR_MESSAGE="directory does not exist !"
EXIST_LOCALDIR_ERROR=42				# localdir does not exits
NEW_LOCALDIR_TITLE="creating new directory."       # creates this directory
NEW_LOCALDIR_MESSAGE="could not create directory !"
NEW_LOCALDIR_ERROR=43
 SYNTAXS+=([$LOCALDIR]="localdir=")
 RETVALS+=([$LOCALDIR]=$NO_LOCALDIR)
HASPARAM+=([$LOCALDIR]="Y")
# the order of check is important !!
CHECK1+=([$IS_LOCALDIR_TITLE]=$IS_LOCALDIR_MESSAGE)
ERROR1+=([$IS_LOCALDIR_TITLE]=$IS_LOCALDIR_ERROR)
CHECK2+=([$EXIST_LOCALDIR_TITLE]=$EXIST_LOCALDIR_MESSAGE)
ERROR2+=([$EXIST_LOCALDIR_TITLE]=$EXIST_LOCALDIR_ERROR)
CHECK3+=([$NEW_LOCALDIR_TITLE]=$NEW_LOCALDIR_MESSAGE)
ERROR3+=([$NEW_LOCALDIR_TITLE]=$NEW_LOCALDIR_ERROR)

# this is remote dir
REMOTEDIR="remotedir"            # the name for 'remotedir'
NO_REMOTEDIR=50
EXIST_REMOTEDIR_TITLE="remote directory exist ?"     # checks if remotedir exist
EXIST_REMOTEDIR_MESSAGE="remote directory does not exist !"
EXISR_REMOTEDIR_ERROR=51
NEW_REMOTEDIR_TITLE="creating remote directory."     # creates this directory
NEW_REMOTEDIR_MESSGAE="could not create remote directory !"
NEW_REMOTEDIR_ERROR=52
 SYNTAXS+=([$REMOTEDIR]="remotedir=")
 RETVALS+=([$REMOTEDIR]=$NO_REMOTEDIR)
HASPARAM+=([$REMOTEDIR]="Y")
# no checks for remote dir this time

# user
USER="user"		# the name for this parameter
NO_USER=60
 SYNTAXS+=([$USER]="user=")
 RETVALS+=([$USER]=$NO_USER)
HASPARAM+=([$USER]="Y")

# password
PASSWORD="password"	# the name for this parameter
NO_PASSWORD=70
EMPTY_PASSWORD_TITLE="is password empty ?"	# checks if the password can be empty, when user = anonymous
EMPTY_PASSSWORD_MESSAGE="password is empty !"
EMPTY_PASSWORD_ERROR=71
 SYNTAXS+=([$PASSWORD]="password=")
 RETVALS+=([$PASSWORD]=$NO_PASSWORD)
HASPARAM+=([$PASSWORD]="Y")
CHECK1+=([$EMPTY_PASSWORD_TITLE]=$EMPTY_PASSWORD_MESSAGE)
ERROR1+=([$EMPTY_PASSWORD_TITLE]=$EMPTY_PASSWORD_ERROR)

# service
SERVICE="service"       # the name for this parameter
NO_SERVICE=80
 SYNTAXS+=([$SERVICE]="service=")
 RETVALS+=([$SERVICE]=$NO_SERVICE)
HASPARAM+=([$SERVICE]="Y")
# service default value is set at a later time

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
        # if HASTITLE indicates it, check it
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
		$IS_LOCALDIR_TITLE)
                        MES="      ${VALUES[$LOCALDIR]} $TITLE"
                        echoIt
                        # check if value designates a directory
                        WC=$(echo ${VALUES[$LOCALDIR]} | wc -w)
                        if [ ! $WC -eq 1 ]; then
                                MES="'${VALUES[$LOCALDIR]}' $MESSAGE"
                                loggerExit
                        fi
		;;
                $EXIST_LOCALDIR_TITLE)
                        MES="      ${VALUES[$LOCALDIR]} $TITLE"
                        echoIt
                        # check if directory exists
                        if [ ! -d ${VALUES[$LOCALDIR]} ]; then
                                MES="${VALUES[$LOCALDIR]} $MESSAGE"
                                loggerExit
                        fi
                ;;
		$NEW_LOCALDIR_TITLE)
                        MES="      ${VALUES[$LOCALDIR]} $TITLE"
                        echoIt
			# create directory, if not exist
			# then check if directort exist
                        if [ ! -d ${VALUES[$LOCALDIR]} ]; then
                                mkdir ${VALUES[$LOCALDIR]}
                        fi
			# seems 'double check' but create is always last check !!
                        if [ ! -d ${VALUES[$LOCALDIR]} ]; then
                                MES="${VALUES[$LOCALDIR]} $MESSAGE"
                                loggerExit
                        fi
		;;
                $HAS_PORT_TITLE)
			MES="      ${VALUES[$PORT]} $TITLE"
			echoIt
                        nmap ${VALUES[$HOST]} | grep ${VALUES[$PORT]} > /dev/null
                        if [ ! $? -eq 0 ]; then
                                MES="host ${VALUES[$HOST]}:${VALUES[$PORT]} $MESSAGE"
                                loggerExit
                        fi
                ;;
		$EMPTY_PASSWORD_TITLE)
			MES="      ${VALUES[$USER]}:${VALUES[$PASSWORD]} $TITLE"
			echoIt
			# when user is anonymous password can be empty
			if [ -z ${VALUES[$PASSWORD]} ]; then
				if [ ! ${VALUES[$USER]} = "anonymous" ]; then
					MES="${VALUES[$USER]} $MESSAGE"
					loggerExit
				fi
			fi
		;;
        esac
}

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

check3() {
        MES="check3"
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
        echo
        echo "$SCRIPT version $VERSION from $DATE"
        echo
        echo "lftp.sh, used ftp protocol to sync between ftp server and local directory"
        echo "commands are:"
        echo "  --> publish, sync local dir to ftp server"
        echo "  -->  backup, sync ftp server to local dir"
        echo "  -->    show, do nothing, show given parameter values"
        echo "  --> silence, do not echo each action"
        echo "  -->   usage, show this message"
        echo ""
        echo "parameters are:"
        echo "  -->       tag=, the TAG to use for the 'logger' command, see /var/log/syslog"
        echo "  -->      host=, the host providing the FTP service"
        echo "  -->  localdir=, the local directory"
        echo "  --> remotedir=, the remote directory to sync to"
        echo "  -->      user=, the user to connect to the ftp server"
        echo "  -->  password=, the password used by the user, user anonymous has none"
        echo "  -->      port=, the port for the ftp service, default 21"
        echo
        TEMP="lftp.sh silence publish tag='WEBSITE' host='ftp.somehost.somedomain'"
        echo "$TEMP localdir='/data/websites/cursuslinux' remotedir='/public_html' user='theuser' password='password'"
}

# be silent, will only use logger (and problably some difficult to avoid empty lines)
SILENCE=$1

MES="$SCRIPT version $VERSION from $DATE"
logit

lookiPrograms
readCommandLineParameters

# set default values if needed
if [ -z ${VALUES[$TNAME]} ]; then VALUES[$TNAME]="LFTP"; fi
if [ -z ${VALUES[$SERVICE]} ]; then VALUES[$SERVICE]="ftp"; fi
if [ -z ${VALUES[$PORT]} ];  then VALUES[$PORT]=21; fi
# if a tag is given then use it
TAG=${VALUES[$TNAME]}

case $COMMAND in
    # publish files from local dir to ftp server
    publish)
	hasCommandLineParameters
        check1
	check2

	MES="publishing ${VALUES[$LOCALDIR]} to ${VALUES[$HOST]}:${VALUES[$REMOTEDIR]}"
	echoIt

        # remove all backup files first
        clean.sh silence tag=$TAG directory=${VALUES[$LOCALDIR]}

        # do the syncing, from local to host
        FTPURL="ftp://${VALUES[$USER]}:${VALUES[$PASSWORD]}@${VALUES[$HOST]}"
        DELETE="--delete"
        lftp -c "set ftp:list-options -a;
        set ssl:verify-certificate no
        open '$FTPURL';
        lcd ${VALUES[$LOCALDIR]};
        cd ${VALUES[$REMOTEDIR]};
        mirror --reverse $DELETE --verbose "

    ;;
    # sync remote dir from ftp server to local dir
    backup)
        hasCommandLineParameters
	check1
	check2
	check3

        # do the syncing, from host to local
        FTPURL="ftp://${VALUES[$USER]}:${VALUES[$PASSWORD]}@${VALUES[$HOST]}"
        DELETE="--delete"
        lftp -c "set ftp:list-options -a;
        set ssl:verify-certificate no
        open '$FTPURL';
        lcd ${VALUES[$LOCALDIR]};
        cd ${VALUES[$REMOTEDIR]};
        mirror $DELETE --verbose "

    ;;
    show)
        showValues
    ;;
    usage)
        usage
    ;;
    *)  echo "$SCRIPT version $VERSION missing command and parameters"
        usage
    ;;
esac

