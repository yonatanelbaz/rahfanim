#!/bin/sh
get_statistic(){
    log_dir=/tmp/NFZ/log/system
    log_name=mem_statistic_data.log
    top_log_name=top.log

    sleep 0.75
    date >> ${log_dir}/${log_name}
    # procrank >> ${log_dir}/${log_name}
    free >> ${log_dir}/${log_name}

    sleep 0.25
    date >> ${log_dir}/${top_log_name}
    top -n 1 >> ${log_dir}/${top_log_name}

    lxtotx=`cat /sys/devices/platform/ambalink/ambalink:ambarella-rproc/remoteproc0/virtio0/lxtotx`
    txtolx=`cat /sys/devices/platform/ambalink/ambalink:ambarella-rproc/remoteproc0/virtio0/txtolx`
    echo "rproc lxtotx: $lxtotx txtolx: $txtolx" >> ${log_dir}/${log_name}
}

get_statistic > /dev/null 2>&1
