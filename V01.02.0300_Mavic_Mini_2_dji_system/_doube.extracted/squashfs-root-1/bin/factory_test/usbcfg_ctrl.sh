#!/bin/sh

USB_CFG_FILE=/tmp/EMMC/usb_cfg.cfg

set_usbcfg()
{
    case $1 in
        'adb_vcom_bulk')
            usbcfg_vcom_adb.sh
            ;;
        'vcom_rndis')
            usbcfg_rndis_vcom.sh
            ;;
    esac
    return $?
}

get_usbcfg()
{
    data=`cat /sys/kernel/config/usb_gadget/g1/configs/c.1/strings/0x409/configuration`
    result=$?
    if [ $result -eq 0 ]; then
        echo $data
    else
        echo 'none'
    fi
    return $result
}

set_usb0_ip()
{
    ip=$1
    #TODO: to check ip validity
    ifconfig usb0 $ip up
    return $?
}

get_usb0_ip()
{
    data=`ifconfig usb0`
    result=$?
    if [ $result -eq 0 ]; then
        ip_str=${data##*inet addr:}
        ip=${ip_str%% *}
        echo $ip
    fi
    return $result
}

same_as_cur_function()
{
    usbcfg=`get_usbcfg`
    result=$?
    if [ $result -eq 0 ]; then
        echo $usbcfg | grep $1
        result=$?
    fi
    return $result
}

set_usb_cfg_handler()
{
    case $1 in
        'adb'|'vcom'|'bulk')
            same_as_cur_function $1
            if [ $? -ne 0 ]; then
                echo "switch USB function to adb_vcom_bulk"
                set_usbcfg 'adb_vcom_bulk'
            fi
            ;;
        'rndis')
            same_as_cur_function $1
            if [ $? -ne 0 ]; then
                echo "switch USB function to vcom_rndis"
                set_usbcfg 'vcom_rndis'
            fi

            if [ $# -eq 2 ]; then
                echo "set ip to $2"
                set_usb0_ip $2
            fi
            ;;
        *)  echo "Illegal params!"
            return 2
            ;;
    esac

    return $?
}

get_usb_cfg_handler()
{
    data=`get_usbcfg`
    result=$?

    if [ $result -ne 0 ]; then
        echo "get usbcfg error, get $data"
        return 1
    else
        echo "cur usbcfg is $data"
    fi

    echo $data | grep 'rndis'

    if [ $? -eq 0 ]; then
        ip=`get_usb0_ip`
        if [ $? -eq 0 ]; then
            echo "host ip: $ip"
        else
            echo "get host ip failure"
        fi
    fi
}

save_usb_cfg_handler()
{
    case $1 in
        'adb'|'vcom'|'bulk')
            echo $1 > $USB_CFG_FILE
            ;;
        'rndis')
            echo $1 > $USB_CFG_FILE
            if [ $# -eq 2 ]; then
                echo "save ip to $2"
                echo $2 >> $USB_CFG_FILE
            fi
            ;;
        *)  echo "Illegal params!"
            return 2
            ;;
    esac
}

delete_usb_cfg_handler()
{
    if [ -e $USB_CFG_FILE ]; then
        echo "delete usb_cfg file :$USB_CFG_FILE"
        rm -f $USB_CFG_FILE
    fi
}

#########################################################################
# usb fucntion ctrl
#
# USAGE:
#   - usbcfg_ctrl.sh [operation] [function] [ip]
#
# DESCRIPTION:
#    The script can be used to configure USB function and get USB config
#  information.
#
# OPTIONS:
#   [operation]:  - Get/set/save/delete usb config info.
#                 - There is more attribute can be configured when you
#                   set the [operation] to 'set/save'
#                 - Support prams: set, get, save, delete
#
#   [function]:   - USB fcuntion.
#                 - Optional param, it does work if [operation]='set/save'.
#                 - Support prams: adb, vcom, rndis, bulk.
#
#   [ip]:         - To set ip address of ftp server.
#                 - Optional param, it does work if [function]='rndis'.
#
# EXIT STATUS
#   0:            - Exec successfully.
#   1:            - Exec Failed.
#   2:            - Illegal params.
#
# NOTES:
#   There is two USB function in system, adb+bulk+vcom and rndis+vcom. You
# can use amt test command to call this script to set any a function, also
# you can get current USB config information by params 'get'.
#   If you want to switch to vcom function, the script will switch to
# adb+bulk+vcom default.
#   The param of 'save' will make your configuration to be saved, and the
# configuration will be loaded with system boots up.
#
# EXAMPLE
# usbcfg_ctrl.sh set adb  -- switch to adb function
# usbcfg_ctrl.sh set rndis 192.168.1.2 -- switch to rndis function and set ip
# usbcfg_ctrl.sh get -- get USB config information
# usbcfg_ctrl.sh save rndis 192.168.1.2 -- switch to rndis function and save config
#
#########################################################################

main()
{
    case $1 in
        'set')
            echo "set usbcfg"
            set_usb_cfg_handler $2 $3
            ;;
        'get')
            echo "get usbcfg"
            get_usb_cfg_handler $2 $3
            ;;
        'save')
            echo "set and save usbcfg"
            set_usb_cfg_handler $2 $3
            save_usb_cfg_handler $2 $3
            ;;
        'delete')
            echo "delete usbcfg"
            delete_usb_cfg_handler
            ;;
        *)
            echo "Illegal params!"
            exit 2
            ;;
    esac

    exit $?
}

main $@
