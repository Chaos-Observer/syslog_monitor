#!/usr/bin/env bash

#before use,exec 'sudo chown -R ${USER} /home/syslog_monitor'in unprivileged user
SLEEP_TIME="10" # unit is second

service_1="iotmanager"
service_2="mediastreaming"
service_3="rtspserverrgb"
service_4="perception"
service_n="4"

record_dir="/home/syslog_monitor/record"
RB_TIMES="${record_dir}/REBOOT_TIMES"
monitor_doc="${record_dir}/syslog_monitor.txt"
reboot_log="${record_dir}/reboot_log.txt"


EXEC_DATE=$(date "+%Y-%m-%d %H:%M:%S")
OS_TYPE=$(uname -o)
OS_VER=$(cat /etc/issue | grep "Ubuntu")
ARCH=$(uname -m)
HOSTNAME=$(uname -n)
internal_ip=$(hostname -I)
sys_mem_free=$(awk '/MemFree/{free1=$2}/^Cached/{cache1=$2}/Buffers/{buffers1=$2}END{print(free1+cache1+buffers1)/1024}' /proc/meminfo)
loadaverge=$(top -n 1 -b | grep "load average" | awk '{print $12 $13 $14}')
disk_used=$(df -h | grep -v "Filesystem" | awk '{print $1 " " $5}')
SERVER_NAME="iot.wenjingtech.com"

if [ ! -d "${record_dir}" ]; then
	mkdir ${record_dir}
fi

if [ -f "$monitor_doc" ]
then
	echo "------------------------restart-------------------------" >> $monitor_doc
	echo "re-exec time $EXEC_DATE ::Record!" >> $monitor_doc
else
	touch $monitor_doc
    echo "-------------------------start--------------------------" >> $monitor_doc
	echo "$EXEC_DATE ::fisrt touch file!" >> $monitor_doc
fi
	echo -e  "OS type:"  $OS_TYPE >> $monitor_doc
	echo -e  "OS release version:"  $OS_VER >> $monitor_doc
	echo -e  "architecture:"  $ARCH >> $monitor_doc
	echo -e  "hostname:"  $HOSTNAME >> $monitor_doc
	echo -e  "internal_ip:"  $internal_ip >> $monitor_doc
	echo -e  "sys_mem_free:"   $sys_mem_free >> $monitor_doc
	echo -e  "CPU loadaverge:"  $loadaverge >> $monitor_doc
	echo -e  "Disk used:"  $disk_used >> $monitor_doc



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
        echo "------------------------restart-------------------------" >> $reboot_log
        echo "re-exec time $EXEC_DATE ::Record!" >> $reboot_log
		echo -e "reboot times:" $x >> $reboot_log
else
	touch $reboot_log
        echo "------------------------start-------------------------" >> $reboot_log
        echo "$EXEC_DATE ::fisrt touch file!" >> $reboot_log
        echo -e "reboot times:" $x >> $reboot_log
fi

SERVICE_NAME=""
x=0

for((i=1;i<=$service_n;i++));
do
SERVICE_NAME=$(eval echo '${service_'"${i}"'}')
if [ ! -f ${record_dir}/${SERVICE_NAME}_pid ]; then
	# rm ${record_dir}/${SERVICE_NAME}_pid_list ${record_dir}/${SERVICE_NAME}_restart_times
	touch ${record_dir}/${SERVICE_NAME}_pid ${record_dir}/${SERVICE_NAME}_pid_lists ${record_dir}/${SERVICE_NAME}_restart_times
	echo "$x" > ${record_dir}/${SERVICE_NAME}_restart_times

fi
done

declare -i p=0
declare -i r=0
declare -i n=0


while [ "1" = "1" ]
do
	echo "-------------monitor--------------" >> $monitor_doc
	CURRENT_DATE=$(date "+%Y-%m-%d %H:%M:%S")
	echo "$CURRENT_DATE :: exec monitor" >> $monitor_doc
	
	for((i=1;i<=$service_n;i++));
	do
		SERVICE_NAME=$(eval echo '${service_'"${i}"'}')
		echo "----div----" >> $monitor_doc
		systemctl status ${SERVICE_NAME}.service | grep -E "Loaded|Active|PID|Tasks" | tee -a $monitor_doc
		p=$(systemctl status ${SERVICE_NAME}.service | grep -E PID | cut -c -24 | tr -cd 0-9)
		r=$(cat ${record_dir}/${SERVICE_NAME}_pid)
		x=$(cat ${record_dir}/${SERVICE_NAME}_restart_times)
		# echo "p is $p .r is $r. x is $x"
		if [[ "${p}" == "${r}" ]]; then
			echo "${p}" > ${record_dir}/${SERVICE_NAME}_pid
		elif [[ "0" == "${r}" ]]; then
			echo "${p}" > ${record_dir}/${SERVICE_NAME}_pid
			echo "time : $CURRENT_DATE ; ${SERVICE_NAME}_PID is : ${p}" >> ${record_dir}/${SERVICE_NAME}_pid_lists
		else
			echo "${p}" > ${record_dir}/${SERVICE_NAME}_pid
			echo "time : $CURRENT_DATE ; ${SERVICE_NAME}_PID is : ${p}" >> ${record_dir}/${SERVICE_NAME}_pid_lists
			x=$(($x+1))
			echo "$x" > ${record_dir}/${SERVICE_NAME}_restart_times
		fi
	done
	n=$(($n+1))
	# echo "$n"
	if [[ "3" -eq "${n}" ]]; then
		n=0
		n_strings=$(ping -c 4 ${SERVER_NAME})
		if [[ ! "0%" == "$(echo "${n_strings}" | grep "packet" | cut -c 36-37)" ]];then
			if [[ -n "$(echo "${n_strings}" | grep "Out")" ]];then
				echo "time : $CURRENT_DATE ; PING SERVER RETURN TIMEOUT: $(echo "${n_strings}" | grep "Out") " >> ${record_dir}/network_record.txt
			elif  [[ -n "$(echo "${n_strings}" | grep "Unreachable")" ]];then
				echo "time : $CURRENT_DATE ; PING SERVER RETURN Unreachable: $(echo "${n_strings}" | grep "Unreachable") " >> ${record_dir}/network_record.txt
			else
				echo "time : $CURRENT_DATE ; PING SERVER RETURN LOSS: $(echo "${n_strings}" | grep "packet") " >> ${record_dir}/network_record.txt
			fi
		# echo "ping false."
		# else
		# echo "ping ok."
		fi
	fi
	sync  #sync write data
	sleep $SLEEP_TIME
done
