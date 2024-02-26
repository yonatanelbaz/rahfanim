#!/bin/sh

##############################################################################
# parse cmdline
#
# USAGE:
#   - parse_cmdline.sh [keyword] [value]
#
# DESCRIPTION
#   The script will parse cmdline and according to the input parameter, decide
#   whether to output the keyword value or the results of output keyword
#   value which parsed from cmdline and input value comparisons.
#
# POTIONS:
#   [keyword]: - The keyword of cmdline you want to check.
#              - If there is no parameter [value] input, it will output the
#                keyword value by echo.
#
#   [value]:   - Will compare whether the value and the keyword value which
#                parsed from cmdline are equal, and return the result of the
#                comparison.
# EXIT STATUS
#   0:         - Exec successfully.
#   1:         - Didn't find the keyword from cmdline.
#   2:         - Compare failures.
#   3:         - Illegal params.
#
# NOTES
#   Must check the exit code first and decide whether to read string from echo
#   output buffer or not, because some message may output via echo.
##############################################################################

FIND_KEYWORD=1
FIND_AND_COMPARE=2

behavior=$FIND_KEYWORD
keyword=''
value=''
keyword_value=''

case $# in
    1)
        #find keyword and return value
        behavior=$FIND_KEYWORD
        keyword=$1
        ;;
    2)
        #return the result of $1) and $2 comparisons
        behavior=$FIND_AND_COMPARE
        keyword=$1
        value=$2
        ;;
    *)
        echo "Illegal params"
        exit 3
        ;;
esac

cmdline_msg=`cat /proc/cmdline | grep $keyword`
if [ $? -eq 0 ]; then
    str=${cmdline_msg##*$keyword=}
    keyword_value=${str%% *}
else
    exit 1
fi

case $behavior in
    $FIND_KEYWORD)
        echo $keyword_value
        ;;
    $FIND_AND_COMPARE)
        if [ "$keyword_value" != "$value" ]; then
            exit 2
        else
            exit 0
        fi
        ;;
    *)
        exit 3
        ;;
esac

exit 0
