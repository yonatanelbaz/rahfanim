#! /bin/sh

# control socket directory
CONTROL_DIR=/tmp/EMMC/wireless/wifi
BLUETOOTH_DIR=/tmp/EMMC/wireless/bluetooth
FACTORY_DIR=/tmp/EMMC/wifi_factory

SOCKET_PATH=$CONTROL_DIR/sockets

#configuration files
AP_PSK_CONF=$CONTROL_DIR/hostapd.psk
MAC_CFG_FILE=$CONTROL_DIR/softmac.bin

#factory file
FACTORY_MAC_ADDR=$FACTORY_DIR/softmac.bin

if [ ! -d $CONTROL_DIR ]; then
    echo "directory $CONTROL_DIR do not exist, create it"
    mkdir -p $CONTROL_DIR
fi

if [ ! -d $BLUETOOTH_DIR ]; then
    echo "directory $BLUETOOTH_DIR do not exist, create it"
    mkdir -p $BLUETOOTH_DIR
fi

if [ ! -d $SOCKET_PATH ]; then
    echo "directory $SOCKET_PATH do not exist, create it"
    mkdir -p $SOCKET_PATH
fi

if [ ! -d $FACTORY_DIR ]; then
    echo "directory $FACTORY_DIR do not exist, create it"
    mkdir -p $FACTORY_DIR
fi

if [ `ps | busybox grep -v grep | busybox grep -c wpa_supplicant` -gt 0 ]; then
    echo "kill process wpa_supplicant"
    killall -KILL wpa_supplicant
fi

if [ `ps | busybox grep -v grep | busybox grep -c hostapd` -gt 0 ]; then
    echo "kill process hostapd"
    killall -KILL hostapd
fi

udhcpd_pid=`ps | grep -v grep | grep udhcpd_wifi | busybox awk -F ' ' '{print $1}'`
if [ $? == 0  ]; then
    if [ $udhcpd_pid -gt 0 ]; then
        echo "kill process udhcpd_wifi $udhcpd_pid"
        kill -9 $udhcpd_pid
    fi
fi

if [ `lsmod | busybox grep -v grep | busybox grep -c bcmdhd` -gt 0 ]; then
    rmmod bcmdhd
fi

# Check softmac set in factory
if [ -f $FACTORY_MAC_ADDR ]; then
    cp $FACTORY_MAC_ADDR $MAC_CFG_FILE
    echo "factory mac addr exist, use it"
fi

FACTORY_WIFI_CONF=$FACTORY_DIR/wifi.config
# Check ssid/psk set in factory
if [ -f "$FACTORY_WIFI_CONF" ]; then
    cat $FACTORY_WIFI_CONF | busybox grep psk
    if [ $? == 0 ]
    then
        AP_PSK=`cat $FACTORY_WIFI_CONF | busybox grep psk | busybox awk -F '=' '{print $2}'`
    fi
    cat $FACTORY_WIFI_CONF | busybox grep ssid
    if [ $? == 0 ]
    then
        AP_SSID=`cat $FACTORY_WIFI_CONF | busybox grep ssid | busybox awk -F '=' '{print $2}'`
    fi
    echo "NEW_PSK $AP_PSK, NEW_SSID $AP_SSID"
fi

if [ ! -f "$AP_PSK_CONF" ]; then
    touch $AP_PSK_CONF
fi

## cfg dhcp server
echo > /tmp/udhcpd.leases

# Unlink the unused PF_UNIX socket
rm $SOCKET_PATH/*

exit 0
