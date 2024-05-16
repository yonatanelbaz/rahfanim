#! /bin/sh
PARAM=$1

if [ is$PARAM = is"-h" -o -z $PARAM ]; then
    echo "Usage:"
    echo "     wifi_sdr_switch.sh wifi/sdr"
    exit 0
fi

if [ "$PARAM" = "wifi" ]; then
    echo "Start to switch to wifi."
    dji_mb_ctrl -S test -R diag -g 9 -t 4 -s 7 -c 41 00
elif [ "$PARAM" = "sdr" ]; then
    echo "Start to switch to sdr."
    dji_mb_ctrl -S test -R diag -g 9 -t 4 -s 7 -c 42 00
else
    echo "Invalid param!"
    echo "Usage:"
    echo "     wifi_sdr_switch.sh wifi/sdr"
    exit 1
fi

exit 0
