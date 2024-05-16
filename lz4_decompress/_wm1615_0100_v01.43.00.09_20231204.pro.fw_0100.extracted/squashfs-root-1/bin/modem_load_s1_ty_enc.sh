#!/bin/sh

run_error_exit()
{
    eval $*
    local r=$?
    if [ $r != 0 ]; then
        echo error to run \"$*\": FAILED, errno=$r > /dev/kmsg
        exit $r
    fi
}

ls /tmp/blackbox | grep "sparrow_firmware"

if [ $? -ne 0 ]; then

    echo "fastboot start" > /dev/kmsg
    run_error_exit brload /etc/sparrow_firmware/bootarea.img
    run_error_exit fastboot -T 2000 flash modem-pub_key      /etc/sparrow_firmware/bootarea.img
    run_error_exit fastboot -T 2000 flash modem-s1-rf-nvram  /etc/sparrow_firmware/rf_nvram.bin
    run_error_exit fastboot -T 2000 flash modem-s1-amt       /tmp/EMMC/wireless/sdr/amt.bin
    run_error_exit fastboot -T 2000 flash modem-s1-nvram     /tmp/EMMC/wireless/sdr/cp_nvram.bin
    run_error_exit fastboot -T 2000 flash modem-s1-pwr       /etc/sparrow_firmware/pwr.bin
    run_error_exit fastboot -T 2000 flash modem-s1-ap        /etc/sparrow_firmware/ap.img
    run_error_exit fastboot -T 2000 flash modem-s1-cp        /etc/sparrow_firmware/cp.img
    echo "fastboot end" > /dev/kmsg

else

    echo "fastboot start" > /dev/kmsg
    run_error_exit brload /tmp/blackbox/sparrow_firmware/bootarea.img
    run_error_exit fastboot -T 2000 flash modem-pub_key      /tmp/blackbox/sparrow_firmware/bootarea.img
    run_error_exit fastboot -T 2000 flash modem-s1-rf-nvram  /tmp/blackbox/sparrow_firmware/rf_nvram.bin
    run_error_exit fastboot -T 2000 flash modem-s1-amt       /tmp/EMMC/wireless/sdr/amt.bin
    run_error_exit fastboot -T 2000 flash modem-s1-nvram     /tmp/EMMC/wireless/sdr/cp_nvram.bin
    run_error_exit fastboot -T 2000 flash modem-s1-pwr       /tmp/blackbox/sparrow_firmware/pwr.bin
    run_error_exit fastboot -T 2000 flash modem-s1-ap        /tmp/blackbox/sparrow_firmware/ap.img
    run_error_exit fastboot -T 2000 flash modem-s1-cp        /tmp/blackbox/sparrow_firmware/cp.img
    echo "fastboot end" > /dev/kmsg

fi

