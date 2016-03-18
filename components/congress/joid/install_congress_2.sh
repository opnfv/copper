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

# This is script 2 of 2 for installation of Congress on an Ubuntu 14.04 
# LXC container in the OPNFV Controller node.
# Prequisite: OPFNV install per https://wiki.opnfv.org/copper/academy/joid
#
# On jumphost:
# Download admin-openrc.sh from Horizon and save in ~
# source ~/git/copper/components/congress/joid/install_congress_1.sh
# (copies install_congress_2.sh to node1-control and executes it)

set -x
source ~/admin-openrc.sh <<EOF
openstack
EOF
source ~/env.sh

# Update package repos
sudo apt-get update

# install pip
sudo apt-get install python-pip -y

# install java
sudo apt-get install default-jre -y

# install other dependencies
sudo apt-get install apg git gcc python-dev libxml2 libxslt1-dev libzip-dev -y

# set mysql root user password and install mysql
export MYSQL_PASSWORD=$(/usr/bin/apg -n 1 -m 16 -c cl_seed)
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password '$MYSQL_PASSWORD
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password '$MYSQL_PASSWORD
sudo -E apt-get -q -y install mysql-server python-mysqldb

# Clone congress
mkdir ~/git
cd ~/git
git clone https://github.com/openstack/congress.git
cd congress
git checkout stable/liberty

# Install virtualenv
sudo pip install virtualenv

# Create virtualenv
virtualenv ~/git/congress
source bin/activate

# Setup Congress
sudo mkdir -p /etc/congress
sudo mkdir -p /etc/congress/snapshot
sudo mkdir /var/log/congress
sudo chown ubuntu /var/log/congress
sudo cp etc/api-paste.ini /etc/congress
sudo cp etc/policy.json /etc/congress

# install requirements.txt and tox dependencies (detected by errors during "tox -egenconfig")
sudo apt-get install libffi-dev -y
sudo apt-get install openssl -y
sudo apt-get install libssl-dev -y

# install dependencies of Congress
cd ~/git/congress
sudo pip install -r requirements.txt
sudo pip install .

# install tox
sudo pip install tox

# generate congress.conf.sample
sudo tox -egenconfig

# edit congress.conf.sample as needed
sudo sed -i -- 's/#verbose = true/verbose = true/g' etc/congress.conf.sample
sudo sed -i -- 's/#log_file = <None>/log_file = congress.log/g' etc/congress.conf.sample
sudo sed -i -- 's/#log_dir = <None>/log_dir = \/var\/log\/congress/g' etc/congress.conf.sample
sudo sed -i -- 's/#bind_host = 0.0.0.0/bind_host = '$CONGRESS_HOST'/g' etc/congress.conf.sample
sudo sed -i -- 's/#policy_path = <None>/policy_path = \/etc\/congress\/snapshot/g' etc/congress.conf.sample
sudo sed -i -- 's/#auth_strategy = keystone/auth_strategy = noauth/g' etc/congress.conf.sample
sudo sed -i -- 's/#drivers =/drivers = congress.datasources.neutronv2_driver.NeutronV2Driver,congress.datasources.glancev2_driver.GlanceV2Driver,congress.datasources.nova_driver.NovaDriver,congress.datasources.keystone_driver.KeystoneDriver,congress.datasources.ceilometer_driver.CeilometerDriver,congress.datasources.cinder_driver.CinderDriver/g' etc/congress.conf.sample
sudo sed -i -- 's/#auth_host = 127.0.0.1/auth_host = '$CONGRESS_HOST'/g' etc/congress.conf.sample
sudo sed -i -- 's/#auth_port = 35357/auth_port = 35357/g' etc/congress.conf.sample
sudo sed -i -- 's/#auth_protocol = https/auth_protocol = http/g' etc/congress.conf.sample
sudo sed -i -- 's/#admin_tenant_name = admin/admin_tenant_name = admin/g' etc/congress.conf.sample
sudo sed -i -- 's/#admin_user = <None>/admin_user = congress/g' etc/congress.conf.sample
sudo sed -i -- 's/#admin_password = <None>/admin_password = congress/g' etc/congress.conf.sample
sudo sed -i -- 's/#connection = <None>/connection = mysql:\/\/ubuntu:'$MYSQL_PASSWORD'@localhost:3306\/congress/g' etc/congress.conf.sample

# copy congress.conf.sample to /etc/congress
sudo cp etc/congress.conf.sample /etc/congress/congress.conf

# create congress database
sudo mysql --user=root --password=$MYSQL_PASSWORD -e "CREATE DATABASE congress; GRANT ALL PRIVILEGES ON congress.* TO 'ubuntu@localhost' IDENTIFIED BY '"$MYSQL_PASSWORD"'; GRANT ALL PRIVILEGES ON congress.* TO 'ubuntu'@'%' IDENTIFIED BY '"$MYSQL_PASSWORD"'; exit;"

# install congress-db-manage dependencies (detected by errors)
sudo apt-get build-dep python-mysqldb -y
pip install MySQL-python

# create database schema
congress-db-manage --config-file /etc/congress/congress.conf upgrade head

# Install and test OpenStack client
cd ~/git
git clone https://github.com/openstack/python-openstackclient.git
cd python-openstackclient
git checkout stable/liberty
sudo pip install -r requirements.txt
sudo pip install .
openstack service list

# Install and test Congress client
cd ~/git
git clone https://github.com/openstack/python-congressclient.git
cd python-congressclient
git checkout stable/liberty
sudo pip install -r requirements.txt
sudo pip install .
openstack congress driver list

# Install and test Keystone client
cd ~/git
git clone https://github.com/openstack/python-keystoneclient.git
cd python-keystoneclient
git checkout stable/liberty
sudo pip install -r requirements.txt
sudo pip install .

# setup Congress user. TODO: needs update in http://congress.readthedocs.org/en/latest/readme.html#installing-congress
pip install cliff --upgrade
export ADMIN_ROLE=$(openstack role list | awk "/ admin / { print \$2 }")
export SERVICE_TENANT=$(openstack project list | awk "/ admin / { print \$2 }")
openstack user create --password congress --project admin --email "congress@example.com" congress
export CONGRESS_USER=$(openstack user list | awk "/ congress / { print \$2 }")
openstack role add --user $CONGRESS_USER --project $SERVICE_TENANT $ADMIN_ROLE 

# Create Congress service
openstack service create congress --type "policy" --description "Congress Service"
export CONGRESS_SERVICE=$(openstack service list | awk "/ congress / { print \$2 }")

# Create Congress endpoint
openstack endpoint create $CONGRESS_SERVICE \
  --region $OS_REGION_NAME \
  --publicurl http://$CONGRESS_HOST:1789/ \
  --adminurl http://$CONGRESS_HOST:1789/ \
  --internalurl http://$CONGRESS_HOST:1789/

# Start the Congress service in the background
cd ~/git/congress
sudo bin/congress-server &

# disown the process (so it keeps running if you get disconnected)
disown -h %1

# Create data sources
# To remove datasources: openstack congress datasource delete <name> 
# Insert a delay here, as nova datasource seems to fail to get setup (server not ready?)
sleep 10
openstack congress datasource create nova "nova" \
  --config username=$OS_USERNAME \
  --config tenant_name=$OS_TENANT_NAME \
  --config password=$OS_PASSWORD \
  --config auth_url=http://$KEYSTONE_HOST:5000/v2.0
openstack congress datasource create neutronv2 "neutronv2" \
  --config username=$OS_USERNAME \
  --config tenant_name=$OS_TENANT_NAME \
  --config password=$OS_PASSWORD \
  --config auth_url=http://$KEYSTONE_HOST:5000/v2.0
openstack congress datasource create ceilometer "ceilometer" \
  --config username=$OS_USERNAME \
  --config tenant_name=$OS_TENANT_NAME \
  --config password=$OS_PASSWORD \
  --config auth_url=http://$KEYSTONE_HOST:5000/v2.0
openstack congress datasource create cinder "cinder" \
  --config username=$OS_USERNAME \
  --config tenant_name=$OS_TENANT_NAME \
  --config password=$OS_PASSWORD \
  --config auth_url=http://$KEYSTONE_HOST:5000/v2.0
openstack congress datasource create glancev2 "glancev2" \
  --config username=$OS_USERNAME \
  --config tenant_name=$OS_TENANT_NAME \
  --config password=$OS_PASSWORD \
  --config auth_url=http://$KEYSTONE_HOST:5000/v2.0
openstack congress datasource create keystone "keystone" \
  --config username=$OS_USERNAME \
  --config tenant_name=$OS_TENANT_NAME \
  --config password=$OS_PASSWORD \
  --config auth_url=http://$KEYSTONE_HOST:5000/v2.0 

# Run Congress Tempest Tests
cd ~/git/congress
# tox -epy27
set +x
return
