#!/bin/sh

# disable UDC
echo "" > /sys/kernel/config/usb_gadget/g1/UDC

echo "0x001D" > /sys/kernel/config/usb_gadget/g1/idProduct

if [ -f /tmp/EMMC/factory_test/usb_serial ]; then
    ser=$(cat /tmp/EMMC/factory_test/usb_serial)
    echo $ser > /sys/kernel/config/usb_gadget/g1/strings/0x409/serialnumber
fi

# delete old config
rm /sys/kernel/config/usb_gadget/g1/configs/c.1/f1
rm /sys/kernel/config/usb_gadget/g1/configs/c.1/f2
rm /sys/kernel/config/usb_gadget/g1/configs/c.1/f3
rm /sys/kernel/config/usb_gadget/g1/configs/c.1/f4
rm /sys/kernel/config/usb_gadget/g1/configs/c.1/f5

# rename configs
echo "vcom,bulk,adb" > /sys/kernel/config/usb_gadget/g1/configs/c.1/strings/0x409/configuration

# make new config links
ln -s /sys/kernel/config/usb_gadget/g1/functions/acm.0 /sys/kernel/config/usb_gadget/g1/configs/c.1/f1
ln -s /sys/kernel/config/usb_gadget/g1/functions/ffs.bulk /sys/kernel/config/usb_gadget/g1/configs/c.1/f2
ln -s /sys/kernel/config/usb_gadget/g1/functions/ffs.adb /sys/kernel/config/usb_gadget/g1/configs/c.1/f3

adbd_pid=$(pidof adbd)
if [ -z $adbd_pid ]; then
# if adbd is not exist, we asume that adbd & bulk is never been configed, do kill dji_sys to init bulk.
    mount -o mode=0777 -o uid=2000 -o gid=2000 -t functionfs adb /dev/usb-ffs/adb
    mount -o mode=0777 -o uid=2000 -o gid=2000 -t functionfs bulk /dev/usb-ffs/bulk

    bulk &
    adbd &
    sleep 1
fi

udc=`ls /sys/class/udc/`
echo "${udc}" > /sys/kernel/config/usb_gadget/g1/UDC

# delete rndis IP
ifconfig usb0 down
ip -f inet addr delete 192.168.1.3/32 dev usb0

echo 'usb config switch is done'

