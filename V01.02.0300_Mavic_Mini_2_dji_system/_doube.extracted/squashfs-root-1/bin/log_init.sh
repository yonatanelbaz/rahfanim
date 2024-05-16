#!/bin/sh

save_to_sd(){
	log_dir=/tmp/blackbox/log/system
	sd_dir=/tmp/SD0/log/system
	df | grep "/tmp/SD0"
	if [ $? == 0 ]; then
		mkdir -p ${sd_dir}
		cd /tmp/blackbox/log
		date > date_time
		sed -i "s/://g" date_time
		sed -i "s/-//g" date_time
		sed -i "s/\.//g" date_time
		tarName="system-`cat date_time`.tar.gz"
		tar zcvf ${tarName} system/
		cp ${tarName} ${sd_dir}/${tarName}
		nfz_log_md5=`md5sum ${tarName} | cut -d ' ' -f1`
		sdo_log_md5=`md5sum ${sd_dir}/${tarName} | cut -d ' ' -f1`
		if [ "${nfz_log_md5}"x = "${sdo_log_md5}"x ]; then
			rm -rf ${log_dir}/*
		else
			echo "${tarName} copy to SD0 error" >> ${log_dir}/log_copy.log
		fi
		rm ${tarName}
		rm date_time
		cd -
	fi
}

echo 0 > /proc/sys/vm/swappiness
echo 308 > /proc/sys/vm/min_free_kbytes

echo 4000 > /proc/sys/net/unix/max_dgram_qlen
echo 4000 > /proc/sys/net/core/netdev_budget
echo 4000 > /proc/sys/net/unix/netdev_max_backlog
echo 1048576 > /proc/sys/net/core/wmem_max
echo 1048576 > /proc/sys/net/core/rmem_max

log_dir=/tmp/blackbox/log/system
mkdir -p ${log_dir}

if [ -f ${log_dir}/current_time ]; then
	date -s `cat ${log_dir}/current_time`
fi

# save_to_sd
kernel_ver=$(uname -a)
log_start_tag="+++++++++++++++wm160-linux-start: `date` ++++++++++++++++++++"

echo -e "\n\n${log_start_tag}\n\n" >> ${log_dir}/syslog.log
echo ${kernel_ver} >> ${log_dir}/syslog.log
