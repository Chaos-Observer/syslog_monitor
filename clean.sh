#!/usr/bin/env bash

sudo systemctl stop user_monitor.service

sleep 1
sync

echo "clean dir /home/syslog_monitor generated data..."
rm -r /home/syslog_monitor/record
echo "ls after clean:"
ls /home/sys_run-log_monitor
echo "------------------------------------------------------"
echo "clean current dir generated data..."
rm -r ./record
echo "ls after clean:"
ls ./

sync
sleep 1

sudo systemctl start user_monitor.service
