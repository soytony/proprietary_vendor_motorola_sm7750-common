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

LOGCAT_LOGFILE_PREFIX_ROOT="/mnt/product/logks/logcat"
LOGCAT_LOGFILE_PREFIX_ROOT_TAIL=".log"
LOGCAT_LOGFILE_PREFIX="$LOGCAT_LOGFILE_PREFIX_ROOT$LOGCAT_LOGFILE_PREFIX_ROOT_TAIL"
POSTFIX=""

allow_to_run

while [ ! -e "/mnt/product/logks/lost+found" ]; do
	sleep 1
	notice "logks partition is not mounted, wait to try"
done

/system/bin/logcat -b main,system,crash -f $LOGCAT_LOGFILE_PREFIX$POSTFIX -r 5120 -n 3
