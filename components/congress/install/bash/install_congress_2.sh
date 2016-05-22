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
# This is script 2 of 2 for installation of Congress on the OPNFV Controller
# node as installed via JOID or Apex (Fuel and Compass not yet verified).
# Prerequisites: 
# - OPFNV installed via JOID or Apex
# - For Apex installs, on the jumphost, ssh to the undercloud VM and
#     $ su stack
# - For JOID installs, admin-openrc.sh saved from Horizon to ~/admin-openrc.sh
# - Retrieve the copper install script as below, optionally specifying the 
#   branch to use as a URL parameter, e.g. ?h=stable%2Fbrahmaputra
# $ cd ~
# $ wget https://git.opnfv.org/cgit/copper/tree/components/congress/install/bash/install_congress_1.sh
# $ wget https://git.opnfv.org/cgit/copper/tree/components/congress/install/bash/install_congress_2.sh
# $ source install_congress_1.sh [openstack-branch]
#   optionally specifying the branch identifier to use for OpenStack
#     

set -x

if [ $# -eq 1 ]; then osbranch=$1; fi

echo "OS-specific prerequisite steps"
dist=`grep DISTRIB_ID /etc/*-release | awk -F '=' '{print $2}'`

if [ "$dist" == "Ubuntu" ]; then
  # Ubuntu
  echo "Ubuntu-based install"
  export CTLUSER="ubuntu"
  source ~/congress/admin-openrc.sh <<EOF
openstack
EOF
  source ~/congress/env.sh
  echo "Update/upgrade package repos"
  sudo apt-get update
  echo "install pip"
  sudo apt-get install python-pip -y
  echo "install java"
  sudo apt-get install default-jre -y
  echo "install other dependencies"
  sudo apt-get install apg git gcc python-dev libxml2 libxslt1-dev libzip-dev -y
  sudo pip install --upgrade pip virtualenv setuptools pbr tox
  echo "set mysql root user password and install mysql"
  export MYSQL_PASSWORD=$(/usr/bin/apg -n 1 -m 16 -c cl_seed)
  sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password '$MYSQL_PASSWORD
  sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password '$MYSQL_PASSWORD
  sudo -E apt-get -q -y install mysql-server python-mysqldb
  echo "install tox dependencies (detected by errors during 'tox -egenconfig')"
  sudo apt-get install libffi-dev openssl libssl-dev -y
else
  # Centos
  echo "Centos-based install"
  export CTLUSER="heat-admin"
  source ~/congress/admin-openrc.sh
  source ~/congress/env.sh
  echo "install pip"
  sudo yum install python-pip -y
  echo "install other dependencies"
  sudo yum install apg git gcc libxml2 python-devel libzip-devel libxslt-devel -y
  sudo pip install --upgrade pip virtualenv setuptools pbr tox
  echo "install tox dependencies (detected by errors during 'tox -egenconfig')"
  sudo yum install libffi-devel openssl openssl-devel -y
fi

echo "Create virtualenv"
virtualenv ~/congress/venv
cd ~/congress/venv
source bin/activate

echo "Clone congress"
cd ~/congress
git clone https://github.com/openstack/congress.git
cd congress
if [ $# -eq 1 ]; then git checkout $1; fi

echo "Install OpenStack client"
cd ~/congress
git clone https://github.com/openstack/python-openstackclient.git
cd python-openstackclient
if [ $# -eq 1 ]; then git checkout $1; fi
pip install -r requirements.txt
pip install .

echo "Setup Congress"
cd ~/congress/congress
sudo mkdir -p /etc/congress
sudo chown $CTLUSER /etc/congress
sudo mkdir -p /etc/congress/snapshot
sudo mkdir /var/log/congress
sudo chown $CTLUSER  /var/log/congress
cp etc/api-paste.ini /etc/congress
cp etc/policy.json /etc/congress

echo "install dependencies of Congress"
cd ~/congress/congress
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
sed -i -- 's/#connection = <None>/connection = mysql:\/\/congress@localhost:3306\/congress/g' etc/congress.conf.sample

echo "copy congress.conf.sample to /etc/congress"
cp etc/congress.conf.sample /etc/congress/congress.conf

echo "create congress database"
sudo mysql -e "CREATE DATABASE congress; GRANT ALL PRIVILEGES ON congress.* TO 'congress';"

echo "install congress-db-manage dependencies (detected by errors)"
if [ "$dist" == "Ubuntu" ]; then sudo apt-get build-dep python-mysqldb -y; fi
pip install MySQL-python

echo "create database schema"
congress-db-manage --config-file /etc/congress/congress.conf upgrade head

echo "Install Congress client"
cd ~/congress
git clone https://github.com/openstack/python-congressclient.git
cd python-congressclient
if [ $# -eq 1 ]; then git checkout $1; fi
pip install -r requirements.txt
pip install .

# Fix error found during startup of congress server
echo "Install python fixtures"
pip install fixtures

# TODO: The rest of this script is not yet tested
function _congress_setup_horizon {
  local HORIZON_DIR="/usr/share/openstack-dashboard"
  local CONGRESS_HORIZON_DIR="/home/heat-admin/git/congress/contrib/horizon"
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
