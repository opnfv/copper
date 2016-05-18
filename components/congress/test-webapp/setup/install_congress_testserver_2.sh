#!/bin/bash
# Copyright 2015-2016 AT&T Intellectual Property, Inc
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
# Prequisite: OPFNV installed per JOID or Apex installer
# On jumphost:
# - Congress installed through install_congress_1.sh
# How to use:
#   $ source install_congress_testserver_1.sh

set -x

echo "Setup OpenStack environment variables per your OPNFV install"
source /opt/copper/env.sh
source /opt/copper/admin-openrc.sh

echo "Install prerequisites"
dist=`grep DISTRIB_ID /etc/*-release | awk -F '=' '{print $2}'`

if [ "$dist" == "Ubuntu" ]; then
  echo "Update the base server"
  set -x
  sudo apt-get update
  #sudo apt-get -y upgrade

  echo "Install pip"
  sudo apt-get install -y python-pip

  echo "Install java"
  sudo apt-get install -y default-jre

  echo "Install other dependencies"
  sudo apt-get install -y git gcc python-dev libxml2 libxslt1-dev libzip-dev php5-curl

  echo "Install Apache, PHP"
  sudo apt-get install -y apache2 php5 libapache2-mod-php5

  echo "Setup the Congress Test Webappp"

  echo "Copy the Apache config"
  sudo cp /opt/copper/www/ubuntu-apache2.conf /etc/apache2/apache2.conf

  echo "Copy the webapp to the Apache root directory and fix permissions"
  sudo cp -R /opt/copper/www/html /var/www
  sudo chmod 755 /var/www/html -R

  echo "Point copper.js to the trusty-copper server per your install"
  sudo sed -i -- "s/COPPER_HOST/$COPPER_HOST/g" /var/www/html/copper.js

  echo "Point proxy.php to the Congress server per your install"
  sudo sed -i -- "s/CONGRESS_HOST/$CONGRESS_HOST/g" /var/www/html/proxy/index.php

  echo "Make webapp log directory"
  mkdir /tmp/copper/log

  sudo /etc/init.d/apache2 restart

else

  echo "install pip"
  sudo yum install python-pip -y

  echo "install other dependencies"
  sudo yum install apg git gcc libxml2 python-devel libzip-devel libxslt-devel -y

  echo "Install Apache, PHP"
  sudo yum install -y httpd php

  echo "Setup the Congress Test Webappp"

  echo "Copy the Apache config"
  sudo cp /opt/copper/www/centos-httpd.conf /etc/httpd/conf/httpd.conf

  echo "Copy the webapp to the Apache root directory and fix permissions"
  sudo cp -R /opt/copper/www/html/* /var/www/html
  sudo chmod 755 /var/www/html -R

  echo "Point copper.js to the trusty-copper server per your install"
  sudo sed -i -- "s/COPPER_HOST/$COPPER_HOST/g" /var/www/html/copper.js

  echo "Point proxy.php to the Congress server per your install"
  sudo sed -i -- "s/CONGRESS_HOST/$CONGRESS_HOST/g" /var/www/html/proxy/index.php

  echo "Make webapp log directory"
  mkdir /tmp/copper/log

  sudo systemctl restart httpd.service

fi

echo "Install python dependencies"
sudo pip install --upgrade pip setuptools pbr tox

echo "Install OpenStack client"
mkdir /opt/copper/git
cd /opt/copper/git
git clone https://github.com/openstack/python-openstackclient.git
cd python-openstackclient
git checkout stable/liberty
sudo pip install -r requirements.txt
sudo pip install .

echo "Install Congress client"
cd /opt/copper/git
git clone https://github.com/openstack/python-congressclient.git
cd python-congressclient
git checkout stable/liberty
sudo pip install -r requirements.txt
sudo pip install .

echo "Install Glance client"
cd /opt/copper/git
git clone https://github.com/openstack/python-glanceclient.git
cd python-glanceclient
git checkout stable/liberty
sudo pip install -r requirements.txt
sudo pip install .

echo "Install Neutron client"
cd /opt/copper/git
git clone https://github.com/openstack/python-neutronclient.git
cd python-neutronclient
git checkout stable/liberty
sudo pip install -r requirements.txt
sudo pip install .

echo "Install Nova client"
cd /opt/copper/git
git clone https://github.com/openstack/python-novaclient.git
cd python-novaclient
git checkout stable/liberty
sudo pip install -r requirements.txt
sudo pip install .

echo "Install Keystone client"
cd /opt/copper/git
git clone https://github.com/openstack/python-keystoneclient.git
cd python-keystoneclient
git checkout stable/liberty
sudo pip install -r requirements.txt
sudo pip install .

set +x

