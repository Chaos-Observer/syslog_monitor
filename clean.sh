#!/usr/bin/env bash

sudo systemctl stop user_monitor.service

sleep 1
sync

echo "clean dir /home/syslog_monitor/record generated data..."
rm -r /home/syslog_monitor/record
echo "------------------------------------------------------"
echo "ls after clean:"
ls /home/syslog_monitor

sync
sleep 1

sudo systemctl start user_monitor.service
