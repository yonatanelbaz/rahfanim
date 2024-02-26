#!/bin/sh

#############################################################################
# Preception test script
#
# exit code:
#  0 - success
#  1 - mb_ctrl fail
#  2 - some bits fail
#
# ###########################################################################

fail_msg="[ ${0##*/} _test_fail ]"

get_bit_name()
{
    if [ $# -ne 1 ]; then
        echo "invalid parameters($@)!"
        return
    fi
    case $1 in
        0) echo -n "down_cam" ;;
        4) echo -n "tof" ;;
        *) echo -n "unknown" ;;
    esac
}

#
#    It can show the perception link status, the bit is defined as below:
#    bit 0: down_cam
#    bit 4: tof
#    usage:
#

flag=0
case $1 in
    "all")
        echo "check all of the items..."
        index='0 4'
        ;;
    *)
        echo "not choice items, run all items default..."
        index='0 4'
        ;;
esac


n=0
retry=5
get_version_flag=0
while [ $n -lt $retry ]; do
    let n+=1
    result=`dji_mb_ctrl -S test -R diag -g 18 -t 0 -s 0 -c 01`
    ret=$?
    if [ $ret != 0 ]; then
        err_msg=${result##*error:}
        echo "get perception version error, $err_msg."
        sleep 1
        continue
    else
        echo "get perception version success, H22_LINUX--UART--1061_FC--UART--H2_RTOS ok"
        get_version_flag=1
        break
    fi
done

if [ $get_version_flag == 0 ]; then
    echo "get perception version fail. $fail_msg"
    exit 1
fi

n=0
retry=5
while [ $n -lt $retry ]; do
    let n+=1
    result=`dji_mb_ctrl -S test -R diag -g 18 -t 0 -s 0 -c 4c -4 ffffffff`
    ret=$?
    if [ $ret != 0 ];then
        err_msg=${result##*error:}
        echo "mb_ctrl(-s 0 -c 4c) perception error,ret=$ret, err_msg=$err_msg"
        sleep 1
        continue
    fi

    raw_data=${result##*data:}

    result=`echo $raw_data | busybox awk '{printf $1}'`
    if [ $result != "00" ]; then
        echo "mb_ctrl(-s 0 -c 4c) perception error, result=$result."
        sleep 1
        continue
    else
        bytes=`echo $raw_data | busybox awk '{printf "0x"$5$4$3$2;}'`
        bytes_dec=$((bytes))

        for i in $index; do
            bitmask=$((1 << $i))
            bit_result=$(($bitmask&$bytes_dec))
            err_msg=`get_bit_name $i`
            if [ $bit_result == 0 ]; then
                echo "perception bit $i is not set, the $err_msg ok "
            else
                flag=2
                echo "perception bit $i is set, the $err_msg error! $fail_msg"
            fi
        done

        break
    fi
done

if [ $flag == 2 ]; then
    echo "resp module state is $bytes. $fail_msg"
fi

exit $flag
