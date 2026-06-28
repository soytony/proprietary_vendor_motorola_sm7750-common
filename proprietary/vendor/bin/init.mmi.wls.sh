#!/vendor/bin/sh

PATH=/sbin:/vendor/sbin:/vendor/bin:/vendor/xbin
export PATH

scriptname=${0##*/}

notice()
{
	echo "$*"
	echo "$scriptname: $*" > /dev/kmsg
}

# Globals

wireless_path=
wireless_fw_cmd_path=/sys/class/qcom-battery

setup_permissions()
{

	 chmod 0660 $wireless_path/tx_mode
	 chmod 0660 $wireless_path/wls_input_current_limit
	 chmod 0660 $wireless_path/wlc_fan_speed
	 chmod 0660 $wireless_path/wlc_light_ctl
	 notice "set wireless permission "
	[ -e $wireless_path/tx_mode ] && chown system:system $wireless_path/tx_mode
	[ -e $wireless_path/wlc_fan_speed ] && chown system:system $wireless_path/wlc_fan_speed
	[ -e $wireless_path/wlc_light_ctl ] && chown system:system $wireless_path/wlc_light_ctl
	[ -e $wireless_path/wlc_st_changed ] && chown system:system $wireless_path/wlc_st_changed
	[ -e $wireless_path/wlc_tx_capability ] && chown system:system $wireless_path/wlc_tx_capability
	[ -e $wireless_path/wlc_tx_id ] && chown system:system $wireless_path/wlc_tx_id
	[ -e $wireless_path/wlc_tx_power ] && chown system:system $wireless_path/wlc_tx_power
	[ -e $wireless_path/wlc_tx_sn ] && chown system:system $wireless_path/wlc_tx_sn
	[ -e $wireless_path/wlc_tx_type ] && chown system:system $wireless_path/wlc_tx_type
	[ -e $wireless_path/wls_input_current_limit ] && chown system:system $wireless_path/wls_input_current_limit
	[ -e $wireless_path/tx_mode_vout ] && chown vendor_tcmd:system $wireless_path/tx_mode_vout

}


process_wireless_fw_update()
{
	echo 10000 > $wireless_fw_cmd_path/wireless_fw_update_time_ms
	echo 2 > $wireless_fw_cmd_path/wireless_fw_update
}


# main
notice "wireless sh start"
count=0
max=10
while [ ! -e /sys/class/power_supply/wireless/device ]; do
	sleep 1
	count=$(($count+1))
	if [ $count -gt $max ]; then
		break
	fi
done

if [ -e /sys/class/power_supply/wireless/device ]; then
	wireless_path=/sys/class/power_supply/wireless/device
	setup_permissions
fi

process_wireless_fw_update
