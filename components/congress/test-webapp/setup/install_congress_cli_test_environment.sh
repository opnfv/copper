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
# $ wget https://git.opnfv.org/cgit/copper/tree/components/congress/test-webapp/setup/install_congress_cli_test_environment.sh
# $ source install_congress_testserver.sh [copper-branch openstack-branch]
#   optionally specifying the branch identifier to use for copper and OpenStack

set -x

if [ $# -eq 1 ]; then
  echo 1>&2 "$0: specify both copper-branch and openstack-branch"
  set +x
  return 2
fi
if [ $# -eq 2 ]; then
  cubranch=$1
  osbranch=$2
fi

cubranch=$1
osbranch=$2

echo "Install prerequisites"
dist=`grep DISTRIB_ID /etc/*-release | awk -F '=' '{print $2}'`

if [ "$dist" == "Ubuntu" ]; then
  echo "Update the base server"
  set -x
  sudo apt-get update
  #apt-get -y upgrade
  echo "Install pip"
  sudo apt-get install -y python-pip
  echo "Install java"
  sudo apt-get install -y default-jre
  echo "Install other dependencies"
  apt-get install -y git gcc python-dev libxml2 libxslt1-dev libzip-dev php5-curl
else
  echo "Add epel repo"
  sudo yum install epel-release -y
  echo "install pip"
  sudo yum install python-pip -y
  echo "install other dependencies"
  sudo yum install apg git gcc libxml2 python-devel libzip-devel libxslt-devel -y
fi

echo "Install python dependencies"
sudo pip install --upgrade pip virtualenv setuptools pbr tox

echo "Create virtualenv"
mkdir /tmp/copper
cd /tmp/copper
virtualenv venv
source venv/bin/activate

echo "Clone copper"
git clone https://gerrit.opnfv.org/gerrit/copper
cd copper
if [ $# -eq 2 ]; then git checkout $1; fi

echo "Setup OpenStack environment variables per your OPNFV install"
source env.sh
source admin-openrc.sh

echo "Clone congress"
git clone https://github.com/openstack/congress.git
cd congress
if [ $# -eq 2 ]; then git checkout $2; fi

echo "Install OpenStack client"
cd /tmp/copper
git clone https://github.com/openstack/python-openstackclient.git
cd python-openstackclient
if [ $# -eq 2 ]; then git checkout $2; fi
pip install -r requirements.txt
pip install .

echo "Install Congress client"
cd /tmp/copper
git clone https://github.com/openstack/python-congressclient.git
cd python-congressclient
if [ $# -eq 2 ]; then git checkout $2; fi
pip install -r requirements.txt
pip install .

echo "Install Glance client"
cd /tmp/copper
git clone https://github.com/openstack/python-glanceclient.git
cd python-glanceclient
if [ $# -eq 2 ]; then git checkout $2; fi
pip install -r requirements.txt
pip install .

echo "Install Neutron client"
cd /tmp/copper
git clone https://github.com/openstack/python-neutronclient.git
cd python-neutronclient
if [ $# -eq 2 ]; then git checkout $2; fi
pip install -r requirements.txt
pip install .

echo "Install Nova client"
cd /tmp/copper
git clone https://github.com/openstack/python-novaclient.git
cd python-novaclient
if [ $# -eq 2 ]; then git checkout $2; fi
pip install -r requirements.txt
pip install .

echo "Install Keystone client"
cd /tmp/copper
git clone https://github.com/openstack/python-keystoneclient.git
cd python-keystoneclient
if [ $# -eq 2 ]; then git checkout $2; fi
pip install -r requirements.txt
pip install .

cd /tmp/copper/copper/tests
ls

echo "You can run tests individually, or as a collection with run.sh"

set +x

