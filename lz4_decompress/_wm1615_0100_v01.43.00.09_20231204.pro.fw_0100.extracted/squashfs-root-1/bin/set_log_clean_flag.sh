#########################################################################
# File Name: set_log_clean_flag.sh
# Author:
# Email:
# Created Time: Fri 07 Aug 2020 09:37:41 PM CST
#########################################################################
#!/bin/sh

touch /tmp/blackbox/clean_blackbox_log_flag
if [ $? -ne 0 ]; then
    exit 1
fi

exit 0
