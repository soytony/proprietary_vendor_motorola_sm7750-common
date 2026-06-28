#!/system/bin/sh
#
# Copyright (c) 2023, Motorola LLC  All rights reserved.
#

scriptname=${0##*/}

notice()
{
	echo "$*"
	echo "$scriptname: $*" > /dev/kmsg
}

KERNEL_LOGFILE_PREFIX="/mnt/product/logks/dmesglog"
POSTFIX=".log"
LOGCAT_LOGFILE_PREFIX_ROOT="/mnt/product/logks/logcat"

if [ ! -e ${KERNEL_LOGFILE_PREFIX}$POSTFIX ]; then
	exit 0
fi

sleep 3

while [ 1 ]
do
	DMESG_SIZE=`stat -c "%s" $KERNEL_LOGFILE_PREFIX$POSTFIX`
	#notice "dmesg size is $DMESG_SIZE"
	if [ $DMESG_SIZE -gt 5242880 ]; then
		notice "dmesg size $DMESG_SIZE is too large, stop dmesg service"
		stop mmi-bootlog-dmesg
		break
	fi
	if [ -e $KERNEL_LOGFILE_PREFIX$POSTFIX ]; then
		fsync $KERNEL_LOGFILE_PREFIX$POSTFIX
	fi
	if [ -e $KERNEL_LOGFILE_PREFIX$POSTFIX ]; then
		fsync $LOGCAT_LOGFILE_PREFIX_ROOT*
	fi
	fsync /mnt/product/logks
	sleep 5
done

