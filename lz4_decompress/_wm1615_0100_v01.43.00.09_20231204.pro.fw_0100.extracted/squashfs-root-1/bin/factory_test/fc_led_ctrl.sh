#!/bin/sh

LED_STATUS_DIR=/tmp/EMMC/factory_test/led_status
LED_GREEN_REQ_ID_FILE=$LED_STATUS_DIR/green_requester_id.txt
LED_GREEN_ACTION_ID_FILE=$LED_STATUS_DIR/green_action_id.txt
LED_GREEN_ACTION_FILE=$LED_STATUS_DIR/green_action.txt

LED_RED_REQ_ID_FILE=$LED_STATUS_DIR/red_requester_id.txt
LED_RED_ACTION_ID_FILE=$LED_STATUS_DIR/red_action_id.txt
LED_RED_ACTION_FILE=$LED_STATUS_DIR/red_action.txt

LED_BLUE_REQ_ID_FILE=$LED_STATUS_DIR/blue_requester_id.txt
LED_BLUE_ACTION_ID_FILE=$LED_STATUS_DIR/blue_action_id.txt
LED_BLUE_ACTION_FILE=$LED_STATUS_DIR/blue_action.txt

LED_WHITE_REQ_ID_FILE=$LED_STATUS_DIR/white_requester_id.txt
LED_WHITE_ACTION_ID_FILE=$LED_STATUS_DIR/white_action_id.txt
LED_WHITE_ACTION_FILE=$LED_STATUS_DIR/white_action.txt

#
# LED
#

LED_GENERIC_FLAG=01
LED_REQUESTER_ID=0000
LED_IDENTITY_ID=00

LED_RED_BLINK_ACTION0=010a6464
LED_RED_BLINK_ACTION1=000a6464
LED_RED_ON_ACTION1=010a6464
LED_RED_BLINK_ACTION2=00000000
LED_RED_BLINK_ACTION3=00000000
LED_RED_BLINK_ACTION4=00000000
LED_RED_BLINK_ACTION5=00000000
LED_RED_BLINK_ACTION6=00000000
LED_RED_BLINK_ACTION7=00000000

LED_PRIORITY=01
RED_LED_PRIORITY=02
GREEN_LED_PRIORITY=03
YELLOW_LED_PRIORITY=04
BLUE_LED_PRIORITY=05
WHITE_LED_PRIORITY=06

LED_SHOWTIME=00
LED_TYPE=00
LED_TIMEOUT=0111
LED_DESCRIPTION=0102030405060708090a

FC_CMDSET=3
REGISTER_LED_CMDID=0xbc
SET_LED_CMDID=0xbe

LED_GREEN_BLINK_ACTION0=020a6464
LED_GREEN_BLINK_ACTION1=000a6464
LED_GREEN_ON_ACTION1=020a6464
LED_GREEN_BLINK_ACTION2=00000000
LED_GREEN_BLINK_ACTION3=00000000
LED_GREEN_BLINK_ACTION4=00000000
LED_GREEN_BLINK_ACTION5=00000000
LED_GREEN_BLINK_ACTION6=00000000
LED_GREEN_BLINK_ACTION7=00000000

LED_BLUE_BLINK_ACTION0=030a6464
LED_BLUE_BLINK_ACTION1=000a6464
LED_BLUE_ON_ACTION1=030a6464
LED_BLUE_BLINK_ACTION2=00000000
LED_BLUE_BLINK_ACTION3=00000000
LED_BLUE_BLINK_ACTION4=00000000
LED_BLUE_BLINK_ACTION5=00000000
LED_BLUE_BLINK_ACTION6=00000000
LED_BLUE_BLINK_ACTION7=00000000

LED_WHITE_BLINK_ACTION0=080a6464
LED_WHITE_BLINK_ACTION1=000a6464
LED_WHITE_ON_ACTION1=080a6464
LED_WHITE_BLINK_ACTION2=00000000
LED_WHITE_BLINK_ACTION3=00000000
LED_WHITE_BLINK_ACTION4=00000000
LED_WHITE_BLINK_ACTION5=00000000
LED_WHITE_BLINK_ACTION6=00000000
LED_WHITE_BLINK_ACTION7=00000000

LED_SET_ACTION_NUM=01
LED_SET_REQUESTER_ID=0000

green_requester_id=00
green_action_id=00
green_action='none'

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

led_green_action_unregister()
{
    echo "led_green_action_unregister enter"
    local r=`dji_mb_ctrl -S test -R diag -g 3 -t 6 -s 3 -c 0xbd 0100${green_requester_id}${green_action_id}`
    local ret=$?
    if [ $ret -ne 0 ]; then
        local err_msg=${r##*error:}
        echo "led_green_action_unregister ret=$ret, mb_ctrl fc $err_msg __fail"
        return 1
    fi
    local k=${r##*data:}
    local rr=`echo $k | busybox awk '{printf $1}'`
    if [ $rr != "00" ]; then
        echo "led_green_action_unregister fc $rr __fail"
        return 2
    fi
    green_action='none'
    green_requester_id=00
    green_action_id=00
    echo "led_green_action_unregister ok"
    return 0
}

led_green_action_register()
{
    local action_byte=00
    local action=$1
    case $action in
        "on")
            action_byte=$LED_GREEN_ON_ACTION1
            ;;
        "blink")
            action_byte=$LED_GREEN_BLINK_ACTION1
            ;;
    esac

    if [ $green_action == $action ]; then
        return 0
    else
        if [ $green_action != "none" ]; then
            led_green_action_unregister
        fi
    fi

    echo "led_green_register enter"
    led_reg_ack=`dji_mb_ctrl -S test -R diag -g 3 -t 6 -s $FC_CMDSET -c $REGISTER_LED_CMDID ${LED_GENERIC_FLAG}${LED_REQUESTER_ID}${LED_IDENTITY_ID}${LED_GREEN_BLINK_ACTION0}${action_byte}${LED_GREEN_BLINK_ACTION2}${LED_GREEN_BLINK_ACTION3}${LED_GREEN_BLINK_ACTION4}${LED_GREEN_BLINK_ACTION5}${LED_GREEN_BLINK_ACTION6}${LED_GREEN_BLINK_ACTION7}${GREEN_LED_PRIORITY}${LED_SHOWTIME}${LED_TYPE}${LED_TIMEOUT}${LED_DESCRIPTION}`
    local ret=$?
    if [ $ret -ne 0 ]; then
        local err_msg=${led_reg_ack##*error:}
        echo "led_green_register ret=$ret, mb_ctrl fc $err_msg __fail"
        return 1
    fi

    raw_data=${led_reg_ack##*data:}
    local rr=`echo $raw_data | busybox awk '{printf $1}'`
    if [[ $rr != "00" && $rr != "0f" ]]; then
        echo "led_green_register fc $rr __fail"
        return 2
    fi

    result=`echo $raw_data | busybox awk '{printf $1;}'`
    green_requester_id=`echo $raw_data | busybox awk '{printf $2$3;}'`
    green_action_id=`echo $raw_data | busybox awk '{printf $5;}'`
    echo "led_green_register result=$result green_requester_id=$green_requester_id green_action_id=$green_action_id"

    green_action=$action

    if [ ! -d $LED_STATUS_DIR ]; then
	mkdir -p $LED_STATUS_DIR
    fi

    echo $green_requester_id > $LED_GREEN_REQ_ID_FILE
    echo $green_action_id > $LED_GREEN_ACTION_ID_FILE
    echo $green_action > $LED_GREEN_ACTION_FILE
    return 0
}

led_green_blink()
{
    led_green_action_register "blink"

    echo "led_green_blink enter"
    local r=`dji_mb_ctrl -S test -R diag -g 3 -t 6 -s 3 -c 0xbe 01${green_requester_id}${green_action_id}01`
    local ret=$?
    if [ $ret -ne 0 ]; then
        local err_msg=${r##*error:}
        echo "led_green_blink ret=$ret, mb_ctrl fc $err_msg __fail"
        return 1
    fi
    local k=${r##*data:}
    local rr=`echo $k | busybox awk '{printf $1}'`
    if [ $rr != "00" ]; then
        echo "led_green_blink fc $rr __fail"
        return 2
    fi
    echo "led_green_blink ok"
}

led_green_on()
{
    led_green_action_register "on"

    echo "led_green_on enter"
    local r=`dji_mb_ctrl -S test -R diag -g 3 -t 6 -s 3 -c 0xbe 01${green_requester_id}${green_action_id}01`
    local ret=$?
    if [ $ret -ne 0 ]; then
        local err_msg=${r##*error:}
        echo "led_green_on ret=$ret, mb_ctrl fc $err_msg __fail"
        return 1
    fi
    local k=${r##*data:}
    local rr=`echo $k | busybox awk '{printf $1}'`
    if [ $rr != "00" ]; then
        echo "led_gree_on fc $rr __fail"
        return 2
    fi
    echo "led_green_on ok"
    return 0
}

red_requester_id=00
red_action_id=00
red_action='none'

led_red_action_unregister()
{
    echo "led_red_action_unregister enter"
    local r=`dji_mb_ctrl -S test -R diag -g 3 -t 6 -s 3 -c 0xbd 0100${red_requester_id}${red_action_id}`
    local ret=$?
    if [ $ret -ne 0 ]; then
        local err_msg=${r##*error:}
        echo "led_red_action_unregister ret=$ret, mb_ctrl fc $err_msg __fail"
        return 1
    fi
    local k=${r##*data:}
    local rr=`echo $k | busybox awk '{printf $1}'`
    if [ $rr != "00" ]; then
        echo "led_red_action_unregister fc $rr __fail"
        return 2
    fi
    red_action='none'
    red_requester_id=00
    red_action_id=00
    echo "led_red_action_unregister ok"
    return 0
}

led_red_action_register()
{
    local action_byte=00
    local action=$1
    case $action in
        "on")
            action_byte=$LED_RED_ON_ACTION1
            ;;
        "blink")
            action_byte=$LED_RED_BLINK_ACTION1
            ;;
    esac

    #higher priority
    if [ $green_action != "none" ]; then
        led_green_action_unregister
    fi

    if [ $red_action == $action ]; then
        return 0
    else
        if [ $red_action != "none" ]; then
            led_red_action_unregister
        fi
    fi

    echo "led_red_register enter"
    led_reg_ack=`dji_mb_ctrl -S test -R diag -g 3 -t 6 -s $FC_CMDSET -c $REGISTER_LED_CMDID ${LED_GENERIC_FLAG}${LED_REQUESTER_ID}${LED_IDENTITY_ID}${LED_RED_BLINK_ACTION0}${action_byte}${LED_RED_BLINK_ACTION2}${LED_RED_BLINK_ACTION3}${LED_RED_BLINK_ACTION4}${LED_RED_BLINK_ACTION5}${LED_RED_BLINK_ACTION6}${LED_RED_BLINK_ACTION7}${RED_LED_PRIORITY}${LED_SHOWTIME}${LED_TYPE}${LED_TIMEOUT}${LED_DESCRIPTION}`
    local ret=$?
    if [ $ret -ne 0 ]; then
        local err_msg=${led_reg_ack##*error:}
        echo "led_red_register ret=$ret, mb_ctrl fc $err_msg __fail"
        return 1
    fi

    raw_data=${led_reg_ack##*data:}
    local rr=`echo $raw_data | busybox awk '{printf $1}'`
    if [[ $rr != "00" && $rr != "0f" ]]; then
        echo "led_red_register fc $rr __fail"
        return 2
    fi

    result=`echo $raw_data | busybox awk '{printf $1;}'`
    red_requester_id=`echo $raw_data | busybox awk '{printf $2$3;}'`
    red_action_id=`echo $raw_data | busybox awk '{printf $5;}'`
    echo "led_red_register result=$result red_requester_id=$red_requester_id red_action_id=$red_action_id"

    red_action=$action

    if [ ! -d $LED_STATUS_DIR ]; then
	mkdir -p $LED_STATUS_DIR
    fi

    echo $red_requester_id > $LED_RED_REQ_ID_FILE
    echo $red_action_id > $LED_RED_ACTION_ID_FILE
    echo $red_action > $LED_RED_ACTION_FILE
    return 0
}

led_red_blink()
{
    led_red_action_register "blink"

    echo "led_red_blink enter"
    local r=`dji_mb_ctrl -S test -R diag -g 3 -t 6 -s 3 -c 0xbe 01${red_requester_id}${red_action_id}01`
    local ret=$?
    if [ $ret -ne 0 ]; then
        local err_msg=${r##*error:}
        echo "led_red_blink ret=$ret, mb_ctrl fc $err_msg __fail"
        return 1
    fi
    local k=${r##*data:}
    local rr=`echo $k | busybox awk '{printf $1}'`
    if [ $rr != "00" ]; then
        echo "led_red_blink fc $rr __fail"
        return 2
    fi
    echo "led_red_blink ok"
}

led_red_on()
{
    led_red_action_register "on"

    echo "led_red_on enter"
    local r=`dji_mb_ctrl -S test -R diag -g 3 -t 6 -s 3 -c 0xbe 01${red_requester_id}${red_action_id}01`
    local ret=$?
    if [ $ret -ne 0 ]; then
        local err_msg=${r##*error:}
        echo "led_red_on ret=$ret, mb_ctrl fc $err_msg __fail"
        return 1
    fi
    local k=${r##*data:}
    local rr=`echo $k | busybox awk '{printf $1}'`
    if [ $rr != "00" ]; then
        echo "led_red_on fc $rr __fail"
        return 2
    fi
    echo "led_red_on ok"
    return 0
}

blue_requester_id=00
blue_action_id=00
blue_action='none'

led_blue_action_unregister()
{
    echo "led_blue_action_unregister enter"
    local r=`dji_mb_ctrl -S test -R diag -g 3 -t 6 -s 3 -c 0xbd 0100${blue_requester_id}${blue_action_id}`
    local ret=$?
    if [ $ret -ne 0 ]; then
        local err_msg=${r##*error:}
        echo "led_blue_action_unregister ret=$ret, mb_ctrl fc $err_msg __fail"
        return 1
    fi
    local k=${r##*data:}
    local rr=`echo $k | busybox awk '{printf $1}'`
    if [ $rr != "00" ]; then
        echo "led_blue_action_unregister fc $rr __fail"
        return 2
    fi
    blue_action='none'
    blue_requester_id=00
    blue_action_id=00
    echo "led_blue_action_unregister ok"
    return 0
}

led_blue_action_register()
{
    local action_byte=00
    local action=$1
    case $action in
        "on")
            action_byte=$LED_BLUE_ON_ACTION1
            ;;
        "blink")
            action_byte=$LED_BLUE_BLINK_ACTION1
            ;;
    esac

    #higher priority
    if [ $green_action != "none" ]; then
        led_green_action_unregister
    fi

    if [ $red_action != "none" ]; then
        led_red_action_unregister
    fi

    if [ $blue_action == $action ]; then
        return 0
    else
        if [ $blue_action != "none" ]; then
            led_blue_action_unregister
        fi
    fi

    echo "led_blue_register enter"
    led_reg_ack=`dji_mb_ctrl -S test -R diag -g 3 -t 6 -s $FC_CMDSET -c $REGISTER_LED_CMDID ${LED_GENERIC_FLAG}${LED_REQUESTER_ID}${LED_IDENTITY_ID}${LED_BLUE_BLINK_ACTION0}${action_byte}${LED_BLUE_BLINK_ACTION2}${LED_BLUE_BLINK_ACTION3}${LED_BLUE_BLINK_ACTION4}${LED_BLUE_BLINK_ACTION5}${LED_BLUE_BLINK_ACTION6}${LED_BLUE_BLINK_ACTION7}${BLUE_LED_PRIORITY}${LED_SHOWTIME}${LED_TYPE}${LED_TIMEOUT}${LED_DESCRIPTION}`
    local ret=$?
    if [ $ret -ne 0 ]; then
        local err_msg=${led_reg_ack##*error:}
        echo "led_blue_register ret=$ret, mb_ctrl fc $err_msg __fail"
        return 1
    fi

    raw_data=${led_reg_ack##*data:}
    local rr=`echo $raw_data | busybox awk '{printf $1}'`
    if [[ $rr != "00" && $rr != "0f" ]]; then
        echo "led_blue_register fc $rr __fail"
        return 2
    fi

    result=`echo $raw_data | busybox awk '{printf $1;}'`
    blue_requester_id=`echo $raw_data | busybox awk '{printf $2$3;}'`
    blue_action_id=`echo $raw_data | busybox awk '{printf $5;}'`
    echo "led_blue_register result=$result blue_requester_id=$blue_requester_id blue_action_id=$blue_action_id"

    blue_action=$action

    if [ ! -d $LED_STATUS_DIR ]; then
	mkdir -p $LED_STATUS_DIR
    fi

    echo $blue_requester_id > $LED_BLUE_REQ_ID_FILE
    echo $blue_action_id > $LED_BLUE_ACTION_ID_FILE
    echo $blue_action > $LED_BLUE_ACTION_FILE
    return 0
}

led_blue_blink()
{
    led_blue_action_register "blink"

    echo "led_blue_blink enter"
    local r=`dji_mb_ctrl -S test -R diag -g 3 -t 6 -s 3 -c 0xbe 01${blue_requester_id}${blue_action_id}01`
    local ret=$?
    if [ $ret -ne 0 ]; then
        local err_msg=${r##*error:}
        echo "led_blue_blink ret=$ret, mb_ctrl fc $err_msg __fail"
        return 1
    fi
    local k=${r##*data:}
    local rr=`echo $k | busybox awk '{printf $1}'`
    if [ $rr != "00" ]; then
        echo "led_blue_blink fc $rr __fail"
        return 2
    fi
    echo "led_blue_blink ok"
}

led_blue_on()
{
    led_blue_action_register "on"

    echo "led_blue_on enter"
    local r=`dji_mb_ctrl -S test -R diag -g 3 -t 6 -s 3 -c 0xbe 01${blue_requester_id}${blue_action_id}01`
    local ret=$?
    if [ $ret -ne 0 ]; then
        local err_msg=${r##*error:}
        echo "led_blue_on ret=$ret, mb_ctrl fc $err_msg __fail"
        return 1
    fi
    local k=${r##*data:}
    local rr=`echo $k | busybox awk '{printf $1}'`
    if [ $rr != "00" ]; then
        echo "led_blue_on fc $rr __fail"
        return 2
    fi
    echo "led_blue_on ok"
    return 0
}

white_requester_id=00
white_action_id=00
white_action='none'

led_white_action_unregister()
{
    echo "led_white_action_unregister enter"
    local r=`dji_mb_ctrl -S test -R diag -g 3 -t 6 -s 3 -c 0xbd 0100${white_requester_id}${white_action_id}`
    local ret=$?
    if [ $ret -ne 0 ]; then
        local err_msg=${r##*error:}
        echo "led_white_action_unregister ret=$ret, mb_ctrl fc $err_msg __fail"
        return 1
    fi
    local k=${r##*data:}
    local rr=`echo $k | busybox awk '{printf $1}'`
    if [ $rr != "00" ]; then
        echo "led_white_action_unregister fc $rr __fail"
        return 2
    fi
    white_action='none'
    white_requester_id=00
    white_action_id=00
    echo "led_white_action_unregister ok"
    return 0
}

led_white_action_register()
{
    local action_byte=00
    local action=$1
    case $action in
        "on")
            action_byte=$LED_WHITE_ON_ACTION1
            ;;
        "blink")
            action_byte=$LED_WHITE_BLINK_ACTION1
            ;;
    esac

    #higher priority
    if [ $green_action != "none" ]; then
        led_green_action_unregister
    fi

    if [ $red_action != "none" ]; then
        led_red_action_unregister
    fi

    if [ $blue_action != "none" ]; then
        led_blue_action_unregister
    fi

    if [ $white_action == $action ]; then
        return 0
    else
        if [ $white_action != "none" ]; then
            led_white_action_unregister
        fi
    fi

    echo "led_white_register enter"
    led_reg_ack=`dji_mb_ctrl -S test -R diag -g 3 -t 6 -s $FC_CMDSET -c $REGISTER_LED_CMDID ${LED_GENERIC_FLAG}${LED_REQUESTER_ID}${LED_IDENTITY_ID}${LED_WHITE_BLINK_ACTION0}${action_byte}${LED_WHITE_BLINK_ACTION2}${LED_WHITE_BLINK_ACTION3}${LED_WHITE_BLINK_ACTION4}${LED_WHITE_BLINK_ACTION5}${LED_WHITE_BLINK_ACTION6}${LED_WHITE_BLINK_ACTION7}${WHITE_LED_PRIORITY}${LED_SHOWTIME}${LED_TYPE}${LED_TIMEOUT}${LED_DESCRIPTION}`
    local ret=$?
    if [ $ret -ne 0 ]; then
        local err_msg=${led_reg_ack##*error:}
        echo "led_white_register ret=$ret, mb_ctrl fc $err_msg __fail"
        return 1
    fi

    raw_data=${led_reg_ack##*data:}
    local rr=`echo $raw_data | busybox awk '{printf $1}'`
    if [[ $rr != "00" && $rr != "0f" ]]; then
        echo "led_white_register fc $rr __fail"
        return 2
    fi

    result=`echo $raw_data | busybox awk '{printf $1;}'`
    white_requester_id=`echo $raw_data | busybox awk '{printf $2$3;}'`
    white_action_id=`echo $raw_data | busybox awk '{printf $5;}'`
    echo "led_white_register result=$result white_requester_id=$white_requester_id white_action_id=$white_action_id"

    white_action=$action

    if [ ! -d $LED_STATUS_DIR ]; then
	mkdir -p $LED_STATUS_DIR
    fi

    echo $white_requester_id > $LED_WHITE_REQ_ID_FILE
    echo $white_action_id > $LED_WHITE_ACTION_ID_FILE
    echo $white_action > $LED_WHITE_ACTION_FILE
    return 0
}

led_white_blink()
{
    led_white_action_register "blink"

    echo "led_white_blink enter"
    local r=`dji_mb_ctrl -S test -R diag -g 3 -t 6 -s 3 -c 0xbe 01${white_requester_id}${white_action_id}01`
    local ret=$?
    if [ $ret -ne 0 ]; then
        local err_msg=${r##*error:}
        echo "led_white_blink ret=$ret, mb_ctrl fc $err_msg __fail"
        return 1
    fi
    local k=${r##*data:}
    local rr=`echo $k | busybox awk '{printf $1}'`
    if [ $rr != "00" ]; then
        echo "led_white_blink fc $rr __fail"
        return 2
    fi
    echo "led_white_blink ok"
}

led_white_on()
{
    led_white_action_register "on"

    echo "led_white_on enter"
    local r=`dji_mb_ctrl -S test -R diag -g 3 -t 6 -s 3 -c 0xbe 01${white_requester_id}${white_action_id}01`
    local ret=$?
    if [ $ret -ne 0 ]; then
        local err_msg=${r##*error:}
        echo "led_white_on ret=$ret, mb_ctrl fc $err_msg __fail"
        return 1
    fi
    local k=${r##*data:}
    local rr=`echo $k | busybox awk '{printf $1}'`
    if [ $rr != "00" ]; then
        echo "led_white_on fc $rr __fail"
        return 2
    fi
    echo "led_white_on ok"
    return 0
}

led_testing()
{
    led_green_on
    sleep 5
    led_red_on
    sleep 5
    led_blue_on
    sleep 5
    led_white_on
    sleep 5
    led_white_action_unregister
}

led_green_off()
{
    if [ -e $LED_GREEN_REQ_ID_FILE -a -e $LED_GREEN_ACTION_ID_FILE -a -e $LED_GREEN_ACTION_FILE ]; then
        green_requester_id=`cat $LED_GREEN_REQ_ID_FILE`
        green_action_id=`cat $LED_GREEN_ACTION_ID_FILE`
	green_action=`cat $LED_GREEN_ACTION_FILE`

	led_green_action_unregister
    else
	echo "led_green_off state file not exist"
    fi
}

led_red_off()
{
    if [ -e $LED_RED_REQ_ID_FILE -a -e $LED_RED_ACTION_ID_FILE -a -e $LED_RED_ACTION_FILE ]; then
        red_requester_id=`cat $LED_RED_REQ_ID_FILE`
        red_action_id=`cat $LED_RED_ACTION_ID_FILE`
	red_action=`cat $LED_RED_ACTION_FILE`

	led_red_action_unregister
    else
	echo "led_red_off state file not exist"
    fi
}

led_blue_off()
{
    if [ -e $LED_BLUE_REQ_ID_FILE -a -e $LED_BLUE_ACTION_ID_FILE -a -e $LED_BLUE_ACTION_FILE ]; then
        blue_requester_id=`cat $LED_BLUE_REQ_ID_FILE`
        blue_action_id=`cat $LED_BLUE_ACTION_ID_FILE`
	blue_action=`cat $LED_BLUE_ACTION_FILE`

	led_blue_action_unregister
    else
	echo "led_blue_off state file not exist"
    fi
}

led_white_off()
{
    if [ -e $LED_WHITE_REQ_ID_FILE -a -e $LED_WHITE_ACTION_ID_FILE -a -e $LED_WHITE_ACTION_FILE ]; then
        white_requester_id=`cat $LED_WHITE_REQ_ID_FILE`
        white_action_id=`cat $LED_WHITE_ACTION_ID_FILE`
	white_action=`cat $LED_WHITE_ACTION_FILE`

	led_white_action_unregister
    else
	echo "led_white_off state file not exist"
    fi
}
