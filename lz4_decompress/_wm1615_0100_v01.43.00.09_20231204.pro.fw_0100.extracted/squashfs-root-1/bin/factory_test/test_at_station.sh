#!/bin/sh
if [ -z "$1" -o -z "$2" ]
then
    echo "Usage: test_at_station.sh <thread> <qrcode>"
    exit 1
fi

thread=$1
param=$2
echo "thread=$thread"
echo "qrcode=$param"
log_name=at_station.log
log_path=/tmp/blackbox/log/autotest/
mkdir -p $log_path
echo "log path= $log_path$log_name"
/usr/bin/autotest $thread $param > $log_path$log_name 2>&1

if [ $? != 0 ]
then
    echo "at <$thread> <$param> test error"
    exit 1
fi
echo "at <$thread> <$param> test success"
exit 0
