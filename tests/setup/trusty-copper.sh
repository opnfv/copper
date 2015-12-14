#!/bin/bash
# Copyright 2015 Open Platform for NFV Project, Inc. and its contributors
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
# What this is: A shell script for installing a test driver for 
# OpenStack Congress on Ubuntu.
# Status: this is a work in progress, under test. Some steps are 
# manual.
#
# How to use:
#   Install OPNFV per https://wiki.opnfv.org/copper/academy/joid
#   $ source ~/git/copper/tests/setup/trusty-copper.sh
#

Following are notes on creating a container as test driver for Congress. This is based upon an Ubuntu host as installed by JOID.

# === Create and Activate the Container ===

# <code>
# On the jumphost
sudo lxc-create -n trusty-copper -t /usr/share/lxc/templates/lxc-ubuntu -- -b ubuntu ~/opnfv

sudo lxc-start -n trusty-copper -d

sudo lxc-info --name trusty-copper

HOST_IP=$(sudo lxc-info --name trusty-copper | grep IP | awk "/ / { print \$2 }")
echo HOST_IP = $HOST_IP

# === Login and configure the test server ===
# <code>
ssh ubuntu@$HOST_IP
sudo apt-get update
sudo apt-get upgrade -y

# Install pip
sudo apt-get install python-pip -y

# Install java
sudo apt-get install default-jre -y

# Install other dependencies
sudo apt-get install git gcc python-dev libxml2 libxslt1-dev libzip-dev php5-curl -y

# Setup OpenStack environment variables per your OPNFV install
export CONGRESS_HOST=192.168.10.117
export KEYSTONE_HOST=192.168.10.108
export CEILOMETER_HOST=192.168.10.105
export CINDER_HOST=192.168.10.101
export GLANCE_HOST=192.168.10.106
export HEAT_HOST=192.168.10.107
export NEUTRON_HOST=192.168.10.111
export NOVA_HOST=192.168.10.112
source ~/admin-openrc.sh

# Install and test OpenStack client
mkdir ~/git
cd git
git clone https://github.com/openstack/python-openstackclient.git
cd python-openstackclient
git checkout stable/liberty
sudo pip install -r requirements.txt
sudo python setup.py install
openstack service list

# Install and test Congress client
cd ~/git
git clone https://github.com/openstack/python-congressclient.git
cd python-congressclient
git checkout stable/liberty
sudo pip install -r requirements.txt
sudo python setup.py install
openstack congress driver list

# Install and test Glance client
cd ~/git
git clone https://github.com/openstack/python-glanceclient.git
cd python-glanceclient
git checkout stable/liberty
sudo pip install -r requirements.txt
sudo python setup.py install
glance image-list

# Install and test Neutron client
cd ~/git
git clone https://github.com/openstack/python-neutronclient.git
cd python-neutronclient
git checkout stable/liberty
sudo pip install -r requirements.txt
sudo python setup.py install
neutron net-list

# Install and test Nova client
cd ~/git
git clone https://github.com/openstack/python-novaclient.git
cd python-novaclient
git checkout stable/liberty
sudo pip install -r requirements.txt
sudo python setup.py install
nova hypervisor-list

# Install and test Keystone client
cd ~/git
git clone https://github.com/openstack/python-keystoneclient.git
cd python-keystoneclient
git checkout stable/liberty
sudo pip install -r requirements.txt
sudo python setup.py install

# </code>

# === Setup the Congress Test Webapp ===

# <code>
# Clone Copper (if not already cloned in user home)
cd ~/git
if [ ! -d ~/git/copper ]; then git clone https://gerrit.opnfv.org/gerrit/copper; fi

# Copy the Apache config
sudo cp ~/git/copper/components/congress/test-webapp/www/ubuntu-apache2.conf /etc/apache2/apache2.conf

# Point proxy.php to the Congress server per your install
sed -i -- "s/192.168.10.117/$CONGRESS_HOST/g" \
  ~/git/copper/components/congress/test-webapp/www/html/proxy/index.php

# Copy the webapp to the Apache root directory and fix permissions
sudo cp -R ~/git/copper/components/congress/test-webapp/www/html /var/www
sudo chmod 755 /var/www/html -R

# Make webapp log directory and set permissions
mkdir ~/logs
chmod 777 ~/logs

# Restart Apache
sudo service apache2 restart
# </code>

# === Using the Test Webapp ===
# Browse to the trusty-copper server IP address.

# Interactive options are meant to be self-explanatory given a basic familiarity with the Congress service and data model. But the app will be developed with additional features and UI elements. 
