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
# LXC container (same as Horizon) in the OPNFV Controller node.
# Prequisite: OPFNV install per https://wiki.opnfv.org/copper/academy/joid
#
# On jumphost:
# Download admin-openrc.sh from Horizon and save in ~
# source install_congress_1b.sh <host>
# (copies install_congress_2b.sh to <host> and executes it)
# <hostname> is the name of the host in which to install Congress.
# 
# If "horizon", Congress will be installed in the same LXC as Horizon,
# as necessary for the OpenStack Dashboard Policy plugins to work.
# Otherwise provide the node name of the controller node, where Congress
# will be installed in an LXC (NOTE: Policy plugin for OpenStack dashboard
# does not currently get installed for the LXC-based Congress deploy)

set -x
source ~/admin-openrc.sh <<EOF
openstack
EOF
source ~/env.sh

echo "Update package repos"
sudo apt-get update

echo "install pip"
sudo apt-get install python-pip -y

echo "install java"
sudo apt-get install default-jre -y

echo "install other dependencies"
sudo apt-get install apg git gcc python-dev libxml2 libxslt1-dev libzip-dev -y

echo "set mysql root user password and install mysql"
export MYSQL_PASSWORD=$(/usr/bin/apg -n 1 -m 16 -c cl_seed)
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password '$MYSQL_PASSWORD
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password '$MYSQL_PASSWORD
sudo -E apt-get -q -y install mysql-server python-mysqldb

echo "Clone congress"
mkdir ~/git
cd ~/git
git clone https://github.com/openstack/congress.git
cd congress
git checkout stable/liberty

echo "Setup Congress"
sudo mkdir -p /etc/congress
sudo chown ubuntu /etc/congress
mkdir -p /etc/congress/snapshot
sudo mkdir /var/log/congress
sudo chown ubuntu /var/log/congress
cp etc/api-paste.ini /etc/congress
cp etc/policy.json /etc/congress

echo "install requirements.txt and tox dependencies (detected by errors during 'tox -egenconfig')"
sudo apt-get install libffi-dev -y
sudo apt-get install openssl -y
sudo apt-get install libssl-dev -y

echo "install dependencies of Congress"
cd ~/git/congress
pip install -r requirements.txt
pip install .

echo "install tox"
pip install tox

echo "generate congress.conf.sample"
tox -egenconfig

echo "edit congress.conf.sample as needed"
sed -i -- 's/#verbose = true/verbose = true/g' etc/congress.conf.sample
sed -i -- 's/#log_file = <None>/log_file = congress.log/g' etc/congress.conf.sample
sed -i -- 's/#log_dir = <None>/log_dir = \/var\/log\/congress/g' etc/congress.conf.sample
sed -i -- 's/#bind_host = 0.0.0.0/bind_host = '$CONGRESS_HOST'/g' etc/congress.conf.sample
sed -i -- 's/#policy_path = <None>/policy_path = \/etc\/congress\/snapshot/g' etc/congress.conf.sample
sed -i -- 's/#auth_strategy = keystone/auth_strategy = noauth/g' etc/congress.conf.sample
sed -i -- 's/#drivers =/drivers = congress.datasources.neutronv2_driver.NeutronV2Driver,congress.datasources.glancev2_driver.GlanceV2Driver,congress.datasources.nova_driver.NovaDriver,congress.datasources.keystone_driver.KeystoneDriver,congress.datasources.ceilometer_driver.CeilometerDriver,congress.datasources.cinder_driver.CinderDriver/g' etc/congress.conf.sample
sed -i -- 's/#auth_host = 127.0.0.1/auth_host = '$CONGRESS_HOST'/g' etc/congress.conf.sample
sed -i -- 's/#auth_port = 35357/auth_port = 35357/g' etc/congress.conf.sample
sed -i -- 's/#auth_protocol = https/auth_protocol = http/g' etc/congress.conf.sample
sed -i -- 's/#admin_tenant_name = admin/admin_tenant_name = admin/g' etc/congress.conf.sample
sed -i -- 's/#admin_user = <None>/admin_user = congress/g' etc/congress.conf.sample
sed -i -- 's/#admin_password = <None>/admin_password = congress/g' etc/congress.conf.sample
sed -i -- 's/#connection = <None>/connection = mysql:\/\/ubuntu:'$MYSQL_PASSWORD'@localhost:3306\/congress/g' etc/congress.conf.sample

echo "copy congress.conf.sample to /etc/congress"
cp etc/congress.conf.sample /etc/congress/congress.conf

echo "create congress database"
sudo mysql --user=root --password=$MYSQL_PASSWORD -e "CREATE DATABASE congress; GRANT ALL PRIVILEGES ON congress.* TO 'ubuntu@localhost' IDENTIFIED BY '"$MYSQL_PASSWORD"'; GRANT ALL PRIVILEGES ON congress.* TO 'ubuntu'@'%' IDENTIFIED BY '"$MYSQL_PASSWORD"'; exit;"

echo "install congress-db-manage dependencies (detected by errors)"
sudo apt-get build-dep python-mysqldb -y
pip install MySQL-python

echo "create database schema"
congress-db-manage --config-file /etc/congress/congress.conf upgrade head

echo "Start the Congress service in the background"
cd ~/git/congress
sudo bin/congress-server &

echo "disown the process (so it keeps running if you get disconnected)"
disown -h %1

echo "Install Congress client"
cd ~/git
git clone https://github.com/openstack/python-congressclient.git
cd python-congressclient
git checkout stable/liberty
pip install -r requirements.txt
pip install .

function _congress_setup_horizon {
  local HORIZON_DIR="/usr/share/openstack-dashboard"
  local CONGRESS_HORIZON_DIR="/home/ubuntu/git/congress/contrib/horizon"
  sudo cp -r $CONGRESS_HORIZON_DIR/datasources $HORIZON_DIR/openstack_dashboard/dashboards/admin/
  sudo cp -r $CONGRESS_HORIZON_DIR/policies $HORIZON_DIR/openstack_dashboard/dashboards/admin/
  sudo cp -r $CONGRESS_HORIZON_DIR/static $HORIZON_DIR/openstack_dashboard/dashboards/admin/
  sudo cp -r $CONGRESS_HORIZON_DIR/templates $HORIZON_DIR/openstack_dashboard/dashboards/admin/
  sudo cp $CONGRESS_HORIZON_DIR/congress.py $HORIZON_DIR/openstack_dashboard/api/
  sudo cp $CONGRESS_HORIZON_DIR/_50_policy.py $HORIZON_DIR/openstack_dashboard/local/enabled/
  sudo cp $CONGRESS_HORIZON_DIR/_60_policies.py $HORIZON_DIR/openstack_dashboard/local/enabled/
  sudo cp $CONGRESS_HORIZON_DIR/_70_datasources.py $HORIZON_DIR/openstack_dashboard/local/enabled/

  # For unit tests
  sudo sh -c 'echo "python-congressclient" >> '$HORIZON_DIR'/requirements.txt'
  sudo sh -c 'echo -e \
"\n# Load the pluggable dashboard settings"\
"\nimport openstack_dashboard.local.enabled"\
"\nfrom openstack_dashboard.utils import settings"\
"\n\nINSTALLED_APPS = list(INSTALLED_APPS)"\
"\nsettings.update_dashboards(["\
"\n    openstack_dashboard.local.enabled,"\
"\n], HORIZON_CONFIG, INSTALLED_APPS)" >> '$HORIZON_DIR'/openstack_dashboard/test/settings.py'

  # Setup alias for django-admin which could be different depending on distro
  local django_admin
  if type -p django-admin > /dev/null; then
      django_admin=django-admin
  else
      django_admin=django-admin.py
  fi

  # Collect and compress static files (e.g., JavaScript, CSS)
  DJANGO_SETTINGS_MODULE=openstack_dashboard.settings $django_admin collectstatic --noinput
  DJANGO_SETTINGS_MODULE=openstack_dashboard.settings $django_admin compress --force

  # Restart Horizon
  sudo service apache2 restart
}
# Commented out as the procedure is not yet working
#echo "Install Horizon Policy plugin"
#_congress_setup_horizon

set +x #echo off
