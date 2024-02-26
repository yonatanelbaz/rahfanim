#!/bin/sh
get_service_log(){
    log_dir=/tmp/blackbox/log/system
    log_name=syslog.log
    logread >> ${log_dir}/${log_name}
}

check_file_size(){
    log_dir=/tmp/blackbox/log/system
    log_name=syslog.log

    file_size=`wc -c < ${log_dir}/${log_name}`
    if [ ${file_size} -gt 52428800 ]; then
        mv ${log_dir}/${log_name} ${log_dir}/${log_name}.pre
        echo '' > ${log_dir}/${log_name}
    fi
}

get_statistic(){
    log_dir=/tmp/blackbox/log/system
    log_name=top.log

    date >> ${log_dir}/${log_name}
    top -n 1 >> ${log_dir}/${log_name}
}

i_m=1
i_ch=1
log_dir=/tmp/blackbox/log/system

while true
do
    echo 3 > /proc/sys/vm/drop_caches
    if [[ $i_m -ge 3 ]];then
        i_m=0
        get_statistic &
    fi
    if [[ $i_ch -ge 15 ]];then
        i_ch=0
        check_file_size &
    fi
    get_service_log &
    date > /dev/kmsg &
    date > ${log_dir}/current_time &
    let i_m++
    let i_ch++
    sleep 4
done