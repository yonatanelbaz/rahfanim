#!/bin/sh
fly_dir='/tmp/blackbox/flyctrl'
sdrs_dir='/tmp/blackbox/sdrs_log'
sys_dir='/tmp/blackbox/log/system'
sys_factory_dir='/tmp/blackbox/log/factory_test'
nav_dir='/tmp/blackbox/navigation'
perception_dir='/tmp/blackbox/perception_log'

flylog_latest_file='/tmp/blackbox/flyctrl/latest'

log_config_dir='/tmp/EMMC/log_config'
partition_size_file='/tmp/EMMC/log_config/partition_size_file'
fc_log_size_file='/tmp/EMMC/log_config/fc_log_size_file'
nav_log_size_file='/tmp/EMMC/log_config/nav_log_size_file'
perception_log_size_file='/tmp/EMMC/log_config/perception_log_size_file'
sdrs_log_size_file='/tmp/EMMC/log_config/sdrs_log_size_file'
sys_log_size_file='/tmp/EMMC/log_config/sys_log_size_file'


blackbox_partion_threshod=80

if [ ! -d $log_config_dir ]; then
	mkdir -p $log_config_dir
fi

blackbox_partion_size=`df -h | grep "/tmp/blackbox" | awk '{print $2}' | cut -d "." -f1`
echo "$blackbox_partion_size" > $partition_size_file

fc_threshold=30000
nav_threshold=30000
perception_threshold=10000
sdrs_threshold=20000
sys_threshold=2000

if [ $blackbox_partion_size -lt 75 ] ; then
	fc_threshold=30000
	nav_threshold=5000
	perception_threshold=3000
	sdrs_threshold=20000
	sys_threshold=2000
fi

if [ ! -e $fc_log_size_file ]; then
	echo `expr $fc_threshold / 1000` > $fc_log_size_file
fi

if [ ! -e $nav_log_size_file ]; then
	echo `expr $nav_threshold / 1000` > $nav_log_size_file
fi

if [ ! -e $perception_log_size_file ]; then
	echo `expr $perception_threshold / 1000` > $perception_log_size_file
fi

if [ ! -e $sdrs_log_size_file ]; then
	echo `expr $sdrs_threshold / 1000` > $sdrs_log_size_file
fi

if [ ! -e $sys_log_size_file ]; then
	echo `expr $sys_threshold / 1000` > $sys_log_size_file
fi

function parseDir(){
	for file in `ls $1`
	do
		if [ -d $1"/"$file ]; then
			parseDir $1"/"$file
		else
			#echo $1"/"$file
			echo " " > $1"/"$file
		fi
	done
}

while [ true ]; do
	#init size parameters
	flyctrl_size=0
	sdrs_size=0
	sys_size=0
	coredump_files=0
	sys_factory_log_size=0
	nav_size=0
	perception_size=0

	#==============================================================================
	# check the threshod in files
	#==============================================================================
	check_fc_threshold=0
	check_nav_threshold=0
	check_perception_threshold=0
	check_sdrs_threshold=0
	check_sys_threshold=0

	if [ -e $fc_log_size_file ]; then
		check_fc_threshold=`cat $fc_log_size_file`
		check_fc_threshold=`expr $check_fc_threshold \* 1000`

		if [ $check_fc_threshold -ne $fc_threshold ]; then
			echo "fc log threshod change to $check_fc_threshold" > /dev/kmsg

			fc_threshold=$check_fc_threshold
		fi
	fi

	if [ -e $nav_log_size_file ]; then
		check_nav_threshold=`cat $nav_log_size_file`
		check_nav_threshold=`expr $check_nav_threshold \* 1000`

		if [ $check_nav_threshold -ne $nav_threshold ]; then
			echo "nav log threshod change to $check_nav_threshold" > /dev/kmsg

			nav_threshold=$check_nav_threshold
		fi
	fi

	if [ -e $perception_log_size_file ]; then
		check_perception_threshold=`cat $perception_log_size_file`
		check_perception_threshold=`expr $check_perception_threshold \* 1000`

		if [ $check_perception_threshold -ne $perception_threshold ]; then
			echo "perception log threshod change to $check_perception_threshold" > /dev/kmsg

			perception_threshold=$check_perception_threshold
		fi
	fi

	if [ -e $sdrs_log_size_file ]; then
		check_sdrs_threshold=`cat $sdrs_log_size_file`
		check_sdrs_threshold=`expr $check_sdrs_threshold \* 1000`

		if [ $check_sdrs_threshold -ne $sdrs_threshold ]; then
			echo "sdrs log threshod change to $check_sdrs_threshold" > /dev/kmsg

			sdrs_threshold=$check_sdrs_threshold
		fi
	fi

	if [ -e $sys_log_size_file ]; then
		check_sys_threshold=`cat $sys_log_size_file`
		check_sys_threshold=`expr $check_sys_threshold \* 1000`

		if [ $check_sys_threshold -ne $sys_threshold ]; then
			echo "sys log threshod change to $check_sys_threshold" > /dev/kmsg

			sys_threshold=$check_sys_threshold

			kill -9 `pidof syslogd`
			syslogd -S -O /tmp/blackbox/log/system/syslog.log -s $sys_threshold
		fi
	fi

	#==============================================================================
	# blackbox log size check
	#==============================================================================
	#get size in KB
	if [ -d $fly_dir ]; then
		flyctrl_size=`du -s $fly_dir | awk '{print $1}'`
		echo "bb_monitor : flyctrl log size=$flyctrl_size"
	fi

	if [ -d $sdrs_dir ]; then
		sdrs_size=`du -s $sdrs_dir | awk '{print $1}'`
		echo "bb_monitor : sdrs log size=$sdrs_size"
	fi

	if [ -d $sys_dir ]; then
		sys_size=`du -s $sys_dir | awk '{print $1}'`
		coredump_files=`find $sys_dir -name "core*" | wc -l`
		echo "bb_monitor : sys log size=$sys_size"
		echo "bb_monitor : coredump files=$coredump_files"
	fi

	if [ -d $sys_factory_dir ]; then
		sys_factory_log_size=`du -s $sys_factory_dir | awk '{print $1}'`
		echo "bb_monitor : sys factory log size=$sys_factory_log_size"
	fi

	if [ -d $nav_dir ]; then
		nav_size=`du -s $nav_dir | awk '{print $1}'`
		echo "bb_monitor : navigation log size=$nav_size"
	fi

	if [ -d $perception_dir ]; then
		perception_size=`du -s $perception_dir | awk '{print $1}'`
		echo "bb_monitor : perception log size=$perception_size"
	fi

	#check size
	if [ $sys_factory_log_size -gt 0 ]; then
		echo 'bb_monitor : need delete sys factory log' > /dev/kmsg
		#rm -rf $sys_factory_dir
	fi

	if [ $flyctrl_size -gt $fc_threshold ]; then
		echo 'bb_monitor : fc log greater than threshold' > /dev/kmsg
		#parse dir and modify space with echo
		parseDir $fly_dir

		rm -rf $fly_dir/*
	fi

	if [ $sdrs_size -gt $sdrs_threshold ]; then
		echo 'bb_monitor : sdrs log greater than threshold' > /dev/kmsg
		#parse dir and modify space with echo
		parseDir $sdrs_dir

		rm -rf $sdrs_dir/*
	fi

	if [ $nav_size -gt $nav_threshold ]; then
		echo 'bb_monitor : navigation log greater than threshold' > /dev/kmsg
		#echo dji > /tmp/service_control
		#kill -9 `pidof dji_navigation`

		#rm -rf $nav_dir/*
		#rm /tmp/service_control

		#parse dir and modify space with echo
		parseDir $nav_dir

		rm -rf $nav_dir/*
	fi

	if [ $perception_size -gt $perception_threshold ]; then
		echo 'bb_monitor : perception log greater than threshold' > /dev/kmsg
		#parse dir and modify space with echo
		parseDir $perception_dir

		rm -rf $perception_dir/*
	fi

	#delete coredump files
	if [ $coredump_files -gt 0 ]; then
		echo 'bb_monitor : need delete coredump files' > /dev/kmsg
		#rm $sys_dir/core*
	fi

	#==============================================================================
	# blackbox partion check
	#==============================================================================
	blackbox_used_percent=`df -h | grep "/tmp/blackbox" | awk '{print $5}' | cut -d "%" -f1`
	echo "bb_monitor : partion used percent = $blackbox_used_percent" > /dev/kmsg
	#echo "bb_monitor : partion used percent = $blackbox_used_percent"

	sleep 30
done
