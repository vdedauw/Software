#!/bin/bash
#
# Programmer: De Dauw Valentijn
#       Date: 2016/10/08
#     Target: mounting the ch3snas nfs volume, data
#      Usage: data.sh command
#
# commands are:
#    mount, mount the data volume
#  unmount, unmount the data volume
#
# History
# 0.0.1 creation
# 0.0.2 added silence
# 0.0.3 checked, error in echoIt()

TAG=DATA
SCRIPT="data.sh"
DATE="2019/05/06"
VERSION="0.0.2"
MES=" "

NFSHOST=ch3snas
HOSTS=/var/lib/bind/de-dauw.eu.hosts
NFSMOUNT=/data
NFSPORT=2049
NFSEXPORT=/mnt/HD_a2/data
SIZE=1,8T

RETVAL=0
NO_MOUNT=1

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

COMMAND=$1
SILENCE=$2

# commands are:
#    mount, mount the NASs exported volume
#  unmount, unmount the NASs exported volume

PROGRAMS=("mount.sh" "showmount")
for PROGRAM in "${PROGRAMS[@]}"
do
        lookiProgram
done
echo

MES="version $VERSION from $DATE command=$1"
logit
MES=""
echoIt

case $COMMAND in
  mount)
	mount.sh $SILENCE tag="DATA" nfsHost=$NFSHOST nfsExport=$NFSEXPORT nfsMount=$NFSMOUNT nfsPort=$NFSPORT nfsSize=$SIZE
	if [ ! $? -eq 0 ]; then exit; fi
	MES="$NFSHOST:$NFSEXPORT mounted on $NFSMOUNT"
  ;;
  unmount)
   	sudo umount -l $NFSMOUNT
	MES="unmounted $NFSMOUNT"
	logit
  ;;
  show)
	showmount -e $NFSHOST
  ;;
  *)
   echo "usage $SCRIPT [command]"
   echo
   echo "Mounts $NFSHOST:$NFSEXPORT on $NFSMOUNT"
   echo "Commands are:"
   echo "  mount, mount $NFSHOST:$NFSEXPOR on $NFSMOUNT"
   echo "unmount, unmount $NFSMOUNT"
   echo "   show, showmount $NFSHOST"
  ;;
esac

