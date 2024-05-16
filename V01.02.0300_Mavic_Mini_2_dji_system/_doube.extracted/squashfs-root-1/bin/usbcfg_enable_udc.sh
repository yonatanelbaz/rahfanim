#!/bin/sh

echo 'usb enable udc'

udc=`ls /sys/class/udc/`
echo "${udc}" > /sys/kernel/config/usb_gadget/g1/UDC


echo 'usb enable udc done'
