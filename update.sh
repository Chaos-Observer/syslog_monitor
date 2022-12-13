#!/usr/bin/env bash


sudo systemctl stop user_monitor.service
sudo cp -r ../syslog_monitor /home/

if [ ${USER} = root ]
then
sudo chown -R vaitl /home/syslog_monitor
else
sudo chown -R ${USER} /home/syslog_monitor
fi

sudo ./clean.sh
