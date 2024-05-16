#!/bin/sh

. /usr/bin/factory_test/fc_led_ctrl.sh
. /usr/bin/factory_test/camera_aging_test_lib.sh
. /usr/bin/factory_test/gimbal_aging_test_lib.sh
. /usr/bin/factory_test/perception_aging_test_lib.sh

timeout=0
retry_count_default=5
aging_test_script_dir=/usr/bin/factory_test/
aging_test_flag_file=/tmp/EMMC/factory_test/AGING_TEST
aging_test_log_file_sd0_dir=/tmp/SD0/factory_test/
aging_test_log_file_nfz_dir=/tmp/blackbox/log/factory_test/
aging_test_log_file=aging_test.log
aging_test_result_file=/tmp/blackbox/log/factory_test/aging_log_result.log
aging_result_file=/tmp/blackbox/log/factory_test/aging_result.log
test_flag=0
test_items_num=7

get_cur_time()
{
    local now=`cat /proc/uptime | busybox awk -F. '{printf $1}'`
    echo $now
}

get_module_version()
{
    module=$1
    index=$2

    result=`dji_mb_ctrl -R diag -g $module -t $index -s 0 -c 1`
    ret=$?

    if [ $ret -ne 0 ]; then
        echo "dji_mb_ctrl error, ret=$ret"
        return 1
    fi

    data=${result##*data:}
    ver0=`echo $data | awk '{printf $26}'`
    ver1=`echo $data | awk '{printf $25}'`
    ver2=`echo $data | awk '{printf $24}'`
    ver3=`echo $data | awk '{printf $23}'`

    version=`echo 0x$ver0 0x$ver1 0x$ver2 0x$ver3 | awk '{printf("%.2d.%.2d.%.2d.%.2d", $1, $2, $3, $4)}'`

    echo $version
    return 0
}

get_package_version()
{
    package_cfg_file='/tmp/BACKUP/cfg_ready.sig'
    if [ -e $package_cfg_file ]; then
        version_str=`cat $package_cfg_file | grep 'firmware formal'`
        version=`echo $version_str | awk -F\" '{printf $2}'`
        echo $version
        return 0
    else
        return 1
    fi
}

output_version()
{
    echo ''
    echo '************** Verion **************'

    package_version=`get_package_version`
    if [ $? -eq 0 ]; then
        echo " package version: $package_version"
    fi

    camera_version=`get_module_version 1 0`
    if [ $? -eq 0 ]; then
        echo " camera version : $camera_version"
    fi

    wait_fc_led_avliable > /dev/null 2>&1

    fc_version=`get_module_version 3 6`
    if [ $? -eq 0 ]; then
        echo " fc version     : $fc_version"
    fi

    gimbal_version=`get_module_version 4 0`
    if [ $? -eq 0 ]; then
        echo " gimbal version : $gimbal_version"
    fi

    echo '************************************'
    echo ''
}

wait_sd_mounted()
{
    sd_mount_result=1
    local time_count=0

    while true; do
        df | grep SD0
        if [ $? -eq 0 ]; then
            sd_mount_result=0
            break
        else
            sleep 1
            time_count=$(($time_count+1))
        fi
        if [ $time_count -ge 10 ]; then
            break
        fi
    done

    return $sd_mount_result
}

redirecting_log_output_to_SD0()
{
    wait_sd_mounted

    if [ $? -eq 0 ]; then
        echo "sdcard exists, save the log to $aging_test_log_file."
        if [ ! -d $aging_test_log_file_sd0_dir ]; then
            echo "mkdir log file"
            mkdir $aging_test_log_file_sd0_dir
            sleep 1
        fi
        exec 1>$aging_test_log_file_sd0_dir$aging_test_log_file 2>&1
    else
        echo "no sdcard, output the log to /dev/null."
        exec 1>/dev/null 2>&1
   fi
}

redirecting_log_output_to_blackbox()
{
    df | grep blackbox

    if [ $? -eq 0 ]; then
        if [ ! -d $aging_test_log_file_nfz_dir ]; then
            echo "mkdir log file"
            mkdir $aging_test_log_file_nfz_dir
            sleep 1
        fi
        exec 1>$aging_test_log_file_nfz_dir$aging_test_log_file 2>&1
    else
        redirecting_log_output_to_SD0
    fi
}

redirecting_log_output_to_console()
{
    exec 1>/dev/console 2>&1
    sleep 1
}

cp_log_file_to_sd0()
{
    echo 'cp log file to sd0' > $aging_test_result_file
    if [ -e $aging_test_log_file_nfz_dir$aging_test_log_file ]; then
        wait_sd_mounted
        if [ $? -eq 0 ]; then
            if [ -e $aging_test_log_file_sd0_dir$aging_test_log_file ]; then
                echo "rm old log file" >> $aging_test_result_file
                rm $aging_test_log_file_sd0_dir$aging_test_log_file
            fi

            if [ ! -d $aging_test_log_file_sd0_dir ]; then
                mkdir -p $aging_test_log_file_sd0_dir
            fi

            if [ -e $aging_test_log_file_sd0_dir$aging_test_log_file ]; then
                rm -f $aging_test_log_file_sd0_dir$aging_test_log_file
            fi

            echo "cp $aging_test_log_file_nfz_dir$aging_test_log_file to SD0" >> $aging_test_result_file

            cp $aging_test_log_file_nfz_dir$aging_test_log_file $aging_test_log_file_sd0_dir$aging_test_log_file -r

            if [ $? -eq 0 ]; then
                echo "cp log file to SD0 successfully" >> $aging_test_result_file
            else
                echo "cp log file to SD0 failed" >> $aging_test_result_file
            fi
        else
            echo "no SD card" >> $aging_test_result_file
        fi
    else
        echo "$aging_test_log_file_nfz_dir$aging_test_log_file not exist" >> $aging_test_result_file
    fi
}

clear_old_log_file()
{
    if [ -e $aging_test_log_file_nfz_dir$aging_test_log_file ]; then
        echo "rm old log file"
        rm $aging_test_log_file_nfz_dir$aging_test_log_file
    fi

    if [ -e $aging_test_result_file ]; then
        echo "rm old log result file"
        rm $aging_test_result_file
    fi

    if [ -e $aging_result_file ]; then
        echo "rm old result file"
        rm $aging_result_file
    fi
}

################################
#   Test items bitmask
#
#   bit 0: ddr
#   bit 1: sdcard
#   bit 2: network
#   bit 3: fc
#   bit 4: gimbal
#   bit 5: camera
#   bit 6: perception
#
################################

get_bit_name()
{
    case $1 in
        0)  echo -n "test_ddr" ;;
        1)  echo -n "test_sdcard" ;;
        2)  echo -n "test_network";;
        3)  echo -n "test_fc" ;;
        4)  echo -n "test_gimbal" ;;
        5)  echo -n "test_camera" ;;
        6)  echo -n "test_perception" ;;
        *)  echo -n "unknown" ;;
    esac
}

parse_timeout_from_file()
{
    file=$1
    timeout=`cat $file | awk '/^[0-9]+$/'`
    if [ -z "$timeout" ]; then
        timeout=7200
    fi
    echo $timeout
}

camera_aging_finish_flag=0
test_camera_status()
{
    camera_aging_test
    ret=$?
    case $ret in
        $READY|$ONGOING)
            return 0
            ;;
        $PASS)
            camera_aging_finish_flag=1
            return 0
            ;;
        $FAIL)
            camera_aging_finish_flag=1
            return 2      #1 is used for 'time out'
            ;;
    esac
}

test_gimbal_status()
{
    case $1 in
        'test')
            gimbal_aging_test
            ;;
        'exit')
            stop_gimbal_aging_test
            ;;
    esac
    return $?
}

exe_test_items()
{
    case $1 in
        0)  echo "test_ddr"
            ddr_test.sh
            ;;
        1)  #echo "test_sdcard"
            #sdcard_link_test.sh
            ;;
        2)  #echo "test_network"
            #test_network_status.sh
            ;;
        3)  echo "test_fc"
            test_fc_status.sh no_battery
            ;;
        4)  echo "test_gimbal"
            test_gimbal_status 'test'
            ;;
        5)  echo "test_camera"
            test_camera_status
            ;;
        6)  echo "test_perception"
            test_perception_status.sh all
            ;;
        *)  echo "unknow params"
            ;;
    esac
    return $?
}

led_ctrl()
{
    #TODO: add fc_led register and ctrl
    case $1 in
        "testing")
                #(green & green) blink
                led_green_blink
                ;;
        "testing_and_fail")
                #(red & red) blink
                led_red_blink
                ;;
        "finished_and_fail")
                #(red & red) light
                led_red_on
                ;;
        "finished_and_success")
                #(green & green) light
                led_green_on
                ;;
        *)
                echo "unknow params"
                ;;
    esac
}

aging_test()
{
    local items_num=$1
    local items_bit=$2
    for i in `seq 0 $(($items_num-1))`; do
        bit_mask=$((1 << $i))
        bit_result=$(($bit_mask&$items_bit))
        if [ $bit_result != 0 ]; then
            retry_count=$retry_count_default
            while true; do
                exe_test_items $i > /tmp/aging_tmp 2>&1
                ret=$?
                result=`cat /tmp/aging_tmp`
                # timeout, retry
                if [ $ret -eq 1 ]; then
                    if [ $retry_count -ge 0 ]; then
                        retry_count=$(($retry_count-1))
                        sleep 1
                        continue
                    fi
                fi
                echo "$result"
                break
            done
            if [ $ret -ne 0 ]; then
                test_name=`get_bit_name $i`
                echo "[ $test_name ] test fail, remove it, cur time: `date`, uptime: `get_cur_time`"
                items_bit=$((items_bit&~$bit_mask))
                break
            fi
        fi
    done

    return $items_bit
}

#########################################################################
# aging test
#
# USAGE:
#   - aging_test.sh [t] [force_test]
#
# DESCRIPTION:
#   The script will run some scripts for the loop until timeout or all
#   script have running failed.
#
# OPTIONS:
#   [t]:          - Running time, the script will be stopped when the
#                   time is up.
#                 - Unit: seconds.
#                 - Non-essentilal param. The script will run 7200s if
#                   you don't input the param.
#
#   [force_test]: - Force test flag, the script will check whether the
#                   flag file /tmp/EMMC/factory_test/AGING_TEST is exist
#                   or not first, if it exist, and run the test, or do
#                   do nothing.
#                   Of course you also can force start the test when you
#                   set the param to "test".
#                 - Non-essentilal param. The script will check the flag
#                   file if you don't input the param.
#
# EXIT STATUS
#   0:            - Exec successfully
#   1:            - Not running test, maybe no flag file
#   2:            - Test finished and fail.
#   3:            - Illegal params.
#
# NOTES:
#  The script will check the flag file before running test and will remove
#  the flag file after running finished if the flag file exist. If you only
#  want to test the aging test script, you can use [force_test] param.
#
#########################################################################

main(){
    ret_code=0
    export PATH=$PATH:$aging_test_script_dir

    case $# in
        0)  echo "parse timeout from file"
            ;;
        1)  digital_flag=`echo $1 | awk '/^[0-9]+$/'`
            echo $digital_flag
            if [ $digital_flag != "" ]; then
                timeout=$digital_flag
            fi
            ;;
        2)  digital_flag=`echo $1 | awk '/^[0-9]+$/'`
            if [ $digital_flag != "" ]; then
                timeout=$digital_flag
            fi
            if [ $2 == "test" ]; then
                test_flag=1
            fi
            ;;
        *)  echo "error params"
            exit 3
            ;;
    esac

    if [[ ! -e $aging_test_flag_file ]]; then
        if [ $test_flag -eq 0 ]; then
            echo "no $aging_test_flag_file exists, no force test flag param input, aging_test exit"
            exit 1
        fi
    else
        if [ $timeout -eq 0 ]; then
            timeout=`parse_timeout_from_file $aging_test_flag_file`
        fi
    fi

    clear_old_log_file

    redirecting_log_output_to_blackbox

    echo 'abort' > $aging_result_file

    output_version

    echo "aging startup time: `date`"
    echo "running timeout: $timeout"

    aging_start_time=$(get_cur_time)
    aging_end_time=$(($aging_start_time+$timeout))

    test_items_bit=1

    for i in `seq 0 $(($test_items_num-1))`; do
        test_items_bit=$(($test_items_bit<<1|1))
    done

    cur_time=$(get_cur_time)

    wait_fc_led_avliable

    led_ctrl 'testing'
    rel_test_items_bit=$test_items_bit
    last_rel_test_items_bit=$test_items_bit

    testing_and_fail_flag=false

    if [ -e $aging_test_flag_file ]; then
        echo "remove aging test flag file"
        rm $aging_test_flag_file
    fi

    while [[ $testing_and_fail_flag == false && $cur_time -lt $aging_end_time && $rel_test_items_bit -ne 0 ]]; do
        echo "cur time: `date`, uptime: `get_cur_time`, size: `du -hs /tmp/blackbox`"
        aging_test $test_items_num $rel_test_items_bit
        rel_test_items_bit=$?
        cur_time=$(get_cur_time)
        if [ $last_rel_test_items_bit -ne $rel_test_items_bit ]; then
            last_rel_test_items_bit=$rel_test_items_bit
            if [ $testing_and_fail_flag == false ]; then
                testing_and_fail_flag=true
                led_ctrl 'testing_and_fail'
                sleep 1
            fi
        fi
    done

    # timeout logic for camera aging test
    local camera_aging_test_result=0
    if [[ $testing_and_fail_flag == false && $camera_aging_finish_flag -eq 0 ]]; then
        if [[ $cur_time -ge $aging_end_time ]]; then
            echo "camera aging test not finished, wait at most 5min"
            aging_end_time=$((aging_end_time+5*60))
            while [[ $cur_time -lt $aging_end_time && $camera_aging_finish_flag -ne 1 ]]; do
                test_camera_status
                ret=$?
                if [ $ret -ne 0 ]; then
                    camera_aging_test_result=1
                    break
                fi
                sleep 10
                cur_time=$(get_cur_time)
            done
        fi

        if [ $cur_time -ge $aging_end_time ]; then
            echo "waitting camera aging finish timeout, camera aging test fail"
            camera_aging_test_result=1
        fi
    fi

    if [[ $((($rel_test_items_bit >> 5) & 0x1)) -eq 0 ]]; then
        camera_aging_test_result=1
    fi

    if [[ $camera_aging_test_result -eq 0 ]]; then
        echo "camera aging _test_success"
    else
        echo "camera aging _test_fail"
    fi

    #analyse log
    #analyse_perception_log
    preception_analysis_result=0

    led_ctrl_string='finished_and_success'

    if [[ $test_items_bit -ne $rel_test_items_bit || $camera_aging_test_result -eq 1 || $preception_analysis_result -eq 1 ]]; then
        echo "aging test finished and fail"
        echo "aging test finished and fail" > $aging_result_file
        led_ctrl_string='finished_and_fail'
        ret_code=2
    else
        echo "aging test finished and success"
        echo "aging test finished and success" > $aging_result_file
        led_ctrl_string='finished_and_success'
        ret_code=0
    fi

    #stop all test
    test_gimbal_status 'exit'

    redirecting_log_output_to_console

    cp_log_file_to_sd0 &

    sleep 30

    led_ctrl $led_ctrl_string

    exit $ret_code
}

main $@
