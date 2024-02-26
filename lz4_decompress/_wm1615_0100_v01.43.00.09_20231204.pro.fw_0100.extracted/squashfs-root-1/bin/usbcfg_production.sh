#!/bin/sh

echo 'usb production config is running'

modprobe ehci-ambarella
modprobe cdc-acm

chekc_if_need_config=$(lsmod | grep ambarella_udc)
if [ -n "$chekc_if_need_config" ]; then
    ## no need to reconfig USB configfs
    echo "no need to reconfig USB configfs"
    exit 0
fi

echo "device" > /proc/ambarella/usbphy0
modprobe ambarella_udc

mount -t configfs none /sys/kernel/config
mkdir /dev/usb-ffs/
mkdir /dev/usb-ffs/bulk
mkdir /dev/usb-ffs/adb

mkdir /sys/kernel/config/usb_gadget/g1
#cd g1
echo "0x2CA3" > /sys/kernel/config/usb_gadget/g1/idVendor
echo "0x001E" > /sys/kernel/config/usb_gadget/g1/idProduct
mkdir /sys/kernel/config/usb_gadget/g1/strings/0x409
echo "123456789ABCDEF" > /sys/kernel/config/usb_gadget/g1/strings/0x409/serialnumber
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

echo "rndis,vcom" > /sys/kernel/config/usb_gadget/g1/configs/c.1/strings/0x409/configuration


ln -s /sys/kernel/config/usb_gadget/g1/functions/rndis.0 /sys/kernel/config/usb_gadget/g1/configs/c.1/f1
ln -s /sys/kernel/config/usb_gadget/g1/functions/acm.0 /sys/kernel/config/usb_gadget/g1/configs/c.1/f2

#enable UDC
udc=`ls /sys/class/udc/`
echo "${udc}" > /sys/kernel/config/usb_gadget/g1/UDC

# bind SD flylog dir to blackbox
if [ ! -d /tmp/blackbox/flylog ]; then
   mkdir -p /tmp/blackbox/flylog
fi
mount --bind /tmp/SD0/MISC/LOG/flylog /tmp/blackbox/flylog

# config rndis
ifconfig usb0 192.168.1.3 up
# port 21 & 22 are for factory usage
#tcpsvd -vE 0.0.0.0 21 ftpd -w /tmp/SD0 &
#tcpsvd -vE 0.0.0.0 22 ftpd -w /tmp/EMMC &
#tcpsvd -vE 0.0.0.0 23 ftpd -w /tmp/blackbox &
dji_ftpd &

busybox udhcpd /etc/udhcpd_rndis.conf &

echo 'usb production config is done'

