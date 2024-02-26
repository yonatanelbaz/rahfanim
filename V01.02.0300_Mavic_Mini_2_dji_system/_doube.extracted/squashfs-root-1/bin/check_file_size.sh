#!/bin/sh

log_dir=/tmp/NFZ/log/system

log_name=dji_network.log
file_size=`wc -c < ${log_dir}/${log_name}`
if [ ${file_size} -gt 2097152 ]; then
    mv ${log_dir}/${log_name} ${log_dir}/${log_name}.pre
    echo '' > ${log_dir}/${log_name}
fi

log_name=dji_sw_uav.log
file_size=`wc -c < ${log_dir}/${log_name}`
if [ ${file_size} -gt 2097152 ]; then
    mv ${log_dir}/${log_name} ${log_dir}/${log_name}.pre
    echo '' > ${log_dir}/${log_name}
fi

log_name=dji_hdvt_uav.log
file_size=`wc -c < ${log_dir}/${log_name}`
if [ ${file_size} -gt 2097152 ]; then
    mv ${log_dir}/${log_name} ${log_dir}/${log_name}.pre
    echo '' > ${log_dir}/${log_name}
fi

log_name=dji_sys.log
file_size=`wc -c < ${log_dir}/${log_name}`
if [ ${file_size} -gt 2097152 ]; then
    mv ${log_dir}/${log_name} ${log_dir}/${log_name}.pre
    echo '' > ${log_dir}/${log_name}
fi

log_name=dji_navigation.log
file_size=`wc -c < ${log_dir}/${log_name}`
if [ ${file_size} -gt 2097152 ]; then
    mv ${log_dir}/${log_name} ${log_dir}/${log_name}.pre
    echo '' > ${log_dir}/${log_name}
fi

log_name=mem_statistic_data.log
file_size=`wc -c < ${log_dir}/${log_name}`
if [ ${file_size} -gt 2097152 ]; then
    mv ${log_dir}/${log_name} ${log_dir}/${log_name}.pre
    echo '' > ${log_dir}/${log_name}
fi

log_name=top.log
file_size=`wc -c < ${log_dir}/${log_name}`
if [ ${file_size} -gt 2097152 ]; then
    mv ${log_dir}/${log_name} ${log_dir}/${log_name}.pre
    echo '' > ${log_dir}/${log_name}
fi