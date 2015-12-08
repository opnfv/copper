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

# This file contains instructions for installing Congress on an Ubuntu 14.04 LXC container in the OPNFV Controller node
# Prequisite: OPFNV install per https://wiki.opnfv.org/copper/academy/joid

# Install base VM for congress on controller node
sudo juju ssh ubuntu@192.168.10.21

# Clone the container
sudo lxc-clone -o juju-trusty-lxc-template -n juju-trusty-congress

# Start the container
sudo lxc-start -n juju-trusty-congress -d

# Get the container IP address
sudo lxc-info -n juju-trusty-congress

# If you need to start over
sudo lxc-destroy --name juju-trusty-congress

# login to congress container
sudo juju ssh ubuntu@192.168.10.117

# Per http://congress.readthedocs.org/en/latest/readme.html#installing-congress

# Setup environment variables
export CONGRESS_HOST=192.168.10.117
export KEYSTONE_HOST=192.168.10.108
export CEILOMETER_HOST=192.168.10.105
export CINDER_HOST=192.168.10.101
export GLANCE_HOST=192.168.10.106
export NEUTRON_HOST=192.168.10.111
export NOVA_HOST=192.168.10.112

# install pip
sudo apt-get install python-pip -y

# install java
sudo apt-get install default-jre -y

# install other dependencies; set mysql root user password = ubuntu
sudo apt-get install git gcc python-dev libxml2 libxslt1-dev libzip-dev mysql-server python-mysqldb -y
sudo pip install virtualenv

# clone congress
git clone https://github.com/openstack/congress.git

# Create virtualenv
virtualenv ~/congress
cd congress
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

# install dependencies in virtualenv
pip install -r requirements.txt
python setup.py install

# install tox
pip install tox

# generate congress.conf.sample
tox -egenconfig

# edit congress.conf.sample as needed
sed -i -- 's/#verbose = true/verbose = true/g' etc/congress.conf.sample
sed -i -- 's/#log_file = <None>/log_file = congress.log/g' etc/congress.conf.sample
sed -i -- 's/#log_dir = <None>/log_dir = \/var\/log\/congress/g' etc/congress.conf.sample
sed -i -- 's/#bind_host = 0.0.0.0/bind_host = 192.168.10.117/g' etc/congress.conf.sample
sed -i -- 's/#policy_path = <None>/policy_path = \/etc\/congress\/snapshot/g' etc/congress.conf.sample
sed -i -- 's/#auth_strategy = keystone/auth_strategy = noauth/g' etc/congress.conf.sample
sed -i -- 's/#drivers =/drivers = congress.datasources.neutronv2_driver.NeutronV2Driver,congress.datasources.glancev2_driver.GlanceV2Driver,congress.datasources.nova_driver.NovaDriver,congress.datasources.keystone_driver.KeystoneDriver,congress.datasources.ceilometer_driver.CeilometerDriver,congress.datasources.cinder_driver.CinderDriver/g' etc/congress.conf.sample
sed -i -- 's/#auth_host = 127.0.0.1/auth_host = 192.168.10.108/g' etc/congress.conf.sample
sed -i -- 's/#auth_port = 35357/auth_port = 35357/g' etc/congress.conf.sample
sed -i -- 's/#auth_protocol = https/auth_protocol = http/g' etc/congress.conf.sample
sed -i -- 's/#admin_tenant_name = admin/admin_tenant_name = admin/g' etc/congress.conf.sample
sed -i -- 's/#admin_user = <None>/admin_user = congress/g' etc/congress.conf.sample
sed -i -- 's/#admin_password = <None>/admin_password = congress/g' etc/congress.conf.sample
sed -i -- 's/#connection = <None>/connection = mysql:\/\/ubuntu:ubuntu@localhost:3306\/congress/g' etc/congress.conf.sample

# copy congress.conf.sample to /etc/congress
sudo cp etc/congress.conf.sample /etc/congress/congress.conf

# create congress database
sudo mysql -u root -p
CREATE DATABASE congress;
GRANT ALL PRIVILEGES ON congress.* TO 'ubuntu'@'localhost' IDENTIFIED BY 'ubuntu';
GRANT ALL PRIVILEGES ON congress.* TO 'ubuntu'@'%' IDENTIFIED BY 'ubuntu';
exit

# install congress-db-manage dependencies  (detected by errors)
sudo apt-get build-dep python-mysqldb
pip install MySQL-python

# create database schema
congress-db-manage --config-file /etc/congress/congress.conf upgrade head

# Dependencies no longer needed in this attempt...
#	pip install alembic
#	sudo pip install oslo.config --upgrade
#	sudo pip install oslo.db --upgrade
#	sudo pip install oslo.log --upgrade

# Dependencies of OpenStack, Congress, Keystone related client operations
pip install python-openstackclient
pip install python-congressclient
pip install python-keystoneclient

# download admin-openrc.sh from Horizon and save in ~
source ~/admin-openrc.sh

# setup Congress user. TODO: needs update in http://congress.readthedocs.org/en/latest/readme.html#installing-congress
pip install cliff --upgrade
export ADMIN_ROLE=$(openstack role list | awk "/ Admin / { print \$2 }")
export SERVICE_TENANT=$(openstack project list | awk "/ admin / { print \$2 }")
openstack user create --password congress --project admin --email "congress@example.com" congress
export CONGRESS_USER=$(openstack user list | awk "/ congress / { print \$2 }")
openstack role add $ADMIN_ROLE --user $CONGRESS_USER --project $SERVICE_TENANT

# Create Congress service
openstack service create congress --type "policy" --description "Congress Service"
export CONGRESS_SERVICE=$(openstack service list | awk "/ congress / { print \$2 }")

# Create Congress endpoint
openstack endpoint create $CONGRESS_SERVICE \
  --region $OS_REGION_NAME \
  --publicurl http://$CONGRESS_HOST:1789/ \
  --adminurl http://$CONGRESS_HOST:1789/ \
  --internalurl http://$CONGRESS_HOST:1789/

# Start the Congress service
bin/congress-server

# Create data sources
# to remove: openstack congress datasource delete nova
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


