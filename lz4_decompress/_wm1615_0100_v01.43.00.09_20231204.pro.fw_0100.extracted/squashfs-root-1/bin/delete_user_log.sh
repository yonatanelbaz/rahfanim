#########################################################################
# File Name: delete_user_log.sh
# Author:
# Email:
# Created Time: Wed 05 Aug 2020 10:57:52 AM CST
#########################################################################
#!/bin/sh

whitelist="log_delete_record clean_blackbox_log_flag lost+found  clear_log.json clear_log.txt"

do_clear_file()
{
    local temp=$1
    local file=`echo `${temp%*/}``

    if [ -d $file  ]; then
        delete_file=$file/*
    else
        delete_file=$file
    fi

    echo "do_clear_file $delete_file"
    rm -rf $delete_file
    return 0
}

check_whitelist()
{
    local file
    local name=$1
    for file in $whitelist
    do
        if [ x"$file" == x"$name" ]; then
            return 0
        fi
    done

    return 1
}

do_clear_content()
{
    local file
    local name=$1
    echo "start clear content=$name"

    for file in `ls $name`
    do
        check_whitelist $file
        if [ $? -ne 0 ]; then
            do_clear_file $name/$file
        fi
    done

    sync
}

params_number=$#
if [ $params_number -lt 1 ]; then
    echo "blackbox should be the fisrt parameter"
    exit 1
fi

params=$1
if [ x$params == xblackbox ]; then
    echo "clean log in blackbox..."
    do_clear_content /tmp/blackbox
else
    echo "blackbox should be the first parameter"
    exit 1
fi

exit 0
