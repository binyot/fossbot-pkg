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

if sdptool browse --uuid $UUID local | grep -q $UUID; then
	echo Serial Port record found
else
	echo No Serial Port records found, adding new SP record
	sdptool add SP || { echo Failed to add new SP record; exit 1; }
fi

RFCOMM_FILE="/dev/rfcomm0"

if [ -e $RFCOMM_FILE ]; then
	echo File $RFCOMM_FILE already exists
	exit 1
fi

echo Launching rfcomm watcher in raw mode for $RFCOMM_FILE

rfcomm --raw watch $RFCOMM_FILE

