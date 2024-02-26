#!/bin/sh

V2SDK_SERVICE=dji_v2_sdk
AUTOTEST_SERVICE=autotest
V2SDK_ENABLE_FLAG_FILE=/tmp/EMMC/factory_test/V2SDK_ENABLE
V2SDK_DISABLE_FLAG_FILE=/tmp/EMMC/factory_test/V2SDK_DISABLE
AUTOTEST_ENABLE_FLAG_FILE=/tmp/SD0/factory_test/AUTOTEST_ENABLE

ctrl_flag_file()
{
    flag_file=$1
    ctrl=$2
    case $ctrl in
        0)
            if [ -e $flag_file ]; then
                echo "clear the existed file: $flag_file"
                rm -f $flag_file
            fi
            ;;
        1)
            if [[ ! -e $flag_file ]]; then
                echo "create the file: $flag_file"
                dir=${flag_file%/*}
                if [[ ! -d $dir ]]; then
                    mkdir -p $dir
                fi
                echo '' >  $flag_file
            fi
            ;;
        *)
            echo "error params"
            ;;
    esac
}

enable_service()
{
    service_name=$1
    echo $service_name
    ps | grep -v 'grep' | grep "$service_name"
    if [ $? -ne 0 ]; then
        if [ -x /usr/bin/$service_name ]; then
            echo "enable the service: $service_name"
            $service_name &
        else
            echo "there is no $service_name file"
        fi
    else
        echo "$service_name has already enabled"
    fi
}

disable_service()
{
    service_name=$1
    echo $service_name
    ps | grep -v 'grep' | grep "$service_name"
    if [ $? -eq 0 ]; then
        kill `ps | grep -v 'grep' | grep "$service_name" | awk -F ' ' '{print $1}'`
    else
        echo "$service_name doesn't running"
    fi
}

############################################################
#help_info
#
# v2sdk/autotest service ctrl script
#
# params:
#   1 - create a enable flag file, and v2sdk service will be
#       launched with system boots up next time.
#   2 - enable v2sdk service only onetime.
#   3 - equivalent to the combination of params 1 and 2.
#   4 - delete the enable flag file.
#   5 - create a enable flag file, and autotest service will be
#       launched with system boots up next time.
#   6 - enable autotest service only onetime.
#   7 - equivalent to the combination of params 5 and 6.
#   8 - delete the enable flag file.
#   9 - create a disable flag file, and v2sdk service will not
#       be launched with system boots up next time.
#   10- delete the v2sdk disable flag file.
#
############################################################

case $1 in
    1)
        echo "create a v2sdk enable flag file"
        ctrl_flag_file $V2SDK_ENABLE_FLAG_FILE 1
        ;;
    2)
        echo "enable v2sdk service oneshot"
        enable_service $V2SDK_SERVICE
        ;;
    3)
        echo "enable the automatic start of v2sdk service and running service"
        ctrl_flag_file $V2SDK_ENABLE_FLAG_FILE 1
        enable_service $V2SDK_SERVICE
        ;;
    4)
        echo "disable the automatic start of v2sdk service"
        ctrl_flag_file $V2SDK_ENABLE_FLAG_FILE 0
        ;;
    5)
        echo "create a autotest enable flag file"
        ctrl_flag_file $AUTOTEST_ENABLE_FLAG_FILE 1
        ;;
    6)
        echo "enable autotest service oneshot"
        enable_service $AUTOTEST_SERVICE
        ;;
    7)
        echo "enable the automatic start of autotest service and kill runnning service"
        ctrl_flag_file $AUTOTEST_ENABLE_FLAG_FILE 1
        enable_service $AUTOTEST_SERVICE
        ;;
    8)
        echo "disable the automatic start of autotest service"
        ctrl_flag_file $AUTOTEST_ENABLE_FLAG_FILE 0
        ;;
    9)
        echo "create a v2sdk disable flag file"
        ctrl_flag_file $V2SDK_DISABLE_FLAG_FILE 1
        ;;
    10)
        echo "enable the automatic start of v2sdk service"
        ctrl_flag_file $V2SDK_DISABLE_FLAG_FILE 0
        ;;
    *)  echo "error params!"
        ;;
esac

exit 0
