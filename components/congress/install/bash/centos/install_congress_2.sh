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
# This is script 2 of 2 for installation of Congress on the Centos 7 based
# OPNFV Controller node as installed per the OPNFV Apex project.
# Prequisites: 
#   OPFNV install per https://wiki.opnfv.org/display/copper/Apex
#   On the jumphost, logged in as stack on the undercloud VM:
#     su stack
#   Clone the Copper repo and run the install script:
#     git clone https://gerrit.opnfv.org/gerrit/copper
#     source  copper/components/install/bash/centos/install_congress_1.sh

set -x
source ~/admin-openrc.sh
source ~/env.sh

echo "install pip"
sudo yum install python-pip -y

echo "install java"
# sudo yum install default-jre -y
# No package default-jre available.

echo "install other dependencies"
sudo yum install apg git gcc libxml2 python-devel libzip-devel libxslt-devel -y
sudo pip install --upgrade pip virtualenv setuptools pbr tox

echo "Clone congress"
mkdir ~/git
cd ~/git
git clone https://github.com/openstack/congress.git
cd congress
git checkout stable/liberty

echo "Create virtualenv"
virtualenv ~/git/congress
source bin/activate

echo "Setup Congress"
sudo mkdir -p /etc/congress
sudo chown heat-admin /etc/congress
mkdir -p /etc/congress/snapshot
sudo mkdir /var/log/congress
sudo chown heat-admin /var/log/congress
cp etc/api-paste.ini /etc/congress
cp etc/policy.json /etc/congress

echo "install requirements.txt and tox dependencies (detected by errors during 'tox -egenconfig')"
sudo yum install libffi-devel openssl openssl-devel -y

echo "install dependencies of Congress"
cd ~/git/congress
bin/pip install -r requirements.txt
bin/pip install .

echo "install tox"
bin/pip install tox

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
bin/pip install MySQL-python

echo "create database schema"
congress-db-manage --config-file /etc/congress/congress.conf upgrade head

echo "Install Congress client"
cd ~/git
git clone https://github.com/openstack/python-congressclient.git
cd python-congressclient
git checkout stable/liberty
../congress/bin/pip install -r requirements.txt
../congress/bin/pip install .

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
