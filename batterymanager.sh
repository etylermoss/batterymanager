#!/bin/bash
charge=''
charging_var=''
discharging_var=''
activeuser=$(loginctl list-sessions --no-legend | awk '{ print $3}')
userbool='0'

# User variable defaults.
allowedusers=()
charging_tracker='/tmp/batterymanager.1.tmp'
percent_tracker='/tmp/batterymanager.2.tmp'
charging_threshold='20'
discharging_threshold='35'
discharging_critical_threshold='7'
discharging_critical_command='systemctl hibernate'
charging_below_keyboard='20'
charging_below_screen='40'
charging_above_keyboard='60'
charging_above_screen='80'
discharging_below_keyboard='0'
discharging_below_screen='17'
discharging_above_keyboard='0'
discharging_above_screen='32'
screendir='/sys/class/backlight/acpi_video0/'
batterydir='/sys/class/power_supply/BAT0/'
capacity=$(cat $batterydir"energy_full")
current=$(cat $batterydir"energy_now")
percentage=$((current*100/capacity + 1))

. /etc/batterymanager.conf

for user in "${allowedusers[@]}" ; do
	if [ "$user" = "$activeuser" ] ; then
		userbool='1'
	fi
done
if [ "$userbool" = '0' ] ; then exit ; fi

if acpi -a | grep on-line &>/dev/null ; then charge='charging' ; else charge='discharging' ; fi

if [ "$percentage" -lt "$charging_threshold" ] ; then charging_var='cinthreshold' ; else charging_var='coutthreshold' ; fi

if [ "$percentage" -lt "$discharging_threshold" ] ; then discharging_var='dinthreshold' ; else discharging_var='doutthreshold' ; fi

if [ "$charge" = 'discharging' ] && [ "$percentage" -lt "$discharging_critical_threshold" ] ; then eval "$discharging_critical_command" ; fi

set_screen () {
	a="$(echo "$1"/100 | bc -l)"
	b="$(cat "$screendir"'max_brightness')"
	c="$(echo "$a"*"$b" | bc)"
	echo $(echo "$c/1" | bc) > "$screendir"'brightness'
}

set_keybd () {
	dbus-send --system --type=method_call  --dest="org.freedesktop.UPower" "/org/freedesktop/UPower/KbdBacklight" "org.freedesktop.UPower.KbdBacklight.SetBrightness" int32:"$1" 
}

if [ -r "$charging_tracker" ] && [ -s "$charging_tracker" ] && [ -r "$percent_tracker" ] && [ -s "$percent_tracker" ] && [ ! "$1" = -f ]  ; then
	# Tracker files exist
	if [ "$(cat "$charging_tracker")" = "$charge" ] && [ "$(cat "$percent_tracker")" = "$charging_var" ] || [ "$(cat "$percent_tracker")" = "$discharging_var" ] ;
	then
		# No change in state
		exit
	fi
fi

if [ "$charge" = 'charging' ] ; then
	# Charging
	echo "charging" > "$charging_tracker"
	if [ "$charging_var" = 'cinthreshold' ] ; then
		echo "cinthreshold" > "$percent_tracker"
		set_keybd "$charging_below_keyboard" && set_screen "$charging_below_screen"
		exit
	else
		echo "coutthreshold" > "$percent_tracker"
		set_keybd "$charging_above_keyboard" && set_screen "$charging_above_screen"
		exit
	fi
else
	# Discharging
	echo "discharging" > "$charging_tracker"
	if [ "$discharging_var" = 'dinthreshold' ] ; then
		echo "dinthreshold" > "$percent_tracker"
		set_keybd "$discharging_below_keyboard" && set_screen "$discharging_below_screen"
		exit
	else
		echo "doutthreshold" > "$percent_tracker"
		set_keybd "$discharging_above_keyboard" && set_screen "$discharging_above_screen"
		exit
	fi
fi

