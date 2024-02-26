#!/bin/sh

####################################################
# erase gimbal data
#
# USAGE:
#   - erase_gimbal_data.sh [opt]
#
# DESCRIPTION:
#   To erase gimbal data and calibration the motor.
#
# OPTIONS:
#   [opt]         - 1 : erase and cali
#                 - 2 : erase and no cali
# EXIT STATUS
#   0:            - Exec successfully
#   1:            - Exec fail
#   2:            - Illegal params
####################################################

erase_cmd()
{
    id='02'
    length='02'
    motor_data=$2
    case $1 in
        'no_ack')
            result=`dji_mb_ctrl -R diag -a 0 -g 4 -t 0 -s 4 -c 68 $id$length$motor_data`
            ;;
        'ack')
            result=`dji_mb_ctrl -R diag -g 4 -t 0 -s 4 -c 68 $id$length$motor_data`
            ;;
        *)
            result=`dji_mb_ctrl -R diag -g 4 -t 0 -s 4 -c 68 $id$length$motor_data`
            ;;
    esac

    ret=$?
    if [ $ret != 0 ]; then
        err_msg=${result##*error}
        echo "error $ret, mb_ctrl gimbal motor $err_msg."
        exit 1
    fi
}

case $1 in
    1)
        echo "erase and cali"
        erase_cmd 'no_ack' '0100'
        ;;
    2)
        echo "erase and no cali"
        erase_cmd 'ack' '0400'
        ;;
    *)
        echo "Illegal params"
        exit 2
        ;;
esac

exit $?
