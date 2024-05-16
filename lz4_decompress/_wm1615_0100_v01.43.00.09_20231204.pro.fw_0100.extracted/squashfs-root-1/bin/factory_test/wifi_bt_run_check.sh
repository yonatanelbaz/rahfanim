#! /bin/sh

param=$1
# Parameters validation
if [ -z $param ]
then
    echo "Usage"
    echo "wifi_bt_run_check.sh <wifi / bt>"
    exit 1
fi

if [ is$param = is"wifi" ]; then
    echo "wifi run check begin"
    if [ `ps | busybox grep -v grep | busybox grep -c hostapd` -gt 0 ]; then
        echo "hostapd run succ"
        exit 0
    else
        echo "hostapd run fail"
        exit 1
    fi
elif [ is$param = is"bt" ]; then
    echo "bt run check begin"
    if [ `ps | busybox grep -v grep | busybox grep -c bsa_server` -gt 0 ]; then
        echo "bsa_server run succ"
        exit 0
    else
        echo "bsa_server run fail"
        exit 1
    fi
else
    echo "invalid parameter, $param"
    exit 1
fi
