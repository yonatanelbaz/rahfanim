#!/bin/sh

##########################################################################
# conditional launch v2sdk service
#
# prodution mode -->
#  - launch v2sdk service by default
#  - launch v2sdk service with bulk available if there is a file
#    /tmp/EMMC/factory_test/V2SDK_CALI
#
# factory mode -->
#  - launch v2sdk service by default (need to be deleted)
#  - don't launch v2sdk service service if there is a file
#    /tmp/EMMC/factory_test/V2SDK_DISABLE, and sleep forever
#
#########################################################################

V2SDK_CALI_FLAG_FILE=/tmp/EMMC/factory_test/V2SDK_CALI
V2SDK_DISABLE_FLAG_FILE=/tmp/EMMC/factory_test/V2SDK_DISABLE
BULK_EP2_NODE=/dev/usb-ffs/bulk/ep2

wait_bulk_available()
{
    local time_count=0
    local timeout=20
    ret=0

    while true
    do
        if [ -e $BULK_EP2_NODE ]; then
            echo 'bulk function is ready.'
            ret=0
            break
        elif [ $time_count -gt $timeout ]; then
            echo 'wait for bulk ready timeout.'
            ret=1
            break
        else
            sleep 1
            echo "waiting for bulk function ready..."
            time_count=$(($time_count+1))
        fi
    done

    return $ret
}

enable_v2_sdk_service()
{
    kill `ps | grep -v 'grep' | grep "dji_v2_sdk" | awk -F ' ' '{print $1}'`

    if [ -x /usr/bin/dji_v2_sdk ]; then
        echo "enable dji_v2_sdk"
        /usr/bin/dji_v2_sdk
    fi
}

is_production_mode()
{
    ret=`/usr/bin/parse_cmdline.sh mp_state production`
    return $ret
}

#can be replaced by factory_mode
is_need_disable_v2sdk()
{
    if [ -e $V2SDK_DISABLE_FLAG_FILE ]; then
        echo "maybe factory mode, don't lanunch v2sdk"
        return 0
    else
        return 1
    fi
}

is_need_cali()
{
    if [ -e $V2SDK_CALI_FLAG_FILE ]; then
        echo "need enable v2sdk for calibration"
        return 0
    else
        return 1
    fi
}

is_secure_debug()
{
    ret=`/usr/bin/parse_cmdline.sh androidboot.secure_debug 1`
    return $ret
}

forever_sleep()
{
    while true; do
        sleep 1000
    done
}

conditional_enable_v2sdk_service()
{
    is_production_mode
    if [ $? -eq 0 ]; then
        is_secure_debug
        if [ $? -eq 0 ]; then
            is_need_disable_v2sdk
            if [ $? -eq 0 ]; then
                forever_sleep
            else
                is_need_cali
                if [ $? -eq 0 ]; then
                    wait_bulk_available
                fi
            fi
        fi
        enable_v2_sdk_service
    else
        is_need_disable_v2sdk
        if [ $? -eq 0 ]; then
            forever_sleep
        else
            is_need_cali
            if [ $? -eq 0 ]; then
                wait_bulk_available
            fi
            enable_v2_sdk_service
        fi
    fi
}

conditional_enable_v2sdk_service $@
