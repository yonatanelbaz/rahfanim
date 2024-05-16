#!/bin/sh

perception_log_root_path=/tmp/blackbox/perception_log/

analyse_perception_log()
{
    num=`ls $perception_log_root_path | sort -r -n | head -n 1`
    cur_perception_log_file=$perception_log_root_path$num

    grep ',ERROR,' -r $cur_perception_log_file >> /dev/null 2>&1

    ret=$?
    if [ $ret -eq 0 ]; then
        echo 'perception log analysis result: _test_fail'
        return 1
    else
        echo 'perception log analysis result: _test_success'
        return 0
    fi
}
