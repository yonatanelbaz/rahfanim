FACTORY_DIR=/tmp/EMMC/factory_test
BOARD_ID_FILE=$FACTORY_DIR/board_id.txt
DEIVCE_ID_FILE=$FACTORY_DIR/device_id.txt

board_id()
{

if [ $1 == "WR" ];then
    echo $2 > $BOARD_ID_FILE
    sync
fi

if [ $1 == "RD" ];then
    local ret=`cat $BOARD_ID_FILE`
    echo "BoardID:$ret"
fi

}

device_id()
{
if [ $1 == "WR" ];then
    echo $2 > $DEIVCE_ID_FILE
    sync
fi

if [ $1 == "RD" ];then
    local ret=`cat $DEIVCE_ID_FILE`
    echo "DeviceID:$ret"
fi

}

delete_sn()
{
if [ $1 == "RM" ];then
    if [ -f $BOARD_ID_FILE ]; then
	rm -f $BOARD_ID_FILE
        echo "delete $BOARD_ID_FILE successfully."
    fi

    if [ -f $DEIVCE_ID_FILE ]; then
	rm -f $DEIVCE_ID_FILE
        echo "delete $DEIVCE_ID_FILE successfully."
    fi
    
    sync
fi

}

if [ $1 == "board" ];then
    board_id  $2 $3
fi

if [ $1 == "device" ];then
    device_id  $2 $3
fi

if [ $1 == "all" ];then
    delete_sn  $2
fi

exit 0
