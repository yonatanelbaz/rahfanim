#!/bin/sh

fail_msg="[ ${0##*/} _test_fail ]"

set -x
test_mem -s 0x80000 -l 2

if [[ $? != 0 ]]; then
        echo "DDR fail. $fail_msg"
        exit 1
fi
echo "DDR test success"
exit 0
