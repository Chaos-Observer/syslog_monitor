#!/usr/bin/env bash

sudo ./uninstall.sh
sudo cp -r ../syslog_monitor /home/

if [ ${USER} = root ]
then
sudo chown -R vaitl /home/syslog_monitor
else
sudo chown -R ${USER} /home/syslog_monitor
fi

sudo cp ./user_monitor.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable user_monitor.service
sudo systemctl start user_monitor.service
sudo sleep 1
sudo sync


# sudo shutdown -r +1
# sudo kill -9 $(pgrep fluent)
# sudo pgrep fluent
# sudo systemctl stop fluentbit
# sudo reboot
