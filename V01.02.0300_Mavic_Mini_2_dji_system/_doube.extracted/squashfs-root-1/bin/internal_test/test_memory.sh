path=/tmp/NFZ/log/system/test_memory.data

function rand(){
	min=$1
	max=$(($2-$min+1))
	num=$(cat /proc/sys/kernel/random/uuid | cksum | awk -F ' ' '{print $1}')
	echo $(($num%$max+$min))
}

while true; do
	date >> $path
	procrank | tee >> $path
	free | tee >> $path
	rnd=$(rand 10 500)
	echo "++++++++++++++++++++++" >> $path
	sleep $rnd
	echo $rnd
	if [ $rnd -le 100 ]; then
		continue
	fi
	if [ $rnd -le 200 ]; then
		echo "kill dji_sw_uav"
		kill -9 `pidof dji_sw_uav`
		continue
	fi
	if [ $rnd -le 300 ]; then
		echo "kill dji_network"
		kill -9 `pidof dji_network`
		continue
	fi
	if [ $rnd -le 400 ]; then
		echo "kill dji_hdvt_uav"
		kill -9 `pidof dji_hdvt_uav`
		continue
	fi
	if [ $rnd -le 500 ]; then
		echo "kill dji_flight"
		kill -9 `pidof dji_flight`
	fi
done
