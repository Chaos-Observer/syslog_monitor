#!/usr/bin/env bash

#before use,exec 'sudo chown -R ${USER} /home/sys_run-log_monitor'in unprivileged user
SLEEP_TIME="60" # unit is second


RB_TIMES="/home/sys_run-log_monitor/REBOOT_TIMES"
monitor_doc="/home/sys_run-log_monitor/sys_run-log_monitor.txt"
reboot_log="/home/sys_run-log_monitor/reboot_log.txt"

EXEC_DATE=$(date "+%Y-%m-%d %H:%M:%S")
OS_TYPE=$(uname -o)
OS_VER=$(cat /etc/issue | grep "Ubuntu")
ARCH=$(uname -m)
HOSTNAME=$(uname -n)
internal_ip=$(hostname -I)
sys_mem_free=$(awk '/MemFree/{free1=$2}/^Cached/{cache1=$2}/Buffers/{buffers1=$2}END{print(free1+cache1+buffers1)/1024}' /proc/meminfo)
loadaverge=$(top -n 1 -b | grep "load average" | awk '{print $12 $13 $14}')
disk_used=$(df -h | grep -v "Filesystem" | awk '{print $1 " " $5}')

if [ -f "$monitor_doc" ]
then
	echo "--------------------restart---------------------" >> $monitor_doc
	echo "re-exec time $EXEC_DATE ::Record!" >> $monitor_doc
	echo -e  "OS type:"  $OS_TYPE >> $monitor_doc
	echo -e  "OS release version:"  $OS_VER >> $monitor_doc
	echo -e  "architecture:"  $ARCH >> $monitor_doc
	echo -e  "hostname:"  $HOSTNAME >> $monitor_doc
	echo -e  "internal_ip:"  $internal_ip >> $monitor_doc
	echo -e  "sys_mem_free:"   $sys_mem_free >> $monitor_doc
	echo -e  "CPU loadaverge:"  $loadaverge >> $monitor_doc
	echo -e  "Disk used:"  $disk_used >> $monitor_doc
else
	touch $monitor_doc
        echo "--------------------start---------------------" >> $monitor_doc
	echo "$EXEC_DATE ::fisrt touch file!" >> $monitor_doc
	echo -e  "OS type:"  $OS_TYPE >> $monitor_doc
        echo -e  "OS release version:"  $OS_VER >> $monitor_doc
        echo -e  "architecture:"  $ARCH >> $monitor_doc
        echo -e  "hostname:"  $HOSTNAME >> $monitor_doc
        echo -e  "internal_ip:"  $internal_ip >> $monitor_doc
        echo -e  "sys_mem_free:"   $sys_mem_free >> $monitor_doc
        echo -e  "CPU loadaverge:"  $loadaverge >> $monitor_doc
        echo -e  "Disk used:"  $disk_used >> $monitor_doc
fi


if [ -f "$RB_TIMES" ]
then
	declare -i x
	x=$(cat $RB_TIMES)
	x=$(($x+1))
	echo "$x" > $RB_TIMES
else
	touch $RB_TIMES
	declare -i x=0
	echo "$x" > $RB_TIMES
fi

if [ -f "$reboot_log" ]
then
        echo "--------------------restart---------------------" >> $reboot_log
        echo "re-exec time $EXEC_DATE ::Record!" >> $reboot_log
	echo -e "reboot times:" $x >> $reboot_log
else
	touch $reboot_log
        echo "--------------------start---------------------" >> $reboot_log
        echo "$EXEC_DATE ::fisrt touch file!" >> $reboot_log
        echo -e "reboot times:" $x >> $reboot_log
fi


while [ "1" = "1" ]
do
	echo "--------monitor--------" >> $monitor_doc
	CURRENT_DATE=$(date "+%Y-%m-%d %H:%M:%S")
	echo "$CURRENT_DATE :: exec monitor" >> $monitor_doc
	systemctl status iotmanager.service | grep -E "Loaded|Active|PID|Tasks|CGroup" | tee -a $monitor_doc
#	echo "----div----" >> $monitor_doc
#	systemctl status perception.service | grep -E "Loaded|Active|PID|Tasks|CGroup" | tee -a $monitor_doc
	sync  #sync write data
	sleep $SLEEP_TIME
done
