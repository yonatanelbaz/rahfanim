#!/bin/sh

opcontrol --dump
date >> /tmp/blackbox/log/system/oprofile.log
opreport -l -d -g >> /tmp/blackbox/log/system/oprofile.log
opcontrol --reset