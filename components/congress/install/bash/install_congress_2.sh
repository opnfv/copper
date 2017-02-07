#!/bin/bash
# Copyright 2015-2017 AT&T Intellectual Property, Inc
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
# This is script 2 of 2 for installation of OpenStack Congress. This install 
# procedure is intended to deploy Congress for testing purposes only.
# Prerequisites: 
# - OpenStack base deployment.
# Usage:
# $ bash install_congress_2.sh <target> [branch]
#   <target>: IP/hostname where Congress is being installed
#   branch: branch identifier to use for OpenStack
#     

trap 'fail' ERR

pass() {
  echo "$0: $(date) Install Succeeded!"
  exit 0
}

fail() {
  echo "$0: $(date) Install Failed!"
  exit 1
}

set -x

if [[ ! -f /.dockerenv ]]; then 
  sudo -i
  mkdir /opt/congress
fi

target=$1
branch=$2

cd /opt/congress
source admin-openrc.sh

echo "$0: $(date) OS-specific prerequisite steps"
dist=`grep DISTRIB_ID /etc/*-release | awk -F '=' '{print $2}'`

echo "$0: $(date) Update/upgrade package repos"
apt-get update
echo "$0: $(date) install pip"
apt-get install python-pip -y
apt-get install python3-pip -y
echo "$0: $(date) install java"
apt-get install default-jre -y
echo "$0: $(date) install other dependencies"
apt-get install apg git gcc python-dev libxml2 libxslt1-dev libzip-dev build-essential libssl-dev libffi-dev -y
# pip install --upgrade pip setuptools pbr
echo "$0: $(date) set mysql root user password"
export MYSQL_PASSWORD=$(/usr/bin/apg -n 1 -m 16 -c cl_seed)
debconf-set-selections <<< 'mysql-server mysql-server/root_password password '$MYSQL_PASSWORD
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password '$MYSQL_PASSWORD
apt-get -q -y install mysql-server python-mysqldb
service mysql restart 

echo "$0: $(date) Clone congress"
cd /opt/congress
git clone https://github.com/openstack/congress.git
cd congress
if [ $# -eq 1 ]; then git checkout $branch; fi

echo "$0: $(date) install Congress code and dependencies"
cd /opt/congress/congress
pip install .
python setup.py install

echo "$0: $(date) Setup Congress"
mkdir -p /etc/congress
mkdir -p /etc/congress/snapshot
mkdir /var/log/congress
cp etc/api-paste.ini /etc/congress
cp etc/policy.json /etc/congress

#echo "$0: $(date) generate congress.conf.sample"
# TODO: tox can't be used for now due to exception with setuptools
# when trying to install pyparsing
#pip install tox
#tox -egenconfig
# For now, using a pre-generated congress.conf.sample as part of the 
# Models repo.

cp /opt/congress/congress.conf.sample etc/congress.conf.sample

echo "$0: $(date) edit congress.conf.sample as needed"
sed -i -- 's/#verbose = true/verbose = true/g' etc/congress.conf.sample
sed -i -- 's/#log_file = <None>/log_file = congress.log/g' etc/congress.conf.sample
sed -i -- 's/#log_dir = <None>/log_dir = \/var\/log\/congress/g' etc/congress.conf.sample
sed -i -- 's/#bind_host = 0.0.0.0/bind_host = '$target'/g' etc/congress.conf.sample
sed -i -- 's/#policy_path = <None>/policy_path = \/etc\/congress\/snapshot/g' etc/congress.conf.sample
# TODO: verify keystone auth strategy
sed -i -- 's/#auth_strategy = keystone/auth_strategy = noauth/g' etc/congress.conf.sample
sed -i -- "s/connection = mysql+pymysql:\/\/root:secret@127.0.0.1\/congress?charset=utf8/connection = mysql+pymysql:\/\/root:$MYSQL_PASSWORD@127.0.0.1\/congress?charset=utf8/" etc/congress.conf.sample
sed -i -- 's/#drivers = /drivers = congress.datasources.neutronv2_driver.NeutronV2Driver, congress.datasources.glancev2_driver.GlanceV2Driver, congress.datasources.nova_driver.NovaDriver, congress.datasources.keystone_driver.KeystoneDriver, congress.datasources.ceilometer_driver.CeilometerDriver, congress.datasources.cinder_driver.CinderDriver, congress.datasources.swift_driver.SwiftDriver, congress.datasources.heatv1_driver.HeatV1Driver\n#drivers = /' etc/congress.conf.sample

# TODO: find out how to get the Rabbit user, password, and host address
rabbit_ip=$(openstack endpoint show nova | awk "/ internalurl / { print \$4 }" | awk -F'[/]' '{print $3}' | awk -F'[:]' '{print $1}')
sed -i -- "s~#transport_url = <None>~transport_url = rabbit://guest:guest@$rabbit_ip:5672~" etc/congress.conf.sample

echo "$0: $(date) copy congress.conf.sample to /etc/congress"
cp etc/congress.conf.sample /etc/congress/congress.conf

echo "$0: $(date) create congress database"
mysql --password=$MYSQL_PASSWORD -e "CREATE DATABASE congress; CREATE USER 'congress'; GRANT ALL PRIVILEGES ON congress.* TO 'congress';"

echo "$0: $(date) install congress-db-manage dependencies (detected by errors)"
apt-get build-dep python-mysqldb -y
pip install MySQL-python PyMySQL

echo "$0: $(date) create database schema"
congress-db-manage --config-file /etc/congress/congress.conf upgrade head

echo "$0: $(date) Install congress client"
cd /opt/congress
git clone https://github.com/openstack/python-congressclient.git
cd python-congressclient
if [ $# -eq 1 ]; then git checkout $branch; fi
pip install .

# Fix error found during startup of congress server
echo "$0: $(date) Install python fixtures"
pip install fixtures

echo "$0: $(date) Install OpenStack client"
cd /opt/congress
git clone https://github.com/openstack/python-openstackclient.git
cd python-openstackclient
if [ $# -eq 1 ]; then git checkout $branch; fi
# TODO: fix this workaround - setuptools fails
# "Command "python setup.py egg_info" failed with error code 1 in /tmp/pip-build-JWTiHZ/pyparsing/"
# run it twice, turn off fail trap
pip install .

# TODO: The rest of this script is not yet tested
function _congress_setup_horizon {
  local HORIZON_DIR="/usr/share/openstack-dashboard"
  local CONGRESS_HORIZON_DIR="/home/heat-admin/git/congress/contrib/horizon"
  cp -r $CONGRESS_HORIZON_DIR/datasources $HORIZON_DIR/openstack_dashboard/dashboards/admin/
  cp -r $CONGRESS_HORIZON_DIR/policies $HORIZON_DIR/openstack_dashboard/dashboards/admin/
  cp -r $CONGRESS_HORIZON_DIR/static $HORIZON_DIR/openstack_dashboard/dashboards/admin/
  cp -r $CONGRESS_HORIZON_DIR/templates $HORIZON_DIR/openstack_dashboard/dashboards/admin/
  cp $CONGRESS_HORIZON_DIR/congress.py $HORIZON_DIR/openstack_dashboard/api/
  cp $CONGRESS_HORIZON_DIR/_50_policy.py $HORIZON_DIR/openstack_dashboard/local/enabled/
  cp $CONGRESS_HORIZON_DIR/_60_policies.py $HORIZON_DIR/openstack_dashboard/local/enabled/
  cp $CONGRESS_HORIZON_DIR/_70_datasources.py $HORIZON_DIR/openstack_dashboard/local/enabled/

  # For unit tests
  sh -c 'echo "$0: $(date) python-congressclient" >> '$HORIZON_DIR'/requirements.txt'
  sh -c 'echo -e \
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
  service apache2 restart
}
# Commented out as the procedure is not yet working
#echo "$0: $(date) Install Horizon Policy plugin"
#_congress_setup_horizon

pass
set +x #echo off
pass
