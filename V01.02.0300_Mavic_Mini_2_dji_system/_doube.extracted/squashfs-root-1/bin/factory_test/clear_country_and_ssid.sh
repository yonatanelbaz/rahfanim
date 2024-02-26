#! /bin/sh
echo dji > /tmp/service_control
killall dji_network
wl down
ifconfig wlan0 down
sleep 1
rmmod bcmdhd
echo "remove the user_cfg.conf"
rm -rf /tmp/EMMC/wireless/wifi/user_cfg.conf
sync
sleep 2
exit 0