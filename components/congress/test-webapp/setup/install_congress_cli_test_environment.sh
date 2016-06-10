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
# What this is: Installer for an OpenStack API test environment for Congress.
# Generally, this script is only needed if you want to setup an environment
# not already provided by the OPNFV installer. In most cases it's expected
# that adhoc tests will be run on the Jumphost with the needed OpenStack
# CLI clients etc already installed, and the OpenStack CLI credentials 
# needed by the test commands already EXPORTed to the shell environment.
# To avoid potential conflicts with the test user account setup (e.g. 
# installed python packages), this script sets up and activates a virtualenv,
# then installs the needed OpenStack CLI clients under it.
#
# Status: this is a work in progress, under test.
#
# Prequisite: OPFNV installed per JOID or Apex installer
# On jumphost:
# - Congress installed through JOID or Apex, or install_congress_1.sh
# - For Apex installs, on the jumphost, ssh to the undercloud VM and
#     $ su stack
# How to use:
#   Retrieve the copper install script as below, optionally specifying the 
#   branch to use as a URL parameter, e.g. ?h=stable%2Fbrahmaputra
# $ wget https://git.opnfv.org/cgit/copper/plain/components/congress/test-webapp/setup/install_congress_cli_test_environment.sh
# $ bash install_congress_cli_test_environment.sh

set -x

if [ $# -eq 1 ]; then osbranch=$1; fi

if [ -d ~/congress ]; then rm -rf ~/congress; fi
mkdir ~/congress

echo "OS-specific prerequisite steps"
dist=`grep DISTRIB_ID /etc/*-release | awk -F '=' '{print $2}'`

if [ "$dist" == "Ubuntu" ]; then
  echo "Ubuntu-based install"
  echo "Install jumphost dependencies"
  echo "Update package repos"
  sudo apt-get update
  echo "install pip"
  sudo apt-get install python-pip -y
  echo "install other dependencies"
  sudo apt-get install apg git gcc python-dev libxml2 libxslt1-dev libzip-dev -y
  sudo pip install --upgrade pip virtualenv setuptools pbr tox
  echo "Get the congress server address"
  CONGRESS_HOST=""
  while [ "$CONGRESS_HOST" == "" ]; do 
    sleep 5
    CONGRESS_HOST=$(juju status ssh ubuntu@node1-control.maas "sudo lxc-info --name juju-trusty-congress | grep IP" | awk "/ / { print \$2 }" | tr -d '\r')
  done
  KEYSTONE_HOST=$(juju status --format=short | awk "/keystone\/0/ { print \$3 }")
  cat <<EOF >~/congress/env.sh
export CONGRESS_HOST=$CONGRESS_HOST
export HORIZON_HOST=$(juju status --format=short | awk "/openstack-dashboard/ { print \$3 }")
export KEYSTONE_HOST=$KEYSTONE_HOST
export CEILOMETER_HOST=$(juju status --format=short | awk "/ceilometer\/0/ { print \$3 }")
export CINDER_HOST=$(juju status --format=short | awk "/cinder\/0/ { print \$3 }")
export GLANCE_HOST=$(juju status --format=short | awk "/glance\/0/ { print \$3 }")
export NEUTRON_HOST=$(juju status --format=short | awk "/neutron-api\/0/ { print \$3 }")
export NOVA_HOST=$(juju status --format=short | awk "/nova-cloud-controller\/0/ { print \$3 }")
export OS_USERNAME=admin
export OS_PASSWORD=openstack
export OS_TENANT_NAME=admin
export OS_AUTH_URL=http://$KEYSTONE_HOST:5000/v2.0
export OS_REGION_NAME=Canonical
EOF
else
  echo "Centos-based install"
  echo "Setup undercloud environment so we can get overcloud Controller server address"
  source ~/stackrc
  echo "Get address of Controller node"
  export CONTROLLER_HOST1=$(openstack server list | awk "/overcloud-controller-0/ { print \$8 }" | sed 's/ctlplane=//g')
  echo "Create the environment file and copy to the congress server"
  cat <<EOF >~/congress/env.sh
export CONGRESS_HOST=$CONTROLLER_HOST1
export KEYSTONE_HOST=$CONTROLLER_HOST1
export CEILOMETER_HOST=$CONTROLLER_HOST1
export CINDER_HOST=$CONTROLLER_HOST1
export GLANCE_HOST=$CONTROLLER_HOST1
export NEUTRON_HOST=$CONTROLLER_HOST1
export NOVA_HOST=$CONTROLLER_HOST1
EOF
  echo "Install jumphost dependencies"
  echo "install pip"
  sudo yum install python-pip -y
  echo "install other dependencies"
  sudo yum install apg git gcc libxml2 python-devel libzip-devel libxslt-devel -y
  sudo pip install --upgrade pip virtualenv setuptools pbr tox
fi

bash ~/congress/env.sh

echo "Clone copper"
cd ~/congress
git clone https://gerrit.opnfv.org/gerrit/copper

echo "Create virtualenv"
virtualenv ~/congress/venv
cd ~/congress/venv
source bin/activate

install_client () {
  cd ~/congress
  git clone https://github.com/openstack/$1
  cd $1
  if [ $# -eq 2 ]; then git checkout $2; fi
  pip install -r requirements.txt
  pip install .
}

echo "Install OpenStack clients"
install_client python-openstackclient.git $1
install_client python-congressclient.git $1
install_client python-keystoneclient.git $1
install_client python-glanceclient.git $1
install_client python-neutronclient.git $1
install_client python-novaclient.git

cd ~/congress/copper/tests
ls

echo "You can run tests individually, or as a collection with run.sh"

set +x

