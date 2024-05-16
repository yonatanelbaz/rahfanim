
/usr/bin/fastboot flash cmpu_otp /tmp/encrypt/otp.sec
[ $? -ne 0 ] && echo "cmpu otp failed" && exit 4

/usr/bin/fastboot reboot
[ $? -ne 0 ] && echo "reboot failed" && exit 5

rm /tmp/service_control

echo 19 > /sys/class/gpio/export
echo low > /sys/class/gpio/gpio19/direction
sleep 1
echo high > /sys/class/gpio/gpio19/direction

exit 0
