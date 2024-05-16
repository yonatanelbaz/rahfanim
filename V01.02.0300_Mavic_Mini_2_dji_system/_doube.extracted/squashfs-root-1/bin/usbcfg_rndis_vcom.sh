#!/bin/sh

# disable UDC
echo "" > /sys/kernel/config/usb_gadget/g1/UDC

echo "0x001E" > /sys/kernel/config/usb_gadget/g1/idProduct

# delete old config
rm /sys/kernel/config/usb_gadget/g1/configs/c.1/f1
rm /sys/kernel/config/usb_gadget/g1/configs/c.1/f2
rm /sys/kernel/config/usb_gadget/g1/configs/c.1/f3
rm /sys/kernel/config/usb_gadget/g1/configs/c.1/f4
rm /sys/kernel/config/usb_gadget/g1/configs/c.1/f5

# rename configs
echo "rndis,vcom" > /sys/kernel/config/usb_gadget/g1/configs/c.1/strings/0x409/configuration

# make new config links
ln -s /sys/kernel/config/usb_gadget/g1/functions/rndis.0 /sys/kernel/config/usb_gadget/g1/configs/c.1/f1
ln -s /sys/kernel/config/usb_gadget/g1/functions/acm.0 /sys/kernel/config/usb_gadget/g1/configs/c.1/f2

#enable UDC
udc=`ls /sys/class/udc/`
echo "${udc}" > /sys/kernel/config/usb_gadget/g1/UDC

# config rndis
ifconfig usb0 192.168.1.3 up
tcpsvd -vE 0.0.0.0 21 ftpd -w /tmp/SD0 &
tcpsvd -vE 0.0.0.0 22 ftpd -w /tmp/EMMC &
#tcpsvd -vE 0.0.0.0 23 ftpd -w /tmp/blackbox &
dji_ftpd &

busybox udhcpd /etc/udhcpd_rndis.conf &

echo 'usb config switch is done'

