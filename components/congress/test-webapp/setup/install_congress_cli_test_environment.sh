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
# Status: this is a work in progress, under test.
#
# Prequisite: OPFNV installed per JOID or Apex installer
# On jumphost:
# - Congress installed through install_congress_1.sh
# - admin-openrc.sh downloaded from Horizon
# - env.sh and admin-openrc.sh in the current folder
# How to use:
#   Retrieve the copper install script as below, optionally specifying the 
#   branch to use as a URL parameter, e.g. ?h=stable%2Fbrahmaputra
# $ wget https://git.opnfv.org/cgit/copper/plain/components/congress/test-webapp/setup/install_congress_cli_test_environment.sh
# $ bash install_congress_cli_test_environment.sh

set -x

if [ $# -eq 1 ]; then cubranch=$1; fi

echo "Copy environment files to /tmp/copper"
if [ ! -d /tmp/copper ]; then mkdir /tmp/copper; fi
dist=`grep DISTRIB_ID /etc/*-release | awk -F '=' '{print $2}'`
if [ "$dist" == "Ubuntu" ]; then
  cp ~/congress/env.sh /tmp/copper/
  cp ~/admin-openrc.sh /tmp/copper/
  echo "Install jumphost dependencies"
  echo "Update package repos"
  sudo apt-get update
  echo "install pip"
  sudo apt-get install python-pip -y
  echo "install other dependencies"
  sudo apt-get install apg git gcc python-dev libxml2 libxslt1-dev libzip-dev -y
  sudo pip install --upgrade pip virtualenv setuptools pbr tox
else
  echo "Copy copper environment files" 
  sudo scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no stack@192.0.2.1:/home/stack/congress/*.sh /tmp/copper
  echo "Install jumphost dependencies"
  echo "install pip"
  sudo yum install python-pip -y
  echo "install other dependencies"
  sudo yum install apg git gcc libxml2 python-devel libzip-devel libxslt-devel -y
  sudo pip install --upgrade pip virtualenv setuptools pbr tox
fi

echo "Clone copper"
if [ ! -d /tmp/copper/copper ]; then 
  cd /tmp/copper
  git clone https://gerrit.opnfv.org/gerrit/copper
  cd copper
else
  echo "/tmp/copper exists: run 'rm -rf /tmp/copper' to start clean if needed"
fi

echo "Create virtualenv"
mkdir ~/congress
virtualenv ~/congress/venv
cd ~/congress/venv
source bin/activate

echo "Install OpenStack client"
cd ~/congress
git clone https://github.com/openstack/python-openstackclient.git
cd python-openstackclient
pip install -r requirements.txt
pip install .

echo "Install Congress client"
cd ~/congress
git clone https://github.com/openstack/python-congressclient.git
cd python-congressclient
pip install -r requirements.txt
pip install .

echo "Install Keystone client"
cd ~/congress
git clone https://github.com/openstack/python-keystoneclient.git
cd python-keystoneclient
pip install -r requirements.txt
pip install .

echo "Install Glance client"
cd ~/congress
git clone https://github.com/openstack/python-glanceclient.git
cd python-glanceclient
pip install -r requirements.txt
pip install .

echo "Install Neutron client"
cd ~/congress
git clone https://github.com/openstack/python-neutronclient.git
cd python-neutronclient
pip install -r requirements.txt
pip install .

echo "Install Nova client"
cd ~/congress
git clone https://github.com/openstack/python-novaclient.git
cd python-novaclient
pip install -r requirements.txt
pip install .

cd /tmp/copper/copper/tests
ls

echo "You can run tests individually, or as a collection with run.sh"

set +x

