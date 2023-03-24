#!/usr/bin/env bash

#before use,exec 'sudo chown -R ${USER} /home/syslog_monitor'in unprivileged user
sleep 3 #first run will sleep 3 seconds

SLEEP_TIME="15" # unit is second
ETH_NAME="eth0"
daily_exec="/edge/reboot.sh"
hour_random=$(echo $RANDOM)
Version="1.0.5"
minute_random=$(echo $RANDOM)


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
REF_WEBSITE="www.baidu.com"

if [ ! -d "${record_dir}" ]; then
	mkdir ${record_dir}
fi

if [ -f "$monitor_doc" ]
then
	if [[ "100000000" -lt "$(stat -c "%s" $monitor_doc)" ]]; then
		rm $monitor_doc
		touch $monitor_doc
	fi
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


hour_calc=$(($hour_random*5/32768))
minute_calc=$(($minute_random*60/32768))

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
declare -i u=0

echo "$(date "+%H")" > ${record_dir}/hour


while [ "1" = "1" ]
do
	sleep $SLEEP_TIME

	echo "-------------monitor--------------" >> $monitor_doc
	CURRENT_DATE=$(date "+%Y-%m-%d %H:%M:%S")
	echo "$CURRENT_DATE :: exec monitor" >> $monitor_doc
	
	if [ "06:30" == "$(date "+%H:%M")" ] && [ ! "06" == "$EXEC_DATE" ]
	then

		crontab_file=$(cat /etc/crontab | grep ${daily_exec})
		if [ -z "${crontab_file}" ]; then
			sudo echo "${minute_calc} ${hour_calc} * * * root ${daily_exec}" >> /etc/crontab
			sync
			crontab /etc/crontab
			systemctl start cron
		else
			sed -i '$d' /etc/crontab
			sudo echo "${minute_calc} ${hour_calc} * * * root ${daily_exec}" >> /etc/crontab
			sync
			crontab /etc/crontab
			systemctl start cron
		fi

		crontab_ret=$(sudo crontab -l | grep ${daily_exec})
		if [ -z "${crontab_ret}" ]; then
			sudo crontab /etc/crontab
		fi
		echo "time : ${EXEC_DATE} ; cron config: ${crontab_ret}" >> ${record_dir}/crontab_list
		EXEC_DATE="06"
	fi

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
	if [[ "8" -eq "${n}" ]]; then
		n=0
		CURRENT_DATE=$(date "+%Y-%m-%d %H:%M:%S")

		ip_detector=$(ifconfig ${ETH_NAME} | grep inet | grep -v inet6 | cut -c 14-28)
		if [ -z "${ip_detector}" ]; then
			sudo ifconfig ${ETH_NAME} down
			sleep 1
			sudo ifconfig ${ETH_NAME} up
			echo "time : $CURRENT_DATE ; ip can't obtain, return ip : ${ip_detector}">> ${record_dir}/${ETH_NAME}_loss_ip_lists
		fi

		n_strings=$(ping -c 4 ${SERVER_NAME})
		ref_strings=$(ping -c 2 ${REF_WEBSITE})
		if [[ ! "0%" == "$(echo "${n_strings}" | grep "packet" | cut -c 36-37)" ]];then
			if [[ -n "$(echo "${n_strings}" | grep "Out")" ]];then
				echo "time : $CURRENT_DATE ; PING SERVER RETURN TIMEOUT: $(echo "${n_strings}" | grep "Out") " >> ${record_dir}/network_record.txt
			elif  [[ -n "$(echo "${n_strings}" | grep -E "Unreachable|unreachable")" ]];then
				echo "time : $CURRENT_DATE ; PING SERVER RETURN unreachable: $(echo "${n_strings}" | grep -E "Unreachable|unreachable") " >> ${record_dir}/network_record.txt
				sudo ifconfig ${ETH_NAME} down
				sudo ifconfig ${ETH_NAME} up
				sudo systemctl stop NetworkManager
				sudo systemctl restart networking
				sleep 2
				if [[ "$(date "+%H")" != "$(cat ${record_dir}/hour)" ]]; then
					u=0
					echo "$(date "+%H")" > ${record_dir}/hour
				fi
				u=$(($u+1)) #continue but no intermittent
				echo "$CURRENT_DATE: $u" >> ${record_dir}/ur_count
				ret = $(systemctl status networking | grep "Active" | awk -F" " '{print $2}')
				if [[ "failed" == "${ret}" ]]; then
					sync
					$(${daily_exec})
				elif [[ "10" -le "${u}" ]]; then
					sync
					$(${daily_exec})
				fi
			else
				echo "time : $CURRENT_DATE ; PING SERVER RETURN LOSS: $(echo "${n_strings}" | grep "packet") " >> ${record_dir}/network_record.txt
			fi
		# echo "ping false."
		# else
		# echo "ping ok."
		fi
		if [[ ! "0%" == "$(echo "${ref_strings}" | grep "packet" | awk -F" " '{print $6}')" ]];then
			echo "time : $CURRENT_DATE ; PING REFERENCE WEBSITE RETURN: $ref_strings " >> ${record_dir}/ref_network_record.txt

		fi
	fi
	sync  #sync write data

done
