#!/usr/bin/env bash

sudo systemctl stop user_monitor.service

sleep 1
sync

echo "clean dir /home/sys_run-log_monitor generated data..."
rm /home/sys_run-log_monitor/sys_run-log_monitor.txt
rm /home/sys_run-log_monitor/REBOOT_TIMES
rm /home/sys_run-log_monitor/reboot_log.txt
echo "ls after clean:"
ls /home/sys_run-log_monitor
echo "------------------------------------------------------"
echo "clean current dir generated data..."
rm ./sys_run-log_monitor.txt
rm ./REBOOT_TIMES
rm ./reboot_log.txt
echo "ls after clean:"
ls ./

sync
sleep 1

sudo systemctl start user_monitor.service
