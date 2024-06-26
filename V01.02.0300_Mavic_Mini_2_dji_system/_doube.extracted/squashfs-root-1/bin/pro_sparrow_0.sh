#!/bin/sh
function kill_process()
{
    keyword=$1
    oldifs="$IFS"
    IFS=$'\n'
    for line in `ps | grep $keyword`
    do
        echo $line | busybox grep grep
        if [ $? -eq 0 ]; then
            continue
        fi
        pid=`echo $line | awk '{print $1}'`
        echo "try to kill $line"
        kill -9 $pid
    done
    IFS=$oldifs
}

# stop sdr agent
echo sdrs_agent > /tmp/service_control
kill_process sdrs_agent

# kill modem_load_s1 script
kill_process modem_load_s1

# kill brload
kill_process brload

# kill fastboot
kill_process fastboot

# reboot slave chip
echo 19 > /sys/class/gpio/export
echo low > /sys/class/gpio/gpio19/direction
sleep 1
echo high > /sys/class/gpio/gpio19/direction

/usr/bin/brload /tmp/encrypt/bootarea.img
[ $? -ne 0 ] && echo "loading bootarea failed" && exit 1

/usr/bin/fastboot flash cmpu_pro /tmp/encrypt/bootarea.img
[ $? -ne 0 ] && echo "change production failed" && exit 6

/usr/bin/fastboot reboot
[ $? -ne 0 ] && echo "reboot failed" && exit 5

rm /tmp/service_control

echo 19 > /sys/class/gpio/export
echo low > /sys/class/gpio/gpio19/direction
sleep 1
echo high > /sys/class/gpio/gpio19/direction

exit 0
