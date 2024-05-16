#!/bin/sh
get_kernel_log(){
    log_num='.lognum'
    log_dir=/tmp/NFZ/log/system

    cur_num=`cat ${log_dir}/${log_num}`
    log_name=kernel.log.${cur_num}

    dmesg -c >> ${log_dir}/${log_name}
}

sleep 1
get_kernel_log > /dev/null 2>&1
