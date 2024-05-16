#!/bin/sh

echo 'usb engineering config is running'

#modprobe ehci-ambarella
#modprobe ohci-hcd
#modprobe cdc-acm

chekc_if_need_config=$(lsmod | grep ambarella_udc)
if [ -n "$chekc_if_need_config" ]; then
    ## no need to reconfig USB configfs
    echo "no need to reconfig USB configfs"
    exit 0
fi

modprobe ambarella_udc

mount -t configfs none /sys/kernel/config
mkdir /dev/usb-ffs/
mkdir /dev/usb-ffs/bulk
mkdir /dev/usb-ffs/adb

mkdir /sys/kernel/config/usb_gadget/g1
#cd g1
echo "0x2CA3" > /sys/kernel/config/usb_gadget/g1/idVendor
echo "0x001D" > /sys/kernel/config/usb_gadget/g1/idProduct
mkdir /sys/kernel/config/usb_gadget/g1/strings/0x409

if [ -f /tmp/EMMC/factory_test/usb_serial ]; then
    ser=$(cat /tmp/EMMC/factory_test/usb_serial)
    echo $ser > /sys/kernel/config/usb_gadget/g1/strings/0x409/serialnumber
else
    echo "123456789ABCDEF" > /sys/kernel/config/usb_gadget/g1/strings/0x409/serialnumber
fi

echo "DJI" > /sys/kernel/config/usb_gadget/g1/strings/0x409/manufacturer
echo "WM160" > /sys/kernel/config/usb_gadget/g1/strings/0x409/product

mkdir /sys/kernel/config/usb_gadget/g1/functions/rndis.0
mkdir /sys/kernel/config/usb_gadget/g1/functions/mass_storage.0
mkdir /sys/kernel/config/usb_gadget/g1/functions/mass_storage.0/lun.1
mkdir /sys/kernel/config/usb_gadget/g1/functions/ffs.bulk
mkdir /sys/kernel/config/usb_gadget/g1/functions/acm.0
mkdir /sys/kernel/config/usb_gadget/g1/functions/ffs.adb

mkdir /sys/kernel/config/usb_gadget/g1/configs/c.1
mkdir /sys/kernel/config/usb_gadget/g1/configs/c.1/strings/0x409

echo "vcom,bulk,adb" > /sys/kernel/config/usb_gadget/g1/configs/c.1/strings/0x409/configuration

ln -s /sys/kernel/config/usb_gadget/g1/functions/acm.0 /sys/kernel/config/usb_gadget/g1/configs/c.1/f1
ln -s /sys/kernel/config/usb_gadget/g1/functions/ffs.bulk /sys/kernel/config/usb_gadget/g1/configs/c.1/f2
ln -s /sys/kernel/config/usb_gadget/g1/functions/ffs.adb /sys/kernel/config/usb_gadget/g1/configs/c.1/f3

mount -o mode=0777 -o uid=2000 -o gid=2000 -t functionfs adb /dev/usb-ffs/adb
mount -o mode=0777 -o uid=2000 -o gid=2000 -t functionfs bulk /dev/usb-ffs/bulk

adbd &

trytime=0
while true
do
	if [ -f /dev/usb-ffs/adb/ep2 ]; then
		break;
	fi

	sleep 0.1
	let trytime++
	if [ trytime -ge 30 ]; then
		echo "adb congfig fail in 3 seconds!"
		break
	fi
done

echo 'usb engineering config is done'

