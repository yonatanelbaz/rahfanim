#!/bin/sh

echo "rm all factory files"

echo "stop blackbox service"
echo 'dji_blackbox' >> /tmp/service_control
ps | grep 'dji_blackbox' | grep -v grep | awk '{print $1}' | xargs kill -9

echo "rm /tmp/EMMC/factory_test/*"
rm -rf /tmp/EMMC/factory_test/*

echo "rm /tmp/blackbox/*"
rm -rf /tmp/blackbox/*

echo "rm done"

exit 0
