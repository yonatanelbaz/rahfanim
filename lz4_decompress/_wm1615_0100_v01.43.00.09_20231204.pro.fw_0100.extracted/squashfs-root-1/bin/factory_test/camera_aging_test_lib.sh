#!/bin/sh

global_seq_id=0
max_seq_id=$((0xffff))

generate_seq_id()
{
    if [ $global_seq_id -ge $max_seq_id ]; then
        global_seq_id=0
    fi
    global_seq_id=$(($global_seq_id+1))
}

start_camera_aging_test()
{
    local seq_id=$1
    result=`dji_mb_ctrl -R diag -q $seq_id -g 1 -t 0 -s 2 -c 0x90 051300000000`
    ret=$?
    if [ $ret -ne 0 ]; then
        err_msg=${result##*error:}
        echo "mb_ctrl error, $err_msg"
        return 1
    fi

    raw_data=${result##*data:}
    ret_code=`echo $raw_data | busybox awk '{printf $1}'`
    if [ $ret_code != "00" ]; then
        echo "start camera aging test cmd fail, ret_code=$raw_data"
        return 2
    fi
}

stop_camera_aging_test()
{
    echo "not support"
    return 3
}

parse_result_string()
{
    case $1 in
        "00")
            echo "init"
            ;;
        "01")
            echo "no_need"
            ;;
        "02")
            echo "ready"
            ;;
        "03")
            echo "start"
            ;;
        "10")
            echo "passed"
            ;;
        "11")
            echo "failed"
            ;;
        "20")
            echo "pass"
            ;;
        "21")
            echo "fail"
            ;;
        *)
            echo "Illegal param"
            return 3
            ;;
   esac
   return 0
}

get_result_camera_aging_test()
{
    local seq_id=$1
    result=`dji_mb_ctrl -R diag -q $seq_id -g 1 -t 0 -s 2 -c 0x90 051200000000`
    ret=$?
    if [ $ret -ne 0 ]; then
        err_msg=${result##*error:}
        echo "mb_ctrl error, $err_msg"
        return 1
    fi

    raw_data=${result##*data:}
    ret_code=`echo $raw_data | busybox awk '{printf $1}'`
    if [ $ret_code != "00" ]; then
        echo "get result camera aging test cmd fail, ret_code=$raw_data"
        return 2
    fi

    test_status=`echo $raw_data | busybox awk '{printf $2}'`

    echo $test_status
    return 0
}

READY=0
ONGOING=1
PASS=2
FAIL=4

aging_test_status=0

camera_aging_test()
{
    local seq_id
    case $aging_test_status in
        $READY)
            generate_seq_id
            result_code=`get_result_camera_aging_test $global_seq_id`
            result_string=`parse_result_string $result_code`
            echo "camera aging not start, get cur camera aging test result: $result_string"
            if [[ $result_string == 'init' ]]; then
                echo "cur status is init, retry get result until camera ready"
            elif [[ $result_string == 'ready' ]]; then
                echo "cur status is ready, ready to start camera aging test"
                generate_seq_id
                start_camera_aging_test $global_seq_id
                ret=$?
                if [ $ret -eq 0 ]; then
                    echo "start camera aging test success"
                    aging_test_status=$ONGOING
                else
                    echo "start camera aging test fail"
                    aging_test_status=$FAIL
                fi
            elif [[ "$result_string" == "start" ]]; then
                echo "cur status: $result_string camera, maybe camera aging be retriggered automatic."
                aging_test_status=$ONGOING
            elif [[ "$result_string" == "failed" || "$result_string" == "fail" ]]; then
                echo "cur status: $result_string, camera aging test fail."
                aging_test_status=$FAIL
            else
                echo "cur status: $result_string"
                aging_test_status=$FAIL
            fi
            ;;
        $ONGOING)
            generate_seq_id
            result_code=`get_result_camera_aging_test $global_seq_id`
            result_string=`parse_result_string $result_code`
            if [[ "$result_string" == "start" ]]; then
                echo "camera aging test running"
            elif [[ "$result_string" == "fail" ]]; then
                echo "camera aging test fail"
                aging_test_status=$FAIL
            elif [[ "$result_string" == "pass" ]]; then
                echo "camera aging test successfully"
                aging_test_status=$PASS
            else
                echo "cur status: $result_string"
            fi
            ;;
        $PASS)
            echo "camera aging test successfully"
            ;;
        $FAIL)
            echo "camera aging test fail"
            ;;
        esac

        return $aging_test_status
}
