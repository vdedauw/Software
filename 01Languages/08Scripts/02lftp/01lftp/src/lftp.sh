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
# NOPORT      noport=true            do not nmap remote host if 'true'	    false
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
# 0.1.8 isexecutable.sh implemented
# 0.2.3 reviewed

SCRIPT="lftp.sh"
VERSION="0.2.3"
DATE="2019/06/08"
MES=" "

RETVAL=0
NO_ISEXECUTABLE=-1
NO_PROGRAM=-2
DO_EXIT="true"

# define arrays
OPTIONS=
COMMANDS=("publish" "backup" "show" "checks" "usage")

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
# ID 1,2,3,4 are not used as check, but as 'check serie' identifier, see above
TAG_ID=5
   NAMES[$TAG_ID]="LFTP"
  VALUES[$TAG_ID]="false"
 SYNTAXS[$TAG_ID]="tag="

# the command for this script
# origin command line first of second parameter, 'command=' not used !!
COMMAND_ID=10
   NAMES[$COMMAND_ID]="COMMAND"
  VALUES[$COMMAND_ID]="false"
 SYNTAXS[$COMMAND_ID]="command="

# the domain to communicate within
# origin ??? not used at this time
DOMAIN=20
   NAMES[$DOMAIN]="DOMAIN"
  VALUES[$DOMAIN]="hasnot"
 SYNTAXS[$DOMAIN]="domain="
# checks if domain is a local dns domain
LOCAL_DOMAIN=21
VALUES[$LOCAL_DOMAIN]="false"
#CHECK1[$LOCAL_DOMAIN]=$LOCAL_DOMAIN

# the host to communicate within
# origin: command line parameter
HOST=30
   NAMES[$HOST]="HOST"
  VALUES[$HOST]="false"
 SYNTAXS[$HOST]="host="
# checks if the host is online
HOST_ONLINE=31
 NAMES[$HOST_ONLINE]="HOST_ONLINE"
VALUES[$HOST_ONLINE]="false"
CHECK1[$HOST_ONLINE]=$HOST_ONLINE
# checks if the host is in de local dns database, only when domain is known
HOST_LOCAL_DOMAIN=32
 NAMES[$HOST_LOCAL_DOMAIN]="HOST_LOCAL_DOMAIN"
VALUES[$HOST_LOCAL_DOMAIN]="false"
#CHECK1[$HOST_LOCAL_DOMAIN]=$HOST_LOCAL_DOMAIN

# the name for the port parameter
# origin: command line parameter
PORT=40
   NAMES[$PORT]="PORT"
  VALUES[$PORT]=21
 SYNTAXS[$PORT]="port="
# indicates that the port cannot be checked, because remote host does not accecpt nmap
NO_PORT=41
   NAMES[$NO_PORT]="NOPORT"
  VALUES[$NO_PORT]="false"
 SYNTAXS[$NO_PORT]="noport="
# checks if the host is online
REMOTE_PORT=42
 NAMES[$REMOTE_PORT]="REMOTE_PORT"
VALUES[$REMOTE_PORT]="false"
CHECK1[$REMOTE_PORT]=$REMOTE_PORT
# checks if the host is in de local dns database, only when domain is known
LOCAL_PORT=43
 NAMES[$LOCAL_PORT]="LOCAL_PORT"
VALUES[$LOCAL_PORT]="false"
#CHECK1[$LOCAL_PORT]=$LOCAL_PORT


# this is local dir
# origin: command line paramater
LOCAL_DIR=50
   NAMES[$LOCAL_DIR]="LOCAL_DIR"
  VALUES[$LOCAL_DIR]="false"
 SYNTAXS[$LOCAL_DIR]="localdir="
# check local_dir designates directory
IS_DIRECTORY=51
 NAMES[$IS_DIRECTORY]="IS_DIRECTORY"
VALUES[$IS_DIRECTORY]="false"
CHECK1[$IS_DIRECTORY]=$IS_DIRECTORY
# create local-dir directory, needed for the backup function
DIRECTORY_CREATE=52
 NAMES[$DIRECTORY_CREATE]="DIRECTORY_CREATE"
VALUES[$DIRECTORY_CREATE]="false"
CHECK1[$DIRECTORY_CREATE]=$DIRECTORY_CREATE
# check if directory exist
DIRECTORY_EXIST=53
 NAMES[$DIRECTORY_EXIST]="DIRECTORY_EXIST"
VALUES[$DIRECTORY_EXIST]="false"
CHECK1[$DIRECTORY_EXIST]=$DIRECTORY_EXIST

# this is remote dir
# origin: command line paramater
REMOTE_DIR=60
   NAMES[$REMOTE_DIR]="REMOTE_DIR"
  VALUES[$REMOTE_DIR]="false"
 SYNTAXS[$REMOTE_DIR]="remotedir="
# check is user designates a possible user
IS_REMOTE_DIR=61
 NAMES[$IS_REMOTE_DIR]="IS_REMOTE_DIR"
VALUES[$IS_REMOTE_DIR]="false"
CHECK1[$IS_REMOTE_DIR]=$IS_REMOTE_DIR

# the user to login in the remote ftp server
# origin: command line paramater
USER=70
   NAMES[$USER]="USER"
  VALUES[$USER]="false"
 SYNTAXS[$USER]="user="
# check is user designates a possible user
IS_USER=71
 NAMES[$IS_USER]="IS_USER"
VALUES[$IS_USER]="false"
CHECK1[$IS_USER]=$IS_USER

# the password to login in the remote ftp server
# origin: command line paramater
PASSWORD=80
   NAMES[$PASSWORD]="PASSWORD"
  VALUES[$PASSWORD]="false"
 SYNTAXS[$PASSWORD]="password="
# check is user designates a possible user
IS_PASSWORD=81
 NAMES[$IS_PASSWORD]="IS_PASSWORD"
VALUES[$IS_PASSWORD]="false"
CHECK1[$IS_PASSWORD]=$IS_PASSWORD

# the ftp service
# origin: command line paramater
SERVICE=90
   NAMES[$SERVICE]="SERVICE"
  VALUES[$SERVICE]="ftp"
 SYNTAXS[$SERVICE]="service="
# check if the service is enabled
HAS_SERVICE=91
 NAMES[$HAS_SERVICE]="HAS_SERVICE"
VALUES[$HAS_SERVICE]="false"
#CHECK1[$HAS_SERVICE]=$HAS_SERVICE

# value used to the isSingleWord method
SINGLE_WORD=100
   NAMES[$SINGLE_WORD]="SINGLE_WORD"
  VALUES[$SINGLE_WORD]="false"
# checks if the single word value is a single word
IS_SINGLE_WORD=101
   NAMES[$IS_SINGLE_WORD]="SINGLE_WORD"
  VALUES[$IS_SINGLE_WORD]="false"

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
			VALUES[$COMMAND_ID]=$PARAMETER
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
                if [ $VALUE = "false" ]; then
                        MES="command line parameter '$NAME' has no value"
                        loggerExit
                fi
                MES="   ($ID) ($NAME) has value ${VALUES[$ID]}"
                echoIt
        done
        MES=""
        echoIt
}

isSingleWord() {
	if [ ${VALUES[$IS_SINGLE_WORD]} =  "false" ]; then
		# check if value designates a single word, not a collection (like in '*')
        	WC=$(echo ${VALUES[$SINGLE_WORD]} | wc -w)
	        if [ $WC -eq 1 ]; then
			VALUES[$IS_SINGLE_WORD]="true"
        	fi
	fi
}

checkParameters() {
        case $ID in

		# checks if the host is online
		$HOST_ONLINE)
			if [ $VALUE = "false" ]; then
				MES="      ${VALUES[$HOST]} online ?"
				echoIt
                	        ping -c 1 ${VALUES[$HOST]} > /dev/null
                        	if [ ! $? -eq 0 ]; then
                                	MES="${VALUES[$HOST]} is not online"
	                                loggerExit
        	                fi
				MES="      ${VALUES[$HOST]} is online"
				echoIt
				VALUES[$HOST_ONLINE]="true"
			fi
                ;;

		# checks if the remote host has the open port
                $REMOTE_PORT)
			if [ $VALUE = "false" ]; then
	                        MES="      host ${VALUES[$HOST]} has ${VALUES[$PORT]} open ?"
        	                echoIt
				if [ ${VALUES[$NO_PORT]} = "true" ]; then
					MES="      nmap checking is disables in this run"
					echoIt
				else
	                	        nmap ${VALUES[$HOST]} | grep ${VALUES[$PORT]} > /dev/null
        	                	if [ ! $? -eq 0 ]; then
                	                	MES="${VALUES[$HOST]}:${VALUES[$PORT]} not open"
	                	                loggerExit
        	                	fi
					VALUES[$REMOTE_PORT]="true"
					MES="      host ${VALUES[$HOST]} has ${VALUES[$PORT]} open !"
					echoIt
				fi
			fi
                ;;

		$IS_DIRECTORY)
			if [ $VALUE = "false" ]; then
	                        MES="      ${VALUES[$LOCAL_DIR]} designates a directory ?"
        	                echoIt
				VALUES[$SINGLE_WORD]=${VALUES[$LOCAL_DIR]}
				VALUES[$IS_SINGLE_WORD]="false"
				isSingleWord
				if [ ${VALUES[$IS_SINGLE_WORD]} = "false" ]; then
					MES="${VALUES[$LOCAL_DIR]} does not designate a directory"
					loggerExit
				fi
				VALUES[$IS_DIRECTORY]="true"
				MES="      ${VALUES[$LOCAL_DIR]} designates a directory !"
                                echoIt
			fi
		;;

                $DIRECTORY_EXIST)
                        if [ $VALUE = "false" ]; then
                                # check if directory exists,
                                MES="      check directory ${VALUES[$LOCAL_DIR]} exist"
                                echoIt
                                if [ ! -d ${VALUES[$MOUNT]} ]; then
                                        MES="${VALUES[$LOCAL_DIR]} does not exist"
                                        loggerExit
                                fi
                                VALUES[$DIRECTORY_EXIST]="true"
                                MES="         ${VALUES[$LOCAL_DIR]} directory exist"
                                echoIt
                        fi
                ;;

                $DIRECTORY_CREATE)
                        if [ $VALUE = "false" ]; then
                                # create directory
                                MES="      create directory ${VALUES[$LOCAL_DIR]}"
                                echoIt
                                if [ ! -d ${VALUES[$LOCAL_DIR]} ]; then
                                        mkdir ${VALUES[$LOCAL_DIR]} > /dev/null 2> /dev/null
                                        if [ ! -d ${VALUES[$LOCAL_DIR]} ]; then
                                                MES="could not create directory ${VALUES[$LOCAL_DIR]}"
                                                loggerExit
                                        fi
                                        VALUES[$DIRECTORY_LOCAL_DIR]="true"
                                        MES="         ${VALUES[$LOCAL_DIR]} directory created"
                                        echoIt
                                fi
                        fi
                ;;

		$IS_REMOTE_DIR)
			if [ $VALUE = "false" ]; then
                               MES="      ${VALUES[$REMOTE_DIR]} designates a directory ?"
                                echoIt
                                VALUES[$SINGLE_WORD]=${VALUES[$REMOTE_DIR]}
                                VALUES[$IS_SINGLE_WORD]="false"
                                isSingleWord
                                if [ ${VALUES[$IS_SINGLE_WORD]} = "false" ]; then
                                        MES="${VALUES[$REMOTE_DIR]} does not designate a directory"
                                        loggerExit
                                fi
                                MES="      ${VALUES[$REMOTE_DIR]} designates a directory"
                                echoIt
				VALUES[$IS_REMOTE_DIR]="true"
			fi
		;;

                $IS_USER)
                        if [ $VALUE = "false" ]; then
                               MES="      ${VALUES[$USER]} designates a single user ?"
                                echoIt
                                VALUES[$SINGLE_WORD]=${VALUES[$USER]}
                                VALUES[$IS_SINGLE_WORD]="false"
                                isSingleWord
                                if [ ${VALUES[$IS_SINGLE_WORD]} = "false" ]; then
                                        MES="${VALUES[$USER]} does not designates a single user"
                                        loggerExit
                                fi
                                MES="      ${VALUES[$USER]} designates a single user"
                                echoIt
                                VALUES[$IS_USER]="true"
                        fi
                ;;

		$IS_PASSWORD)
			if [ $VALUE = "false" ]; then
				MES="      ${VALUES[$PASSWORD]} designates a single password ?"
				echoIt
                                # when user is anonymous password can be empty
                                if [ -z ${VALUES[$PASSWORD]} ]; then
                                        if [ ! ${VALUES[$USER]} = "anonymous" ]; then
                                                MES="empty password with user ${VALUES[$USER]} not allowed"
                                                loggerExit
                                        fi
                                else
	                                VALUES[$SINGLE_WORD]=${VALUES[$PASSWORD]}
        	                        VALUES[$IS_SINGLE_WORD]="false"
                	                isSingleWord
                        	        if [ ${VALUES[$IS_SINGLE_WORD]} = "false" ]; then
                                	        MES="${VALUES[$USER]} does not designates a single password"
                                        	loggerExit
	                                fi
				fi
				MES="      password ok !"
				echoIt
				VALUES[$IS_PASSWORD]="true"
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
        echo
        echo "$SCRIPT version $VERSION from $DATE"
        echo
        echo "lftp.sh, used ftp protocol to sync between ftp server and local directory"
        echo "commands are:"
        echo "  --> publish, sync local dir to ftp server"
        echo "  -->  backup, sync ftp server to local dir"
        echo "  -->    show, do nothing, show given parameter values"
	echo "  -->  checks, shows check order"
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
	echo "  -->    noport=, when set 'true' as in noport=true, no nmap port checking will be done"
        echo
        TEMP="lftp.sh silence publish tag='WEBSITE' host='ftp.somehost.somedomain'"
        echo "$TEMP localdir='/data/websites/cursuslinux' remotedir='/public_html' user='theuser' password='password'"
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

# be silent, will only use logger (and problably some difficult to avoid empty lines)
SILENCE=$1
if [ -z $SILENCE ]; then SILENCE="---"; fi
if [ $SILENCE = "silence" ]; then shift; fi
if [ $SILENCE = "SILENCE" ]; then shift; fi
PARAMS=("$@")

TAG="LFTP"
MES="$SCRIPT version $VERSION from $DATE"
logit

if [ ! -x /usr/bin/isexecutable.sh ]; then
        RETVAL=$NO_ISEXECUTABLE
        MES="isexecutable not installed"
        loggerExit
fi

isexecutable.sh silence $TAG "lftp" "nmap" "ping" "clean.sh"
if [ ! $? -eq 0 ]; then
        RETVAL=$NO_PROGRAM
        MES="one or more programs not installed"
        loggerExit
fi
readCommandLineParameters

# set default values if needed
if [ -z ${VALUES[$PORT]} ];  then VALUES[$PORT]=21; fi
# if a tag is given then use it
TAG=${VALUES[$TNAME]}

echo "command = $COMMAND"

case $COMMAND in
    # publish files from local dir to ftp server
    publish)
	hasCommandLineParameters
        CHECKS=(${CHECK1[@]})
        checks
	MES="publishing ${VALUES[$LOCALDIR]} to ${VALUES[$HOST]}:${VALUES[$REMOTEDIR]}"
	echoIt

        # remove all backup files first
        clean.sh silence tag=$TAG directory=${VALUES[$LOCAL_DIR]}

        # do the syncing, from local to host
        FTPURL="ftp://${VALUES[$USER]}:${VALUES[$PASSWORD]}@${VALUES[$HOST]}"
        DELETE="--delete"
        lftp -c "set ftp:list-options -a;
        set ssl:verify-certificate no
        open '$FTPURL';
        lcd ${VALUES[$LOCAL_DIR]};
        cd ${VALUES[$REMOTE_DIR]};
        mirror --reverse $DELETE --verbose "

    ;;
    # sync remote dir from ftp server to local dir
    backup)
        hasCommandLineParameters
        CHECKS=(${CHECK1[@]})
        checks

        # do the syncing, from host to local
        FTPURL="ftp://${VALUES[$USER]}:${VALUES[$PASSWORD]}@${VALUES[$HOST]}"
        DELETE="--delete"
        lftp -c "set ftp:list-options -a;
        set ssl:verify-certificate no
        open '$FTPURL';
        lcd ${VALUES[$LOCAL_DIR]};
        cd ${VALUES[$REMOTE_DIR]};
        mirror $DELETE --verbose "

    ;;
    show)
	disableExitChecks
        showValues
    ;;
    checks)
	disableExitChecks
        CHECKS=(${CHECK1[@]})
        showChecks
        CHECKS=(${CHECK2[@]})
        showChecks
        CHECKS=(${CHECK3[@]})
        showChecks
        CHECKS=(${CHECK4[@]})
	showChecks
    ;;
    usage)
        usage
    ;;
    *)  echo "$SCRIPT version $VERSION missing command and parameters"
        usage
    ;;
esac

