#!/bin/sh

wlan0_ip=192.168.2.1

fail_msg="[ ${0##*/} _test_fail ]"

ping $wlan0_ip -c 2 1>/dev/null 2>&1

if [ $? != 0 ]; then
    echo "wlan0 does not exist, network $fail_msg"
    exit 1
fi

echo "wlan0 exists, network test success"
exit 0
