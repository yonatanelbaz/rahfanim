#!/bin/sh

fail_msg="[ ${0##*/} _test_fail ]"

check_sdcard()
{
    local std_md5=5cb71fa08ed8fa84ecd2bd00a30a7edc
    SDCARD=`df | grep "/tmp/SD0" | awk '{print $6}'`
    echo $SDCARD
    if [ "$SDCARD" == "/tmp/SD0" ]; then
        if [ ! -f /usr/bin/factory_test/test_data/sample.data ];then
            echo "no sample.data, please check data partition! $fail_msg"
            return 1
        fi
        #SD

        if [ -e /tmp/SD0/sd.data ]; then
            echo "sd.data already exist, remove it"
            rm /tmp/SD0/sd.data
        fi

        dd if=/usr/bin/factory_test/test_data/sample.data of=/tmp/SD0/sd.data bs=1024 count=1024
        result=$?
        if [ $result != 0 ]; then
            echo "dd fail, fail to write SD."
            return 1
        fi
        SD_MD5=`md5sum /tmp/SD0/sd.data | awk '{print $1}'`
        if [ $SD_MD5 != $std_md5 ]; then
            echo "SD dd fail, MD5 is $SD_MD5. $fail_msg"
            return 1
        fi
        return 0
    fi
    echo "no sdcard directory!. $fail_msg"
    return 1

}

check_sdcard

exit $?
