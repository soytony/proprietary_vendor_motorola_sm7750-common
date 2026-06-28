#!/system/bin/sh
#
# Copyright (c) 2023, Motorola LLC  All rights reserved.
#

scriptname=${0##*/}

debug()
{
	echo "$*"
}

notice()
{
	echo "$*"
	echo "$scriptname: $*" > /dev/kmsg
}

allow_to_run()
{
	secure_hw=$(getprop ro.boot.secure_hardware)
	build_type=$(getprop ro.build.type)
	cid=$(getprop ro.boot.cid)

	if [ x"$secure_hw" == x"1" ] && [ x"$build_type" == x"user" ] && [ x"$cid" != x"0x0" ] && [ x"$cid" != x"0x0000" ]; then
		apdp_state=$(getprop ro.boot.device_apdp_state)
		aplogd_state=$(getprop ro.boot.force_aplogd_enable)
		if [ "$apdp_state" == "1" ] || [ "$aplogd_state" == "1" ]; then
			notice "secure_hw=$secure_hw build_type=$build_type cid=$cid apdp_state=$apdp_state aplogd_state=$aplogd_state"
			return
		fi
		exit 0
	fi
}

KERNEL_LOGFILE_PREFIX="/mnt/product/logks/dmesglog"
LOGCAT_LOGFILE_PREFIX_ROOT="/mnt/product/logks/logcat"
BACKUP_LOGFILE_PREFIX="/mnt/product/logks/backup_log"
POSTFIX=".log"

# mv files.x-1.tar.gz to files.x.tar.gz
# tar czfP file.1.tar.gz demsglog.log* logcat.log*
mv_files()
{
	if [ -z "$1" ]; then
	  echo "No file name!"
	  return
	fi
	if [ -z "$2" ]; then
	  LAST_FILE=3
	else
	  LAST_FILE=$2
	fi

	#echo $1 $2 $LAST_FILE
	i=$LAST_FILE
	while [ $i -gt 0 ]; do
	  prev=$(($i-1))
	  if [ -e "$1.$prev.tar.gz" ]; then
#	    echo mv $1.$prev $1.$i
	    mv $1.$prev.tar.gz $1.$i.tar.gz
	  fi
	  i=$(($i-1))
	done

	if [ -e ${KERNEL_LOGFILE_PREFIX}${POSTFIX} ]; then
	  #echo mv $1 $1.1
	  LOGCAT_FILE_NAME=""
	  if [ -e ${LOGCAT_LOGFILE_PREFIX_ROOT}${POSTFIX} ]; then
		LOGCAT_FILE_NAME=${LOGCAT_LOGFILE_PREFIX_ROOT}${POSTFIX}*
	  fi
	  tar czfP $1.1.tar.gz  ${KERNEL_LOGFILE_PREFIX}${POSTFIX}* ${LOGCAT_FILE_NAME}
	  rm -rf ${KERNEL_LOGFILE_PREFIX}${POSTFIX}* ${LOGCAT_FILE_NAME}
	fi
}

allow_to_run

while [ ! -e "/mnt/product/logks/lost+found" ]; do
	sleep 1
	notice "logks partition is not mounted, wait to try"
done

ls ${BACKUP_LOGFILE_PREFIX}.[0-9]*.tar.gz
if [ $? -eq 0 ]; then
	LOGKS_AVA_SIZE=`df | grep logks |  tr -s ' ' | cut -d ' ' -f 4`
	NUM_OF_LOG=`ls ${BACKUP_LOGFILE_PREFIX}.[0-9]*.tar.gz -l | wc -l`
	notice "current log count is: ${NUM_OF_LOG}, free space is: ${LOGKS_AVA_SIZE}"

	if [ ${LOGKS_AVA_SIZE} -gt 32000 ]; then
		NUM_OF_LOG=$((NUM_OF_LOG+1))
	fi
else
	NUM_OF_LOG=1
fi
notice "save number of log: ${NUM_OF_LOG}"

if [ -e ${KERNEL_LOGFILE_PREFIX}$POSTFIX ]; then
	mv_files $BACKUP_LOGFILE_PREFIX ${NUM_OF_LOG}
fi



dmesg -w > ${KERNEL_LOGFILE_PREFIX}$POSTFIX

