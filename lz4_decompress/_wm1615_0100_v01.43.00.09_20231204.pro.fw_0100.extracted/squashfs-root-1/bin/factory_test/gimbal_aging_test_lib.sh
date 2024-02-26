#!/bin/sh

start_gimbal_aging_test()
{
    local n=0
    local retry=3
    while [ $n -lt $retry ]; do
        let n+=1
        result=`dji_mb_ctrl -S test -R diag -g 4 -t 0 -s 0 -c 0xf4 -1 1`
        if [ $? == 0 ]; then
            return 0
        fi
    done
    return 1
}

stop_gimbal_aging_test()
{
    echo "stop gimbal aging test"
    result=`dji_mb_ctrl -S test -R diag -g 4 -t 0 -s 0 -c 0xf5`
    if [ $? == 0 ]; then
        return 0
    else
        return 1
    fi
}

get_gimbal_aging_test_result()
{
    local n=0
    local retry=10
    while [ $n -lt $retry ]; do
        let n+=1
        info=`dji_mb_ctrl -S test -R diag -g 4 -t 0 -s 0 -c 0xf6`
        if [ $? != 0 ]; then
            echo "gimbal aging test get result, send cmd fail"
            sleep 1
            continue
        fi
        resp_data=${info##*data:}
        result=`echo $resp_data | busybox awk '{print $2}'`
        val=`echo $resp_data | busybox awk '{print $3}'`
        if [ $result != "00" ]; then
            echo "gimbal aging test get result fail, resp data is $result, error data is $val, _test_fail"
            return 2
        else
            echo "gimbal aging test get result success"
            return 0
        fi
    done

    echo "gimbal aging test get result fail, exit"
    return 1
}

gimbal_aging_test_status='READY'

gimbal_aging_test()
{
    case $gimbal_aging_test_status in
        'READY')
            start_gimbal_aging_test
            ret=$?
            if [ $ret -eq 0 ]; then
                echo "start gimbal aging test success"
                gimbal_aging_test_status='ONGOING'
                return 0
            else
                echo "start gimbal aging _test_fail"
                gimbal_aging_test_status='FAIL'
                stop_gimbal_aging_test
                return 3
            fi
            ;;
        'ONGOING')
            get_gimbal_aging_test_result
            ret=$?
            if [ $ret -eq 0 ]; then
                echo "gimbal aging test running"
                return 0
            else
                echo "gimbal aging _test_fail"
                gimbal_aging_test_status='FAIL'
                stop_gimbal_aging_test
                return 3
            fi
            ;;
        'PASS')
            return 0
            ;;
        'FAIL')
            echo "gimbal aging _test_fail"
            return 3
            ;;
    esac
}
