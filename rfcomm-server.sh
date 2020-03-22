#!/bin/bash

BLUEZ_FILE="/etc/systemd/system/dbus-org.bluez.service"
BLUEZ_COMP="bluetoothd --compat"
BLUEZ_COMP_SHORT="bluetoothd -C"

SDP_FILE="/var/run/sdp"
SDP_PERM=777

if [ ! -f $BLUEZ_FILE ]; then
	echo $BLUEZ_FILE not found \(no systemd or bluez installed\)\?
	exit 1
fi

if ! grep -q -E "$BLUEZ_COMP|$BLUEZ_COMP_SHORT" "$BLUEZ_FILE"; then
	echo BlueZ is not running in compatibility mode, SDP may be broken
fi

if [ ! -e $SDP_FILE ]; then
	echo $SDP_FILE not found
	exit 1
fi

if [ `stat -c %a $SDP_FILE` != $SDP_PERM ]; then
	echo Setting $SDP_FILE permissions to $SDP_PERM
	chmod $SDP_PERM $SDP_FILE
else
	echo $SDP_FILE already has $SDP_PERM permissions set
fi

UUID="0x1101"

rfcomm_channel() {
	echo $()
}

if ! sdptool browse --uuid $UUID local | grep -q $UUID; then
	echo No Serial Port records found, adding new SP record
	sdptool add SP || { echo Failed to add new SP record; exit 1; }
fi

CHANNEL=$(sdptool browse local | grep -A4 $UUID | awk 'NR == 5 {print $2};')
echo Serial Port record found with channel $CHANNEL

echo Powering on hci0
hciconfig hci0 up
hciconfig hci0 piscan

# TODO: run fossbot-core with channel $CHANNEL

