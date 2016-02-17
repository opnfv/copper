#!/bin/bash
# Copyright 2015-2016 Open Platform for NFV Project, Inc. and its contributors
#  
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#  
# http://www.apache.org/licenses/LICENSE-2.0
#  
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# What this is: script 2 of 2 for installation of a test server for Congress.
# Status: this is a work in progress, under test.
#
# Prequisite: OPFNV install per https://wiki.opnfv.org/copper/academy/joid
# On jumphost:
# - Congress installed through install_congress_1/2/3/4.sh
# - ~/env.sh created as part of Congress install (install_congress_3.sh)
# How to use:
#   Install OPNFV per https://wiki.opnfv.org/copper/academy/joid
#   $ source ~/git/copper/tests/setup/install_congress_testserver_1.sh

# === Configure the test server ===
# <code>

sudo apt-get update
sudo apt-get upgrade -y

# Install pip
sudo apt-get install python-pip -y

# Install java
sudo apt-get install default-jre -y

# Install other dependencies
sudo apt-get install git gcc python-dev libxml2 libxslt1-dev libzip-dev php5-curl -y

# Setup OpenStack environment variables per your OPNFV install
source ~/env.sh
source ~/admin-openrc.sh <<EOF
openstack
EOF

# Install and test OpenStack client
mkdir ~/coppertest
mkdir ~/coppertest/git
cd git
git clone https://github.com/openstack/python-openstackclient.git
cd python-openstackclient
git checkout stable/liberty
sudo pip install -r requirements.txt
sudo pip install .
openstack service list

# Install and test Congress client
cd ~/coppertest/git
git clone https://github.com/openstack/python-congressclient.git
cd python-congressclient
git checkout stable/liberty
sudo pip install -r requirements.txt
sudo pip install .
openstack congress driver list

# Install and test Glance client
cd ~/coppertest/git
git clone https://github.com/openstack/python-glanceclient.git
cd python-glanceclient
git checkout stable/liberty
sudo pip install -r requirements.txt
sudo pip install .
glance image-list

# Install and test Neutron client
cd ~/coppertest/git
git clone https://github.com/openstack/python-neutronclient.git
cd python-neutronclient
git checkout stable/liberty
sudo pip install -r requirements.txt
sudo pip install .
neutron net-list

# Install and test Nova client
cd ~/coppertest/git
git clone https://github.com/openstack/python-novaclient.git
cd python-novaclient
git checkout stable/liberty
sudo pip install -r requirements.txt
sudo pip install .
nova hypervisor-list

# Install and test Keystone client
cd ~/coppertest/git
git clone https://github.com/openstack/python-keystoneclient.git
cd python-keystoneclient
git checkout stable/liberty
sudo pip install -r requirements.txt
sudo pip install .

# </code>

# === Setup the Congress Test Webapp ===

# <code>
# Clone Copper (if not already cloned in user home)
cd ~/coppertest/git
if [ ! -d ~/coppertest/git/copper ]; then git clone https://gerrit.opnfv.org/gerrit/copper; fi

# Install Apache, PHP
sudo apt-get install -y apache2 php5 libapache2-mod-php5
sudo /etc/init.d/apache2 restart

# Copy the Apache config
sudo cp ~/coppertest/git/copper/components/congress/test-webapp/www/ubuntu-apache2.conf /etc/apache2/apache2.conf

# Copy the webapp to the Apache root directory and fix permissions
sudo cp -R ~/coppertest/git/copper/components/congress/test-webapp/www/html /var/www
sudo chmod 755 /var/www/html -R

# Point copper.js to the trusty-copper server per your install
sudo sed -i -- "s/COPPER_HOST/$COPPER_HOST/g" /var/www/html/copper.js

# Point proxy.php to the Congress server per your install
sudo sed -i -- "s/CONGRESS_HOST/$CONGRESS_HOST/g" /var/www/html/proxy/index.php

# Make webapp log directory and set permissions
mkdir ~/coppertest/logs
chmod 777 ~/coppertest/logs

# Restart Apache
sudo service apache2 restart
# </code>
