#!/bin/sh -x
ACTION_TYPE=$1


usbconfigfs(){
	mount -t configfs none /sys/kernel/config
	mkdir /dev/usb-ffs/
	mkdir /dev/usb-ffs/bulk
	mkdir /dev/usb-ffs/adb

	mkdir /sys/kernel/config/usb_gadget/g1
	echo "0x2CA3" > /sys/kernel/config/usb_gadget/g1/idVendor
	echo "0x001D" > /sys/kernel/config/usb_gadget/g1/idProduct
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

	echo "vcom,bulk,adb" > /sys/kernel/config/usb_gadget/g1/configs/c.1/strings/0x409/configuration

	#ln -s /sys/kernel/config/usb_gadget/g1/functions/rndis.0 /sys/kernel/config/usb_gadget/g1/configs/c.1/f1
	#ln -s /sys/kernel/config/usb_gadget/g1/functions/mass_storage.0 /sys/kernel/config/usb_gadget/g1/configs/c.1/f2
	ln -s /sys/kernel/config/usb_gadget/g1/functions/acm.0 /sys/kernel/config/usb_gadget/g1/configs/c.1/f1
	ln -s /sys/kernel/config/usb_gadget/g1/functions/ffs.bulk /sys/kernel/config/usb_gadget/g1/configs/c.1/f2
	ln -s /sys/kernel/config/usb_gadget/g1/functions/ffs.adb /sys/kernel/config/usb_gadget/g1/configs/c.1/f3

	mount -o mode=0777 -o uid=2000 -o gid=2000 -t functionfs adb /dev/usb-ffs/adb
	mount -o mode=0777 -o uid=2000 -o gid=2000 -t functionfs bulk /dev/usb-ffs/bulk
	adbd &
	bulk &
	sleep 1
}

echo "ACTION_TYPE:  $ACTION_TYPE"
case $ACTION_TYPE in
	ins | INS)
		echo "ins usb module"
		echo "device" > /proc/ambarella/usbphy0
		modprobe ambarella_udc
		if [ ! -d /sys/kernel/config/usb_gadget/g1 ];then
			#modprobe libcomposite
			usbconfigfs
		fi
		udc=`ls /sys/class/udc/`
		echo "${udc}" > /sys/kernel/config/usb_gadget/g1/UDC

		#ifconfig usb0 192.168.1.3 up
		#tcpsvd -vE 0.0.0.0 21 ftpd -w /tmp/SD0 &
		#tcpsvd -vE 0.0.0.0 22 ftpd -w /tmp/EMMC &
		#echo "1usb1_vcom" > /tmp/ipc_fifo
		#while [ -f /tmp/ipc_fifo ]
		#do
		#	sleep 0.3
		#done
		#source /usr/local/duml/setup_duml.sh
		#/usr/bin/dji_sys &
		#echo "1duml_host" > /tmp/ipc_fifo
		#while [ -f /tmp/ipc_fifo ]
		#do
		#	sleep 0.3
		#done
		#echo "1usb1_vnet" > /tmp/ipc_fifo
		;;
	none | NONE)
		echo "remove usb module"
		#echo "0usb1_vcom" > /tmp/ipc_fifo
		#while [ -f /tmp/ipc_fifo ]
		#do
		#	sleep 0.3
		#done
		#echo "0usb1_vnet" > /tmp/ipc_fifo
		ifconfig usb0 192.168.1.3 down
		echo "" > /sys/kernel/config/usb_gadget/g1/UDC
		rm -rf /sys/kernel/config/usb_gadget/g1/configs/c.1/f1
		rm -rf /sys/kernel/config/usb_gadget/g1/functions/rndis.0
		rmmod ambarella_udc
		#set phy shared flag
		echo "shared_with_rtos" > /proc/ambarella/usbphy0
		;;
	*)
		echo "ACTION_TYPE should be INS/NONE"
		exit -1
		;;
esac
