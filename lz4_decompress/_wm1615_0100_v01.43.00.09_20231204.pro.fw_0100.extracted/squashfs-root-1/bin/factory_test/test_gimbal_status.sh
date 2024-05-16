#!/bin/sh

#############################################################################
# Gimbal test script
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
	14) echo -n "accelerometer" ;;
	15) echo -n "gyroscope" ;;
	18) echo -n "pitch motor" ;;
	19) echo -n "roll motor" ;;
	20) echo -n "yaw motor" ;;
	21) echo -n "pitch hall a" ;;
	22) echo -n "pitch hall b" ;;
	23) echo -n "roll  hall a" ;;
	24) echo -n "roll  hall b" ;;
	25) echo -n "yaw   hall a" ;;
	26) echo -n "yaw   hall b" ;;
	*) echo -n "unknown" ;;
    esac
}

#
#    It can show the gimbal link status, the bit is defined as below:
#    bit 14: 加速度计
#    bit 15: 陀螺仪
#    bit 18: pitch 电机
#    bit 19: roll 电机
#    bit 20: yaw 电机
#    bit 21: pitch 霍尔A
#    bit 22: pitch 霍尔B
#    bit 23: roll  霍尔A
#    bit 24: roll  霍尔B
#    bit 25: yaw   霍尔A
#    bit 26: yaw   霍尔B
#    usage:
#

flag=0
case $1 in
    "all")
        echo "check all of the items..."
        index='14 15 18 19 20 21 22 23 24 25 26'
        ;;
    *)
        echo "not choice items, run all items default..."
        index='14 15 18 19 20 21 22 23 24 25 26'
        ;;
esac

result=`dji_mb_ctrl -S test -R diag -g 4 -t 0 -s 0 -c 5f`
ret=$?
if [ $ret != 0 ];then
    err_msg=${result##*error:}
    echo "error $ret, mb_ctrl gimbal $err_msg. $fail_msg"
    exit 1
fi

raw_data=${result##*data:}

result=`echo $raw_data | busybox awk '{printf $1}'`
if [ $result != "00" ]; then
    echo "gimbal error $result. $fail_msg."
    exit 1
fi

bytes=`echo $raw_data | busybox awk '{printf "0x"$6$5$4$3;}'`

bytes_dec=$((bytes))

for i in $index; do
    bitmask=$((1 << $i))
    bit_result=$(($bitmask&$bytes_dec))
    err_msg=`get_bit_name $i`
    if [ $bit_result == 0 ]; then
        echo "gimbal bit $i is not set, the $err_msg ok "
    else
        flag=2
        echo "gimbal bit $i is set, the $err_msg error! $fail_msg"
    fi
done

if [ $flag == 2 ]; then
    echo "resp module state is $bytes. $fail_msg"
fi

exit $flag
