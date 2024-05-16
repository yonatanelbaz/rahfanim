#!/bin/sh

#############################################################################
# FC test script
#
# exit code:
#  0 - success
#  1 - mb_ctrl fail
#  2 - some bits fail
#############################################################################

fail_msg="[ ${0##*/} _test_fail ]"

get_module_name_for_index()
{
    case $1 in
        "0")
            module_name=25700_comm
            ;;
        "1")
            module_name=smb1352_comm
            ;;
        "2")
            module_name=bat_comm
            ;;
        "3")
            module_name=bat_vol
            ;;
        "4")
            module_name=usb_vol
            ;;
        "5")
            module_name=gimbal_vol
            ;;
        "6")
            module_name=pmic_comm
            ;;
        "8")
            module_name=acc
            ;;
        "9")
            module_name=gypo
            ;;
        "10")
            module_name=baro
            ;;
        "11")
            module_name=compass
            ;;
        "12")
            module_name=gps
            ;;
        "13")
            module_name=recorder
            ;;
        "14")
            module_name=esc
            ;;
        "15")
            module_name=bat
            ;;
        "16")
            module_name=ofdm
            ;;
        "17")
            module_name=rc
            ;;
        "18")
            module_name=vo
            ;;
        "19")
            module_name=acc_link
            ;;
        "20")
            module_name=gyro_link
            ;;
        "21")
            module_name=acc1
            ;;
        "22")
            module_name=gyro1
            ;;
        "23")
            module_name=acc1_link
            ;;
        "24")
            module_name=gyro1_link
            ;;
        "25")
            module_name=acc2
            ;;
        "26")
            module_name=gyro2
            ;;
        "27")
            module_name=acc2_link
            ;;
        "28")
            module_name=gyro2_link
            ;;
        "29")
            module_name=fan_link
            ;;
        "31")
            module_name=esc_pwm
            ;;
    esac
    echo -n "fc -> $module_name"
}

#
#    It can show the fly ctrl status, the bit is defined as below:
#    bit 0:  27500_comm
#    bit 1:  smb1352_comm
#    bit 2:  bat_comm
#    bit 3:  bat_vol
#    bit 4:  usb_vol
#    bit 5:  gimbal_vol
#    bit 6:  pmic_comm
#    bit 8:  acc
#    bit 9:  gypo
#    bit 10: baro
#    bit 11: compass
#    bit 12: gps
#    bit 13: recorder
#    bit 14: esc
#    bit 15: bat
#    bit 19: raw_acc
#    bit 20: raw_gypo
#    bit 31: esc_ppm
#

flag=0
case $1 in
    "all")
        echo "check all of the items..."
        index='8 9 10 11 12 13 14 15 19 20 31'
        ;;
    "main_card")
        echo "check main_card item"
        index='8 9 10 13 14 19 20 31'
        ;;
    "gps_only")
        echo "check gps_only item"
        index='12'
        ;;
    "compass_only")
        echo "check compass_only item"
        index='11'
        ;;
    "battery_only")
        echo "check battery_only item"
        index='15'
        ;;
    "charge_only")
        echo "check charge_only item"
        index='0 1 2 3 4 5 6'
        ;;
    "no_battery")
        echo "check all items except battery"
        index='8 9 10 11 12 13 14 19 20 31'
        ;;
    *)
        echo "not choice items, run all items default..."
        index='8 9 10 11 12 13 14 15 19 20 31'
        ;;
esac

result=`dji_mb_ctrl -S test -R diag -g 3 -t 6 -s 0 -c 4c`
ret=$?
if [ $ret != 0 ];then
    err_msg=${result##*error:}
    echo "error $ret, mb_ctrl fc $err_msg. $fail_msg"
    exit 1
fi

raw_data=${result##*data:}

result=`echo $raw_data | busybox awk '{printf $1}'`
if [ $result != "00" ]; then
    echo "fc error $result. $fail_msg."
    exit 1
fi

bytes=`echo $raw_data | busybox awk '{printf "0x"$5$4$3$2;}'`

bytes_dec=$((bytes))

for i in $index; do
    bitmask=$((1 << $i))
    bit_result=$(($bitmask&$bytes_dec))
    err_msg=`get_module_name_for_index $i`
    if [ $bit_result == 0 ]; then
        echo "bit $i not set, the $err_msg ok"
    else
        flag=2
        echo "fc bit $i is set, the $err_msg error!. $fail_msg"
        echo "fc bit $i. $fail_msg"
    fi
done


if [ $flag == 2 ]; then
    echo "resp module state is $bytes. $fail_msg"
fi

exit $flag
