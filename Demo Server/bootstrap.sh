#!/usr/bin/env bash

# Python 3.5 (& pip)
sudo add-apt-repository ppa:fkrull/deadsnakes
sudo apt-get update
sudo apt-get install -y python3.5
sudo apt-get install -y python-pip

# Bonjour
sudo apt-get install -y avahi-daemon
sudo apt-get install -y libnss-mdns

# Misc
sudo apt-get install -y libyaml-dev

# Set up our software
cd /vagrant
sudo pip install -r requirements.txt
sudo cp /vagrant/my_echo.conf /etc/init

# Start our software
sudo initctl start my_echo
