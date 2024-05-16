#! /bin/sh

cmd=$1
cmd_opt=$2
param_0=$3
param_1=$4

FACTORY_DIR=/tmp/EMMC/wifi_factory
COUNTRY_CODE_FILE=$FACTORY_DIR/country.txt
AP_INFO_CFG_FILE=$FACTORY_DIR/wifi.config
MAC_CFG_FILE=$FACTORY_DIR/softmac.bin
SSID_PRE="WM161"
AP_PSK=""
AP_SSID=""
mac_array0="00"
mac_array1="00"
mac_array2="00"
mac_array3="00"
mac_array4="00"
mac_array5="00"

if [ is$cmd = is"-h" -o -z $cmd ]; then
    echo "Usage: wifi_info.sh set power value(dbm)"
    echo "       wifi_info.sh set chn value (no effect after reboot)"
    echo "       wifi_info.sh set cc value(alpha2) "
    echo "       wifi_info.sh set mac xx:xx:xx:xx:xx:xx (must lower case)"
    echo "       wifi_info.sh get power"
    echo "       wifi_info.sh get chn"
    echo "       wifi_info.sh get cc"
    echo "       wifi_info.sh get mac"
    echo "       wifi_info.sh get ap"
    exit 1
fi

#update mac to global array
function check_mac_file()
{
    if [ ! -f $MAC_CFG_FILE ]; then
        echo "no mac file:$MAC_CFG_FILE"
        return 1
    fi
    echo "check_mac_file"
    i=0
    tmp0=`busybox hexdump -C $MAC_CFG_FILE | busybox grep 00000000 |busybox awk '{print $2}'`
    tmp1=`busybox hexdump -C $MAC_CFG_FILE | busybox grep 00000000 |busybox awk '{print $3}'`
    tmp2=`busybox hexdump -C $MAC_CFG_FILE | busybox grep 00000000 |busybox awk '{print $4}'`
    tmp3=`busybox hexdump -C $MAC_CFG_FILE | busybox grep 00000000 |busybox awk '{print $5}'`
    tmp4=`busybox hexdump -C $MAC_CFG_FILE | busybox grep 00000000 |busybox awk '{print $6}'`
    tmp5=`busybox hexdump -C $MAC_CFG_FILE | busybox grep 00000000 |busybox awk '{print $7}'`
    while [ $i -lt 6 ]; do
        eval tmp_val="\$tmp$i"
        STRING_LEN=`echo $tmp_val | busybox wc -L`
        if [ $STRING_LEN -ne 2 ]; then
            echo "mac read failed $tmp_val"
            return 1
        fi
	JUDGE=`echo "$tmp$i" | busybox awk -F '' '{for(i=1; i<=NF; i++) {if(!match($i, /[0-9a-fA-F]/)) {print "INFALID_VALUE"; break;}}}'`
        if [ -n "$JUDGE" ]; then
            echo "mac read invalid value $tmp$i"
            return 1
        fi
        if [ "$tmp1" = "00" -a "$tmp2" = "00" -a "$tmp3" = "00" -a "$tmp4" = "00" -a "$tmp5" = "00" ]; then
            echo "mac read invalid zero}"
            return 1
        fi
	eval mac_array$i="\$tmp$i"
        i=`busybox expr $i + 1`
    done
    return 0
}

#update ssid and psk to global variable
#must run check_mac_file firstly
function parser_ssid_psk()
{
    #get ssid
    echo "ssid-MAC_ADDR=${mac_array0}:${mac_array1}:${mac_array2}:${mac_array3}:${mac_array4}:${mac_array5}"
    AP_SSID="${SSID_PRE}-${mac_array3}${mac_array4}${mac_array5}"
    #get psk
    #KEY_STRING=`cat /proc/cmdline | busybox awk -F ' ' '{for(i=1; i<=NF; i++) {if(match($i, "wifi_key")) {print $i}}}'`
    #AP_PSK=`echo "$KEY_STRING" | busybox awk -F "=" '{print $2}'`
    AP_PSK="12341234"
    echo "get ap psk:$AP_PSK"
    STRING_LEN=`echo "$AP_PSK" | busybox wc -L`
    if [ $STRING_LEN -ne 8 ]; then
        echo "KEY STRING $KEY_STRING invalid len $STRING_LEN"
        return 1
    fi
    JUDGE=`echo "$AP_PSK" | busybox awk -F '' '{for(i=1; i<=NF; i++) {if(!match($i, /[0-9a-fA-F]/)) {print "INFALID_VALUE"; break;}}}'`
    if [ -n "$JUDGE" ]; then
        echo "KEY STRING $KEY_STRING invalid value $AP_PSK"
        return 1
    fi
    echo "parser: ssid is $AP_SSID, psk is $AP_PSK"
    return 0
}

function check_wifi_config_file()
{
    #check AP CFG file
    if [ -f $AP_INFO_CFG_FILE ]; then
        NEW_PSK=`cat $AP_INFO_CFG_FILE | busybox grep psk | busybox awk -F '=' '{print $2}'`
        if [ "$NEW_PSK" != "$AP_PSK" ]; then
            echo "save invalid psk"
            return 1
        fi
        NEW_SSID=`cat $AP_INFO_CFG_FILE | busybox grep ssid| busybox awk -F '=' '{print $2}'`
        if [ "$NEW_SSID" != "$AP_SSID" ]; then
            echo "save ssid failed"
            return 1
        fi
    else
        echo "create $AP_INFO_CFG_FILE failed"
        return 1
    fi
    return 0
}

if [ is$cmd = is"set" ]; then
    if [ is$cmd_opt = is"power" ]; then
        echo "will run cmd: iw dev wlan0 set tx power limit ${param_0}00"
        iw dev wlan0 set tx power limit ${param_0}00
        if [ $? == 0 ]; then
            echo "SUCCESS"
            exit 0
        else
            echo "FAILURE"
            exit 1
        fi
    elif [ is$cmd_opt = is"chn" ]; then
        target_chn=`busybox printf '%02x' ${param_0}`
        echo "will change to channel $target_chn"
        dji_mb_ctrl -s test -R diag -g 7 -t 0 -s 7 -c 0x2b -a 0x40 -q 142 00${target_chn}00
        echo "wait 5 seconds for reconfig"
        sleep 3
        channel=`cat /tmp/EMMC/wifi/hostapd.conf | busybox grep channel | busybox awk -F '=' '{print $2}'`
        echo "current channel is $channel"
        if [ "$target_chn" = "$channel" ]; then
            echo "SUCCESS"
            exit 0
        else
           echo "FAILURE"
           exit 1
        fi
    elif [ is$cmd_opt = is"mac" ]; then
        tmp0=`echo $param_0 | busybox awk -F ':' '{print $1}'`
        tmp1=`echo $param_0 | busybox awk -F ':' '{print $2}'`
        tmp2=`echo $param_0 | busybox awk -F ':' '{print $3}'`
        tmp3=`echo $param_0 | busybox awk -F ':' '{print $4}'`
        tmp4=`echo $param_0 | busybox awk -F ':' '{print $5}'`
        tmp5=`echo $param_0 | busybox awk -F ':' '{print $6}'`
        i=0
        while [ $i -lt 6 ]; do
            eval tmp_val="\$tmp$i"
            if [ -z $tmp_val ]; then
                echo "mac $param_0: $i element invalid"
                exit 1
            fi
            if [ ${#tmp_val} -ne 2  ]; then
               echo "mac $param_0: $i invalid pattern xx:xx"
               exit 1
            fi
            busybox printf %x 0x${tmp_val} > /dev/null
            if [ $? -ne 0 ]; then
               echo "mac $param_0: $i invalid digital pattern "
               exit 1
            fi
            eval mac_array$i="${tmp_val}"
            echo "parse $i: mac_val: ${tmp_val}"
            i=`busybox expr $i + 1`
        done
        #write mac to factory_data
        if [ ! -d $FACTORY_DIR ]; then
            mkdir -p $FACTORY_DIR
        else
            echo "mac right, MAC ADDR re-write"
        fi
        echo -e -n \\x${mac_array0} > $MAC_CFG_FILE
        i=1
        while [ $i -lt 6 ]; do
            eval temp_mac="\$mac_array$i"
            echo -e -n \\x${temp_mac} >> $MAC_CFG_FILE
            i=`busybox expr $i + 1`
        done
        sync
        #check mac file
        check_mac_file
        if [ $? -ne 0 ]; then
            echo "check_mac_file failed on set mac"
            echo "FAILURE"
            exit 1
        fi
        rm /tmp/EMMC/wifi/softmac.bin
        parser_ssid_psk
        if [ $? -ne 0 ]; then
            echo "parser_ssid_psk failed"
            echo "FAILURE"
            exit 1
        fi
        #write ssid to factory_data
        echo "ssid=${AP_SSID}"             >  $AP_INFO_CFG_FILE
        echo "psk=${AP_PSK}"               >> $AP_INFO_CFG_FILE
        #check AP CFG file
        check_wifi_config_file
        if [ $? -ne 0 ]; then
            echo "check_wifi_config_file failed"
            echo "FAILURE"
            exit 1
        fi
        #UPDATE RUN-TIME FILE for SSID
        if [ `ps | busybox grep -v grep | busybox grep -c dji_network` -gt 0 ]; then
            killall dji_network
        fi
        sync
        echo "SUCCESS"
        exit 0
     elif [ is$cmd_opt = is"cc" ]; then
        # Save country code
        echo "will save country code $param_0"
        echo country_code=$param_0 > $COUNTRY_CODE_FILE
        sync
        # Check country code
        COUNTRY_CODE=`cat $COUNTRY_CODE_FILE | busybox awk -F '=' '{print $2}'`
        if [ "$param_0" != "$COUNTRY_CODE" ]; then
            echo "save country coude failed"
            echo "FAILURE"
            exit 1
        else
            echo "SUCCESS"
            exit 0
        fi
    else
        echo "INVALID SET CMD:$cmd_opt"
        echo "FAILURE"
        exit 1
    fi
elif [ is$cmd = is"get" ]; then
    if [ is$cmd_opt = is"power" ]; then
        echo "currently unsupported"
        echo "FAILURE"
        exit 1
    elif [ is$cmd_opt = is"chn" ]; then
        channel=`cat /tmp/EMMC/wifi/hostapd.conf | busybox grep channel | busybox awk -F '=' '{print $2}'`
        if [ $? -ne 0 ]; then
            echo "no channel info from hostapd.conf"
            echo "FAILURE"
            exit 1
        fi
        echo "AP_MODE_CHANNEL=$channel"
        echo "SUCCESS"
        exit 0
    elif [ is$cmd_opt = is"mac" ]; then
        check_mac_file
        if [ $? -ne 0 ]; then
            echo "get mac failed"
            echo "FAILURE"
            exit 1
        fi
        echo "SUCCESS"
        echo "MAC_ADDR=${mac_array0}:${mac_array1}:${mac_array2}:${mac_array3}:${mac_array4}:${mac_array5}"
        exit 0
    elif [ is$cmd_opt = is"ap" ]; then
        check_mac_file
        if [ $? -ne 0 ]; then
            echo "NO MAC ADDR for AP SSID"
            echo "FAILURE"
            exit 1
        fi
        parser_ssid_psk
        if [ $? -ne 0 ]; then
            echo "NO VALID SSID or PSK"
            echo "FAILURE"
            exit 1
        fi
        check_wifi_config_file
        if [ $? -ne 0 ]; then
            echo "WIFI AP or SSID re-write failed"
            echo "FAILURE"
            exit 1
        fi
        echo "SUCCESS"
        echo "AP_SSID=$AP_SSID, AP_PSK=$AP_PSK"
        exit 0
    elif [ is$cmd_opt = is"cc" ]; then
        COUNTRY_CODE=`cat $COUNTRY_CODE_FILE | busybox awk -F '=' '{print $2}'`
        if [ -z $COUNTRY_CODE ]; then
            echo "FAILURE"
            exit 1
        else
            echo "COUNTRY_CODE=$COUNTRY_CODE"
            echo "SUCCESS"
            exit 0
        fi
    else
        echo "INVALID GET CMD"
        echo "FAILURE"
        exit 1
    fi
else
    echo "CMD INVALID"
    echo "FAILURE"
    exit 1
fi

