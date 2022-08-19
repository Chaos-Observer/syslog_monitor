#!/usr/bin/env bash


sudo systemctl stop user_monitor.service
sudo systemctl disable user_monitor.service
sudo rm /etc/systemd/system/user_monitor.service

sudo ./clean.sh

sleep 1
sync
