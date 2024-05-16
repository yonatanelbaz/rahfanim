#!/bin/sh

HEAD_LED_STATUS_DIR=/tmp/EMMC/factory_test/head_led_status
HEAD_LED_GREEN_REQ_ID_FILE=$HEAD_LED_STATUS_DIR/green_requester_id.txt
HEAD_LED_GREEN_ACTION_ID_FILE=$HEAD_LED_STATUS_DIR/green_action_id.txt
HEAD_LED_GREEN_ACTION_FILE=$HEAD_LED_STATUS_DIR/green_action.txt

HEAD_LED_RED_REQ_ID_FILE=$HEAD_LED_STATUS_DIR/red_requester_id.txt
HEAD_LED_RED_ACTION_ID_FILE=$HEAD_LED_STATUS_DIR/red_action_id.txt
HEAD_LED_RED_ACTION_FILE=$HEAD_LED_STATUS_DIR/red_action.txt

HEAD_LED_BLUE_REQ_ID_FILE=$HEAD_LED_STATUS_DIR/blue_requester_id.txt
HEAD_LED_BLUE_ACTION_ID_FILE=$HEAD_LED_STATUS_DIR/blue_action_id.txt
HEAD_LED_BLUE_ACTION_FILE=$HEAD_LED_STATUS_DIR/blue_action.txt

HEAD_LED_WHITE_REQ_ID_FILE=$HEAD_LED_STATUS_DIR/white_requester_id.txt
HEAD_LED_WHITE_ACTION_ID_FILE=$HEAD_LED_STATUS_DIR/white_action_id.txt
HEAD_LED_WHITE_ACTION_FILE=$HEAD_LED_STATUS_DIR/white_action.txt

#
# HEAD LED
#

HEAD_LED_GENERIC_FLAG=01
HEAD_LED_REQUESTER_ID=0000
HEAD_LED_IDENTITY_ID=00

HEAD_LED_RED_BLINK_ACTION0=010a6464
HEAD_LED_RED_BLINK_ACTION1=000a6464
HEAD_LED_RED_ON_ACTION1=010a6464
HEAD_LED_RED_BLINK_ACTION2=00000000
HEAD_LED_RED_BLINK_ACTION3=00000000
HEAD_LED_RED_BLINK_ACTION4=00000000
HEAD_LED_RED_BLINK_ACTION5=00000000
HEAD_LED_RED_BLINK_ACTION6=00000000
HEAD_LED_RED_BLINK_ACTION7=00000000

HEAD_LED_PRIORITY=01
RED_HEAD_LED_PRIORITY=02
GREEN_HEAD_LED_PRIORITY=03
YELLOW_HEAD_LED_PRIORITY=04
BLUE_HEAD_LED_PRIORITY=05
WHITE_HEAD_LED_PRIORITY=06

HEAD_LED_SHOWTIME=00
HEAD_LED_TYPE=01
HEAD_LED_TIMEOUT=0111
HEAD_LED_DESCRIPTION=0102030405060708090a

FC_CMDSET=3
REGISTER_HEAD_LED_CMDID=0xbc
SET_HEAD_LED_CMDID=0xbe

HEAD_LED_GREEN_BLINK_ACTION0=020a6464
HEAD_LED_GREEN_BLINK_ACTION1=000a6464
HEAD_LED_GREEN_ON_ACTION1=020a6464
HEAD_LED_GREEN_BLINK_ACTION2=00000000
HEAD_LED_GREEN_BLINK_ACTION3=00000000
HEAD_LED_GREEN_BLINK_ACTION4=00000000
HEAD_LED_GREEN_BLINK_ACTION5=00000000
HEAD_LED_GREEN_BLINK_ACTION6=00000000
HEAD_LED_GREEN_BLINK_ACTION7=00000000

HEAD_LED_BLUE_BLINK_ACTION0=030a6464
HEAD_LED_BLUE_BLINK_ACTION1=000a6464
HEAD_LED_BLUE_ON_ACTION1=030a6464
HEAD_LED_BLUE_BLINK_ACTION2=00000000
HEAD_LED_BLUE_BLINK_ACTION3=00000000
HEAD_LED_BLUE_BLINK_ACTION4=00000000
HEAD_LED_BLUE_BLINK_ACTION5=00000000
HEAD_LED_BLUE_BLINK_ACTION6=00000000
HEAD_LED_BLUE_BLINK_ACTION7=00000000

HEAD_LED_WHITE_BLINK_ACTION0=080a6464
HEAD_LED_WHITE_BLINK_ACTION1=000a6464
HEAD_LED_WHITE_ON_ACTION1=080a6464
HEAD_LED_WHITE_BLINK_ACTION2=00000000
HEAD_LED_WHITE_BLINK_ACTION3=00000000
HEAD_LED_WHITE_BLINK_ACTION4=00000000
HEAD_LED_WHITE_BLINK_ACTION5=00000000
HEAD_LED_WHITE_BLINK_ACTION6=00000000
HEAD_LED_WHITE_BLINK_ACTION7=00000000

HEAD_LED_SET_ACTION_NUM=01
HEAD_LED_SET_REQUESTER_ID=0000

head_led_green_requester_id=00
head_led_green_action_id=00
head_led_green_action='none'

wait_fc_led_avliable()
{
    local retry_count=10
    while true; do
        dji_mb_ctrl -o 2000000 -R diag -g 3 -t 6 -s 0 -c 1 >> /dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo "fc led available"
            return 0
        else
            if [ $retry_count -eq 0 ]; then
                echo "wait fc led available fail"
                return 1
            else
                retry_count=$(($retry_count-1))
                sleep 1
            fi
        fi
    done
}

head_led_green_action_unregister()
{
    echo "head_led_green_action_unregister enter"
    local r=`dji_mb_ctrl -S test -R diag -g 3 -t 6 -s 3 -c 0xbd 0100${head_led_green_requester_id}${head_led_green_action_id}`
    local ret=$?
    if [ $ret -ne 0 ]; then
        local err_msg=${r##*error:}
        echo "head_led_green_action_unregister ret=$ret, mb_ctrl fc $err_msg __fail"
        return 1
    fi
    local k=${r##*data:}
    local rr=`echo $k | busybox awk '{printf $1}'`
    if [ $rr != "00" ]; then
        echo "head_led_green_action_unregister fc $rr __fail"
        return 2
    fi
    head_led_green_action='none'
    head_led_green_requester_id=00
    head_led_green_action_id=00
    echo "head_led_green_action_unregister ok"
    return 0
}

head_led_green_action_register()
{
    local action_byte=00
    local action=$1
    case $action in
        "on")
            action_byte=$HEAD_LED_GREEN_ON_ACTION1
            ;;
        "blink")
            action_byte=$HEAD_LED_GREEN_BLINK_ACTION1
            ;;
    esac

    if [ $head_led_green_action == $action ]; then
        return 0
    else
        if [ $head_led_green_action != "none" ]; then
            head_led_green_action_unregister
        fi
    fi

    echo "head_led_green_register enter"
    head_led_reg_ack=`dji_mb_ctrl -S test -R diag -g 3 -t 6 -s $FC_CMDSET -c $REGISTER_HEAD_LED_CMDID ${HEAD_LED_GENERIC_FLAG}${HEAD_LED_REQUESTER_ID}${HEAD_LED_IDENTITY_ID}${HEAD_LED_GREEN_BLINK_ACTION0}${action_byte}${HEAD_LED_GREEN_BLINK_ACTION2}${HEAD_LED_GREEN_BLINK_ACTION3}${HEAD_LED_GREEN_BLINK_ACTION4}${HEAD_LED_GREEN_BLINK_ACTION5}${HEAD_LED_GREEN_BLINK_ACTION6}${HEAD_LED_GREEN_BLINK_ACTION7}${GREEN_HEAD_LED_PRIORITY}${HEAD_LED_SHOWTIME}${HEAD_LED_TYPE}${HEAD_LED_TIMEOUT}${HEAD_LED_DESCRIPTION}`
    local ret=$?
    if [ $ret -ne 0 ]; then
        local err_msg=${head_led_reg_ack##*error:}
        echo "head_led_green_register ret=$ret, mb_ctrl fc $err_msg __fail"
        return 1
    fi

    raw_data=${head_led_reg_ack##*data:}
    local rr=`echo $raw_data | busybox awk '{printf $1}'`
    if [[ $rr != "00" && $rr != "0f" ]]; then
        echo "head_led_green_register fc $rr __fail"
        return 2
    fi

    result=`echo $raw_data | busybox awk '{printf $1;}'`
    head_led_green_requester_id=`echo $raw_data | busybox awk '{printf $2$3;}'`
    head_led_green_action_id=`echo $raw_data | busybox awk '{printf $5;}'`
    echo "head_led_green_register result=$result head_led_green_requester_id=$head_led_green_requester_id head_led_green_action_id=$head_led_green_action_id"

    head_led_green_action=$action

    if [ ! -d $HEAD_LED_STATUS_DIR ]; then
	mkdir -p $HEAD_LED_STATUS_DIR
    fi

    echo $head_led_green_requester_id > $HEAD_LED_GREEN_REQ_ID_FILE
    echo $head_led_green_action_id > $HEAD_LED_GREEN_ACTION_ID_FILE
    echo $head_led_green_action > $HEAD_LED_GREEN_ACTION_FILE
    return 0
}

head_led_green_blink()
{
    head_led_green_action_register "blink"

    echo "head_led_green_blink enter"
    local r=`dji_mb_ctrl -S test -R diag -g 3 -t 6 -s 3 -c 0xbe 01${head_led_green_requester_id}${head_led_green_action_id}01`
    local ret=$?
    if [ $ret -ne 0 ]; then
        local err_msg=${r##*error:}
        echo "head_led_green_blink ret=$ret, mb_ctrl fc $err_msg __fail"
        return 1
    fi
    local k=${r##*data:}
    local rr=`echo $k | busybox awk '{printf $1}'`
    if [ $rr != "00" ]; then
        echo "head_led_green_blink fc $rr __fail"
        return 2
    fi
    echo "head_led_green_blink ok"
}

head_led_green_on()
{
    head_led_green_action_register "on"

    echo "head_led_green_on enter"
    local r=`dji_mb_ctrl -S test -R diag -g 3 -t 6 -s 3 -c 0xbe 01${head_led_green_requester_id}${head_led_green_action_id}01`
    local ret=$?
    if [ $ret -ne 0 ]; then
        local err_msg=${r##*error:}
        echo "head_led_green_on ret=$ret, mb_ctrl fc $err_msg __fail"
        return 1
    fi
    local k=${r##*data:}
    local rr=`echo $k | busybox awk '{printf $1}'`
    if [ $rr != "00" ]; then
        echo "head_led_gree_on fc $rr __fail"
        return 2
    fi
    echo "head_led_green_on ok"
    return 0
}

head_led_red_requester_id=00
head_led_red_action_id=00
head_led_red_action='none'

head_led_red_action_unregister()
{
    echo "head_led_red_action_unregister enter"
    local r=`dji_mb_ctrl -S test -R diag -g 3 -t 6 -s 3 -c 0xbd 0100${head_led_red_requester_id}${head_led_red_action_id}`
    local ret=$?
    if [ $ret -ne 0 ]; then
        local err_msg=${r##*error:}
        echo "head_led_red_action_unregister ret=$ret, mb_ctrl fc $err_msg __fail"
        return 1
    fi
    local k=${r##*data:}
    local rr=`echo $k | busybox awk '{printf $1}'`
    if [ $rr != "00" ]; then
        echo "head_led_red_action_unregister fc $rr __fail"
        return 2
    fi
    head_led_red_action='none'
    head_led_red_requester_id=00
    head_led_red_action_id=00
    echo "head_led_red_action_unregister ok"
    return 0
}

head_led_red_action_register()
{
    local action_byte=00
    local action=$1
    case $action in
        "on")
            action_byte=$HEAD_LED_RED_ON_ACTION1
            ;;
        "blink")
            action_byte=$HEAD_LED_RED_BLINK_ACTION1
            ;;
    esac

    #higher priority
    if [ $head_led_green_action != "none" ]; then
        head_led_green_action_unregister
    fi

    if [ $head_led_red_action == $action ]; then
        return 0
    else
        if [ $head_led_red_action != "none" ]; then
            head_led_red_action_unregister
        fi
    fi

    echo "head_led_red_register enter"
    head_led_reg_ack=`dji_mb_ctrl -S test -R diag -g 3 -t 6 -s $FC_CMDSET -c $REGISTER_HEAD_LED_CMDID ${HEAD_LED_GENERIC_FLAG}${HEAD_LED_REQUESTER_ID}${HEAD_LED_IDENTITY_ID}${HEAD_LED_RED_BLINK_ACTION0}${action_byte}${HEAD_LED_RED_BLINK_ACTION2}${HEAD_LED_RED_BLINK_ACTION3}${HEAD_LED_RED_BLINK_ACTION4}${HEAD_LED_RED_BLINK_ACTION5}${HEAD_LED_RED_BLINK_ACTION6}${HEAD_LED_RED_BLINK_ACTION7}${RED_HEAD_LED_PRIORITY}${HEAD_LED_SHOWTIME}${HEAD_LED_TYPE}${HEAD_LED_TIMEOUT}${HEAD_LED_DESCRIPTION}`
    local ret=$?
    if [ $ret -ne 0 ]; then
        local err_msg=${head_led_reg_ack##*error:}
        echo "head_led_red_register ret=$ret, mb_ctrl fc $err_msg __fail"
        return 1
    fi

    raw_data=${head_led_reg_ack##*data:}
    local rr=`echo $raw_data | busybox awk '{printf $1}'`
    if [[ $rr != "00" && $rr != "0f" ]]; then
        echo "head_led_red_register fc $rr __fail"
        return 2
    fi

    result=`echo $raw_data | busybox awk '{printf $1;}'`
    head_led_red_requester_id=`echo $raw_data | busybox awk '{printf $2$3;}'`
    head_led_red_action_id=`echo $raw_data | busybox awk '{printf $5;}'`
    echo "head_led_red_register result=$result head_led_red_requester_id=$head_led_red_requester_id head_led_red_action_id=$head_led_red_action_id"

    head_led_red_action=$action

    if [ ! -d $HEAD_LED_STATUS_DIR ]; then
	mkdir -p $HEAD_LED_STATUS_DIR
    fi

    echo $head_led_red_requester_id > $HEAD_LED_RED_REQ_ID_FILE
    echo $head_led_red_action_id > $HEAD_LED_RED_ACTION_ID_FILE
    echo $head_led_red_action > $HEAD_LED_RED_ACTION_FILE
    return 0
}

head_led_red_blink()
{
    head_led_red_action_register "blink"

    echo "head_led_red_blink enter"
    local r=`dji_mb_ctrl -S test -R diag -g 3 -t 6 -s 3 -c 0xbe 01${head_led_red_requester_id}${head_led_red_action_id}01`
    local ret=$?
    if [ $ret -ne 0 ]; then
        local err_msg=${r##*error:}
        echo "head_led_red_blink ret=$ret, mb_ctrl fc $err_msg __fail"
        return 1
    fi
    local k=${r##*data:}
    local rr=`echo $k | busybox awk '{printf $1}'`
    if [ $rr != "00" ]; then
        echo "head_led_red_blink fc $rr __fail"
        return 2
    fi
    echo "head_led_red_blink ok"
}

head_led_red_on()
{
    head_led_red_action_register "on"

    echo "head_led_red_on enter"
    local r=`dji_mb_ctrl -S test -R diag -g 3 -t 6 -s 3 -c 0xbe 01${head_led_red_requester_id}${head_led_red_action_id}01`
    local ret=$?
    if [ $ret -ne 0 ]; then
        local err_msg=${r##*error:}
        echo "head_led_red_on ret=$ret, mb_ctrl fc $err_msg __fail"
        return 1
    fi
    local k=${r##*data:}
    local rr=`echo $k | busybox awk '{printf $1}'`
    if [ $rr != "00" ]; then
        echo "head_led_red_on fc $rr __fail"
        return 2
    fi
    echo "head_led_red_on ok"
    return 0
}

head_led_blue_requester_id=00
head_led_blue_action_id=00
head_led_blue_action='none'

head_led_blue_action_unregister()
{
    echo "head_led_blue_action_unregister enter"
    local r=`dji_mb_ctrl -S test -R diag -g 3 -t 6 -s 3 -c 0xbd 0100${head_led_blue_requester_id}${head_led_blue_action_id}`
    local ret=$?
    if [ $ret -ne 0 ]; then
        local err_msg=${r##*error:}
        echo "head_led_blue_action_unregister ret=$ret, mb_ctrl fc $err_msg __fail"
        return 1
    fi
    local k=${r##*data:}
    local rr=`echo $k | busybox awk '{printf $1}'`
    if [ $rr != "00" ]; then
        echo "head_led_blue_action_unregister fc $rr __fail"
        return 2
    fi
    head_led_blue_action='none'
    head_led_blue_requester_id=00
    head_led_blue_action_id=00
    echo "head_led_blue_action_unregister ok"
    return 0
}

head_led_blue_action_register()
{
    local action_byte=00
    local action=$1
    case $action in
        "on")
            action_byte=$HEAD_LED_BLUE_ON_ACTION1
            ;;
        "blink")
            action_byte=$HEAD_LED_BLUE_BLINK_ACTION1
            ;;
    esac

    #higher priority
    if [ $head_led_green_action != "none" ]; then
        head_led_green_action_unregister
    fi

    if [ $head_led_red_action != "none" ]; then
        head_led_red_action_unregister
    fi

    if [ $head_led_blue_action == $action ]; then
        return 0
    else
        if [ $head_led_blue_action != "none" ]; then
            head_led_blue_action_unregister
        fi
    fi

    echo "head_led_blue_register enter"
    head_led_reg_ack=`dji_mb_ctrl -S test -R diag -g 3 -t 6 -s $FC_CMDSET -c $REGISTER_HEAD_LED_CMDID ${HEAD_LED_GENERIC_FLAG}${HEAD_LED_REQUESTER_ID}${HEAD_LED_IDENTITY_ID}${HEAD_LED_BLUE_BLINK_ACTION0}${action_byte}${HEAD_LED_BLUE_BLINK_ACTION2}${HEAD_LED_BLUE_BLINK_ACTION3}${HEAD_LED_BLUE_BLINK_ACTION4}${HEAD_LED_BLUE_BLINK_ACTION5}${HEAD_LED_BLUE_BLINK_ACTION6}${HEAD_LED_BLUE_BLINK_ACTION7}${BLUE_HEAD_LED_PRIORITY}${HEAD_LED_SHOWTIME}${HEAD_LED_TYPE}${HEAD_LED_TIMEOUT}${HEAD_LED_DESCRIPTION}`
    local ret=$?
    if [ $ret -ne 0 ]; then
        local err_msg=${head_led_reg_ack##*error:}
        echo "head_led_blue_register ret=$ret, mb_ctrl fc $err_msg __fail"
        return 1
    fi

    raw_data=${head_led_reg_ack##*data:}
    local rr=`echo $raw_data | busybox awk '{printf $1}'`
    if [[ $rr != "00" && $rr != "0f" ]]; then
        echo "head_led_blue_register fc $rr __fail"
        return 2
    fi

    result=`echo $raw_data | busybox awk '{printf $1;}'`
    head_led_blue_requester_id=`echo $raw_data | busybox awk '{printf $2$3;}'`
    head_led_blue_action_id=`echo $raw_data | busybox awk '{printf $5;}'`
    echo "head_led_blue_register result=$result head_led_blue_requester_id=$head_led_blue_requester_id head_led_blue_action_id=$head_led_blue_action_id"

    head_led_blue_action=$action

    if [ ! -d $HEAD_LED_STATUS_DIR ]; then
	mkdir -p $HEAD_LED_STATUS_DIR
    fi

    echo $head_led_blue_requester_id > $HEAD_LED_BLUE_REQ_ID_FILE
    echo $head_led_blue_action_id > $HEAD_LED_BLUE_ACTION_ID_FILE
    echo $head_led_blue_action > $HEAD_LED_BLUE_ACTION_FILE
    return 0
}

head_led_blue_blink()
{
    head_led_blue_action_register "blink"

    echo "head_led_blue_blink enter"
    local r=`dji_mb_ctrl -S test -R diag -g 3 -t 6 -s 3 -c 0xbe 01${head_led_blue_requester_id}${head_led_blue_action_id}01`
    local ret=$?
    if [ $ret -ne 0 ]; then
        local err_msg=${r##*error:}
        echo "head_led_blue_blink ret=$ret, mb_ctrl fc $err_msg __fail"
        return 1
    fi
    local k=${r##*data:}
    local rr=`echo $k | busybox awk '{printf $1}'`
    if [ $rr != "00" ]; then
        echo "head_led_blue_blink fc $rr __fail"
        return 2
    fi
    echo "head_led_blue_blink ok"
}

head_led_blue_on()
{
    head_led_blue_action_register "on"

    echo "head_led_blue_on enter"
    local r=`dji_mb_ctrl -S test -R diag -g 3 -t 6 -s 3 -c 0xbe 01${head_led_blue_requester_id}${head_led_blue_action_id}01`
    local ret=$?
    if [ $ret -ne 0 ]; then
        local err_msg=${r##*error:}
        echo "head_led_blue_on ret=$ret, mb_ctrl fc $err_msg __fail"
        return 1
    fi
    local k=${r##*data:}
    local rr=`echo $k | busybox awk '{printf $1}'`
    if [ $rr != "00" ]; then
        echo "head_led_blue_on fc $rr __fail"
        return 2
    fi
    echo "head_led_blue_on ok"
    return 0
}

head_led_white_requester_id=00
head_led_white_action_id=00
head_led_white_action='none'

head_led_white_action_unregister()
{
    echo "head_led_white_action_unregister enter"
    local r=`dji_mb_ctrl -S test -R diag -g 3 -t 6 -s 3 -c 0xbd 0100${head_led_white_requester_id}${head_led_white_action_id}`
    local ret=$?
    if [ $ret -ne 0 ]; then
        local err_msg=${r##*error:}
        echo "head_led_white_action_unregister ret=$ret, mb_ctrl fc $err_msg __fail"
        return 1
    fi
    local k=${r##*data:}
    local rr=`echo $k | busybox awk '{printf $1}'`
    if [ $rr != "00" ]; then
        echo "head_led_white_action_unregister fc $rr __fail"
        return 2
    fi
    head_led_white_action='none'
    head_led_white_requester_id=00
    head_led_white_action_id=00
    echo "head_led_white_action_unregister ok"
    return 0
}

head_led_white_action_register()
{
    local action_byte=00
    local action=$1
    case $action in
        "on")
            action_byte=$HEAD_LED_WHITE_ON_ACTION1
            ;;
        "blink")
            action_byte=$HEAD_LED_WHITE_BLINK_ACTION1
            ;;
    esac

    #higher priority
    if [ $head_led_green_action != "none" ]; then
        head_led_green_action_unregister
    fi

    if [ $head_led_red_action != "none" ]; then
        head_led_red_action_unregister
    fi

    if [ $head_led_blue_action != "none" ]; then
        head_led_blue_action_unregister
    fi

    if [ $head_led_white_action == $action ]; then
        return 0
    else
        if [ $head_led_white_action != "none" ]; then
            head_led_white_action_unregister
        fi
    fi

    echo "head_led_white_register enter"
    head_led_reg_ack=`dji_mb_ctrl -S test -R diag -g 3 -t 6 -s $FC_CMDSET -c $REGISTER_HEAD_LED_CMDID ${HEAD_LED_GENERIC_FLAG}${HEAD_LED_REQUESTER_ID}${HEAD_LED_IDENTITY_ID}${HEAD_LED_WHITE_BLINK_ACTION0}${action_byte}${HEAD_LED_WHITE_BLINK_ACTION2}${HEAD_LED_WHITE_BLINK_ACTION3}${HEAD_LED_WHITE_BLINK_ACTION4}${HEAD_LED_WHITE_BLINK_ACTION5}${HEAD_LED_WHITE_BLINK_ACTION6}${HEAD_LED_WHITE_BLINK_ACTION7}${WHITE_HEAD_LED_PRIORITY}${HEAD_LED_SHOWTIME}${HEAD_LED_TYPE}${HEAD_LED_TIMEOUT}${HEAD_LED_DESCRIPTION}`
    local ret=$?
    if [ $ret -ne 0 ]; then
        local err_msg=${head_led_reg_ack##*error:}
        echo "head_led_white_register ret=$ret, mb_ctrl fc $err_msg __fail"
        return 1
    fi

    raw_data=${head_led_reg_ack##*data:}
    local rr=`echo $raw_data | busybox awk '{printf $1}'`
    if [[ $rr != "00" && $rr != "0f" ]]; then
        echo "head_led_white_register fc $rr __fail"
        return 2
    fi

    result=`echo $raw_data | busybox awk '{printf $1;}'`
    head_led_white_requester_id=`echo $raw_data | busybox awk '{printf $2$3;}'`
    head_led_white_action_id=`echo $raw_data | busybox awk '{printf $5;}'`
    echo "head_led_white_register result=$result head_led_white_requester_id=$head_led_white_requester_id head_led_white_action_id=$head_led_white_action_id"

    head_led_white_action=$action

    if [ ! -d $HEAD_LED_STATUS_DIR ]; then
	mkdir -p $HEAD_LED_STATUS_DIR
    fi

    echo $head_led_white_requester_id > $HEAD_LED_WHITE_REQ_ID_FILE
    echo $head_led_white_action_id > $HEAD_LED_WHITE_ACTION_ID_FILE
    echo $head_led_white_action > $HEAD_LED_WHITE_ACTION_FILE
    return 0
}

head_led_white_blink()
{
    head_led_white_action_register "blink"

    echo "head_led_white_blink enter"
    local r=`dji_mb_ctrl -S test -R diag -g 3 -t 6 -s 3 -c 0xbe 01${head_led_white_requester_id}${head_led_white_action_id}01`
    local ret=$?
    if [ $ret -ne 0 ]; then
        local err_msg=${r##*error:}
        echo "head_led_white_blink ret=$ret, mb_ctrl fc $err_msg __fail"
        return 1
    fi
    local k=${r##*data:}
    local rr=`echo $k | busybox awk '{printf $1}'`
    if [ $rr != "00" ]; then
        echo "head_led_white_blink fc $rr __fail"
        return 2
    fi
    echo "head_led_white_blink ok"
}

head_led_white_on()
{
    head_led_white_action_register "on"

    echo "head_led_white_on enter"
    local r=`dji_mb_ctrl -S test -R diag -g 3 -t 6 -s 3 -c 0xbe 01${head_led_white_requester_id}${head_led_white_action_id}01`
    local ret=$?
    if [ $ret -ne 0 ]; then
        local err_msg=${r##*error:}
        echo "head_led_white_on ret=$ret, mb_ctrl fc $err_msg __fail"
        return 1
    fi
    local k=${r##*data:}
    local rr=`echo $k | busybox awk '{printf $1}'`
    if [ $rr != "00" ]; then
        echo "head_led_white_on fc $rr __fail"
        return 2
    fi
    echo "head_led_white_on ok"
    return 0
}

head_led_testing()
{
    head_led_green_on
    sleep 5
    head_led_red_on
    sleep 5
    head_led_blue_on
    sleep 5
    head_led_white_on
    sleep 5
    head_led_white_action_unregister
}

head_led_green_off()
{
    if [ -e $HEAD_LED_GREEN_REQ_ID_FILE -a -e $HEAD_LED_GREEN_ACTION_ID_FILE -a -e $HEAD_LED_GREEN_ACTION_FILE ]; then
	head_led_green_requester_id=`cat $HEAD_LED_GREEN_REQ_ID_FILE`
	head_led_green_action_id=`cat $HEAD_LED_GREEN_ACTION_ID_FILE`
	head_led_green_action=`cat $HEAD_LED_GREEN_ACTION_FILE`

	head_led_green_action_unregister
    else
	echo "head_led_green_off state file not exist"
    fi
}

head_led_red_off()
{
    if [ -e $HEAD_LED_RED_REQ_ID_FILE -a -e $HEAD_LED_RED_ACTION_ID_FILE -a -e $HEAD_LED_RED_ACTION_FILE ]; then
	head_led_red_requester_id=`cat $HEAD_LED_RED_REQ_ID_FILE`
        head_led_red_action_id=`cat $HEAD_LED_RED_ACTION_ID_FILE`
	head_led_red_action=`cat $HEAD_LED_RED_ACTION_FILE`

	head_led_red_action_unregister
    else
	echo "head_led_red_off state file not exist"
    fi
}

head_led_blue_off()
{
    if [ -e $HEAD_LED_BLUE_REQ_ID_FILE -a -e $HEAD_LED_BLUE_ACTION_ID_FILE -a -e $HEAD_LED_BLUE_ACTION_FILE ]; then
        head_led_blue_requester_id=`cat $HEAD_LED_BLUE_REQ_ID_FILE`
        head_led_blue_action_id=`cat $HEAD_LED_BLUE_ACTION_ID_FILE`
	head_led_blue_action=`cat $HEAD_LED_BLUE_ACTION_FILE`

	head_led_blue_action_unregister
    else
	echo "head_led_blue_off state file not exist"
    fi
}

head_led_white_off()
{
    if [ -e $HEAD_LED_WHITE_REQ_ID_FILE -a -e $HEAD_LED_WHITE_ACTION_ID_FILE -a -e $HEAD_LED_WHITE_ACTION_FILE ]; then
        head_led_white_requester_id=`cat $HEAD_LED_WHITE_REQ_ID_FILE`
        head_led_white_action_id=`cat $HEAD_LED_WHITE_ACTION_ID_FILE`
	head_led_white_action=`cat $HEAD_LED_WHITE_ACTION_FILE`

	head_led_white_action_unregister
    else
	echo "head_led_white_off state file not exist"
    fi
}
