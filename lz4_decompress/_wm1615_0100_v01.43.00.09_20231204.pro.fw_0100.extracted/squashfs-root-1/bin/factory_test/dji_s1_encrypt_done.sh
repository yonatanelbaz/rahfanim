ENCRYPT_DONE_DIR=/tmp/EMMC/encrypt_info
S1_ENCRYPT_DONE_FILE=$ENCRYPT_DONE_DIR/npi_s1_encrypt_done

if [ ! -d  /tmp/EMMC/encrypt_info ]; then
	echo "S1_ENCRYPT_DONE : create encrypt info dir"
	mkdir -p /tmp/EMMC/encrypt_info
fi

if [ ! -e /tmp/EMMC/encrypt_info/npi_s1_encrypt_done ]; then
	echo "S1_ENCRYPT_DONE : create s1 encrypt done file"
	touch /tmp/EMMC/encrypt_info/npi_s1_encrypt_done
fi

exit 0
