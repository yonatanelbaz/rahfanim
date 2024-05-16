#!/bin/sh
get_service_log(){
    log_dir=/tmp/NFZ/log/system
    dji_network_log_name=dji_network.log
    dji_sw_uav_log_name=dji_sw_uav.log
    dji_hdvt_uav_log_name=dji_hdvt_uav.log
    dji_sys_log_name=dji_sys.log
    dji_navigation_log_name=dji_navigation.log

    dji_network_pid=`cat /tmp/dji_network.pid`
    dji_sw_uav_pid=`cat /tmp/dji_sw_uav.pid`
    dji_hdvt_uav_pid=`cat /tmp/dji_hdvt_uav.pid`
    dji_sys_pid=`cat /tmp/dji_sys.pid`
    dji_navigation_pid=`cat /tmp/dji_navigation.pid`

    if [ "${dji_network_pid}"x = ""x ]; then
        dji_network_pid=`pidof dji_network`
    fi
    if [ "${dji_sw_uav_pid}"x = ""x ]; then
        dji_sw_uav_pid=`pidof dji_sw_uav`
    fi
    if [ "${dji_hdvt_uav_pid}"x = ""x ]; then
        dji_hdvt_uav_pid=`pidof dji_hdvt_uav`
    fi
    if [ "${dji_sys_pid}"x = ""x ]; then
        dji_sys_pid=`pidof dji_sys`
    fi
    if [ "${dji_navigation_pid}"x = ""x ]; then
        dji_navigation_pid=`pidof dji_navigation`
    fi

    tmp_log=/tmp/other.log
    logread >> ${tmp_log}

    # dji_network
    log_name=${dji_network_log_name}
    cat ${tmp_log} | grep "duss\[${dji_network_pid}\]" >> ${log_dir}/${log_name}

    # dji_sw_uav
    log_name=${dji_sw_uav_log_name}
    cat ${tmp_log} | grep "duss\[${dji_sw_uav_pid}\]" >> ${log_dir}/${log_name}

    # dji_hdvt_uav
    log_name=${dji_hdvt_uav_log_name}
    cat ${tmp_log} | grep "duss\[${dji_hdvt_uav_pid}\]" >> ${log_dir}/${log_name}

    # dji_sys
    log_name=${dji_sys_log_name}
    cat ${tmp_log} | grep "duss\[${dji_sys_pid}\]" >> ${log_dir}/${log_name}

    # dji_navigation
    log_name=${dji_navigation_log_name}
    cat ${tmp_log} | grep "duss\[${dji_navigation_pid}\]" >> ${log_dir}/${log_name}

    sed -i '/duss\['${dji_network_pid}'\]/d;/duss\['${dji_sw_uav_pid}'\]/d;/duss\['${dji_hdvt_uav_pid}'\]/d;/duss\['${dji_sys_pid}'\]/d;/duss\['${dji_navigation_pid}'\]/d' ${tmp_log}

    dji_network_pid=`pidof dji_network`
    dji_sw_uav_pid=`pidof dji_sw_uav`
    dji_hdvt_uav_pid=`pidof dji_hdvt_uav`
    dji_sys_pid=`pidof dji_sys`
    dji_navigation_pid=`pidof dji_navigation`

    echo ${dji_network_pid} > /tmp/dji_network.pid
    echo ${dji_sw_uav_pid} > /tmp/dji_sw_uav.pid
    echo ${dji_hdvt_uav_pid} > /tmp/dji_hdvt_uav.pid
    echo ${dji_sys_pid} > /tmp/dji_sys.pid
    echo ${dji_navigation_pid} > /tmp/dji_navigation.pid
}

sleep 2
get_service_log > /dev/null 2>&1