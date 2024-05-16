#!/bin/sh

AGING_TEST_FLAG_FILE=/tmp/EMMC/factory_test/AGING_TEST

create_aging_test_flag_file()
{
    echo $1 > $AGING_TEST_FLAG_FILE
}

remove_aging_test_flag_file()
{
    if [ -e AGING_TEST_FLAG_FILE ]; then
        rm -f $AGING_TEST_FLAG_FILE
    fi
}

case $1 in
    "enable")
        timeout=`echo $2 | awk '/^[0-9]+$/'`
        if [ -z "$timeout" ]; then
            timeout=7200
        fi
        echo "enable aging test, set timeout to $timeout"
        create_aging_test_flag_file $timeout
        ;;
    "disable")
        echo "disable aging test"
        remove_aging_test_flag_file
        ;;
    *)
        echo "error pramas"
        ;;
esac

exit 0
