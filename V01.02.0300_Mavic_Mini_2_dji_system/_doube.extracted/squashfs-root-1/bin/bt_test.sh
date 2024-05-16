#! /bin/sh

param=$1

APP_UIPC_BT_PATH=/tmp/EMMC/wireless/bluetooth/
APP_UIPC_SIMPLE_APP=$APP_UIPC_BT_PATH/simple_app

if [ ! -f $APP_UIPC_SIMPLE_APP ]; then
    cp /usr/bin/simple_app $APP_UIPC_BT_PATH
    chmod +x $APP_UIPC_SIMPLE_APP
fi

# hci reset
cd $APP_UIPC_BT_PATH && ./simple_app --hci 030C00
# bt signal tone tx cfg
cd $APP_UIPC_BT_PATH && ./simple_app --vsc $param

if [ $? == 0  ]; then
    echo "simple_app run success."
    exit 0
else
    echo "simple_app run failed."
    exit 1
fi
