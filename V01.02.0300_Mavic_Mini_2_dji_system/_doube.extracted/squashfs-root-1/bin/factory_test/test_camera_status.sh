#!/bin/sh

#############################################################################
# Camera test script
#
# exit code:
#  0 - success
#  1 - mb_ctrl fail
#  2 - take_photos fail
#  3 - link test fail
# ###########################################################################

fail_msg="[ ${0##*/} _test_fail ]"

DCIM_ROOT_DIR=/tmp/SD0/DCIM/

get_version_test_flag=0
take_photos_test_flag=0

recheck_photo_file_flag=0

case $1 in
    "all")
        echo "check all of the items..."
        get_version_test_flag=1
        take_photos_test_flag=1
        case $2 in
            "recheck")
                echo "recheck photo file status"
                recheck_photo_file_flag=1
                ;;
            "norecheck")
                echo "not recheck photo file status"
                recheck_photo_file_flag=0
                ;;
            *)
                echo "not recheck photo file status default "
                ;;
        esac
        ;;
    "link")
        echo "get version test"
        get_version_test_flag=1
        ;;
    *)
        echo "not choice items, run all items default..."
        get_version_test_flag=1
        take_photos_test_flag=1
        ;;
esac

if [ $get_version_test_flag != 0 ]; then
    result=`dji_mb_ctrl -S test -R diag -g 1 -t 0 -s 0 -c 1`
    ret=$?

    if [ $ret != 0 ];then
        err_msg=${result##*error:}
        echo "error $ret, mb_ctrl camera $err_msg. $fail_msg"
        exit 1
    else
        raw_data=${result##*data:}
        ret_code=`echo $raw_data | busybox awk '{printf $1}'`

        if [ $ret_code == "00" ]; then
            echo "test camera link success"
        else
            echo "test camera link fail. $fail_msg"
            exit 3
        fi

    fi
fi

CUR_DCIM_DIR=`ls $DCIM_ROOT_DIR | grep MEDIA |sort -n -r | head -n 1`

if [ $? -ne 0 ]; then
    echo "find DCIM dir fail. $fail_msg"
    exit 2
else
    CUR_DCIM_DIR=$DCIM_ROOT_DIR$CUR_DCIM_DIR
    echo "latest DCIM dir is $CUR_DCIM_DIR"
fi

if [ $take_photos_test_flag != 0 ]; then
    if [ $recheck_photo_file_flag != 0 ]; then
        if [ -e $CUR_DCIM_DIR ]; then
            last_file_num=`ls -l $CUR_DCIM_DIR | grep "^-" | wc -l`
            if [ $last_file_num -eq 999 ]; then
                echo "update to new media dir"
                CUR_DCIM_DIR=${CUR_DCIM_DIR##*/}
                CUR_DCIM_DIR=$DCIM_ROOT_DIR$((${CUR_DCIM_DIR%%MEDIA}+1))MEDIA
                last_file_num=0
            fi
        else
            last_file_num=0
        fi
    fi

    # switch to capture mode
    echo "switch to capture mode..."
    result=`dji_mb_ctrl -S test -R diag -g 1 -t 0 -s 2 -c e1 -1 5`
    ret=$?

    if [ $ret != 0 ];then
        err_msg=${result##*error:}
        echo "error $ret, mb_ctrl camera $err_msg. $fail_msg"
        exit 1
    fi

    raw_data=${result##*data:}
    ret_code=`echo $raw_data | busybox awk '{printf $1}'`

    if [ $ret_code == "00" ]; then
       echo "switch to capture mode success"
    else
       echo "switch to capture mode error, skip testing, ret is  $ret ,resp is $result."
       exit 2
    fi

    echo "capture..."
    result=`dji_mb_ctrl -S test -R diag -g 1 -t 0 -s 2 -c 1 -1 1`
    ret=$?

    if [ $ret != 0 ];then
        err_msg=${result##*error:}
        echo "error $ret, mb_ctrl camera $err_msg. $fail_msg"
        exit 1
    fi

    raw_data=${result##*data:}
    ret_code=`echo $raw_data | busybox awk '{printf $1}'`

    if [ $ret_code == "00" ]; then
        if [ $recheck_photo_file_flag != 0 ]; then
            sleep 1
            if [ -e $CUR_DCIM_DIR ]; then
                count=5
                while true; do
                    sleep 1
                    echo "rechecking... $count times"
                    cur_file_num=`ls -l $CUR_DCIM_DIR | grep "^-" | wc -l`
                    echo "last_num=$last_file_num, cur_num=$cur_file_num"
                    diff=$(($cur_file_num - $last_file_num))
                    if [[ $diff -ge 1 || $count -eq 0 ]]; then
                        break;
                    fi
                    count=$(($count-1))
                done
                if [ $diff -lt 1 ]; then
                    echo "recheck fail, no photo file. $fail_msg"
                    exit 2
                fi
            else
                echo "no $CUR_DCIM_DIR directory"
            fi
        fi
        echo "take photo test success"
    else
       echo "take photo cmd send error, ret is  $ret resp is $result. $fail_msg"
       exit 2
    fi
fi

exit 0
