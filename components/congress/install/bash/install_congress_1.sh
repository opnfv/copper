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
# This is script 1 of 2 for installation of Congress on the OPNFV Controller
# node as installed via JOID or Apex (Fuel and Compass not yet verified).
# Prerequisites: 
# - OPFNV installed via JOID or Apex
# - For Apex installs, on the jumphost, ssh to the undercloud VM and
#     $ su stack
# - For JOID installs, admin-openrc.sh saved from Horizon to ~/admin-openrc.sh
# - Retrieve the copper install script as below, optionally specifying the 
#   branch to use as a URL parameter, e.g. ?h=stable%2Fbrahmaputra
# $ cd ~
# $ wget https://git.opnfv.org/cgit/copper/plain/components/congress/install/bash/install_congress_1.sh
# $ wget https://git.opnfv.org/cgit/copper/plain/components/congress/install/bash/install_congress_2.sh
# $ bash install_congress_1.sh [openstack-branch]
#   optionally specifying the branch identifier to use for OpenStack
#     

set -x

sudo -i

if [ $# -eq 1 ]; then osbranch=$1; fi

if [ -d ~/congress ]; then rm -rf ~/congress; fi
mkdir ~/congress

echo "OS-specific prerequisite steps"
dist=`grep DISTRIB_ID /etc/*-release | awk -F '=' '{print $2}'`

if [ "$dist" == "Ubuntu" ]; then
  # Ubuntu
  echo "Ubuntu-based install"
  echo "Create the environment file and copy to the congress server"
  cat <<EOF >~/congress/env.sh
export CONGRESS_HOST=$(juju status --format=short | awk "/openstack-dashboard/ { print \$3 }")
export HORIZON_HOST=$(juju status --format=short | awk "/openstack-dashboard/ { print \$3 }")
export KEYSTONE_HOST=$(juju status --format=short | awk "/keystone\/0/ { print \$3 }")
export CEILOMETER_HOST=$(juju status --format=short | awk "/ceilometer\/0/ { print \$3 }")
export CINDER_HOST=$(juju status --format=short | awk "/cinder\/0/ { print \$3 }")
export GLANCE_HOST=$(juju status --format=short | awk "/glance\/0/ { print \$3 }")
export NEUTRON_HOST=$(juju status --format=short | awk "/neutron-api\/0/ { print \$3 }")
export NOVA_HOST=$(juju status --format=short | awk "/nova-cloud-controller\/0/ { print \$3 }")
EOF
  source ~/congress/env.sh
  export CTLUSER="ubuntu"
  ssh -x -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $CTLUSER@$CONGRESS_HOST "mkdir ~/congress; exit"
  juju scp ~/admin-openrc.sh ubuntu@$CONGRESS_HOST:/home/$CTLUSER/congress
  juju scp ~/congress/env.sh ubuntu@$CONGRESS_HOST:/home/$CTLUSER/congress
  echo "Copy install_congress_2.sh to the congress server and execute"
  juju scp ~/install_congress_2.sh $CTLUSER@$CONGRESS_HOST:/home/ubuntu/congress
  ssh -x -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $CTLUSER@$CONGRESS_HOST "source ~/congress/install_congress_2.sh; exit"
  echo "Install jumphost dependencies"
  echo "Update package repos"
  sudo apt-get update
  echo "install pip"
  apt-get install python-pip -y
  echo "install other dependencies"
  apt-get install apg git gcc python-dev libxml2 libxslt1-dev libzip-dev -y
  pip install --upgrade pip virtualenv setuptools pbr tox
  sed -i -- 's/echo/#echo/g' ~/admin-openrc.sh  
  sed -i -- 's/read -sr OS_PASSWORD_INPUT/#read -sr OS_PASSWORD_INPUT/g' ~/admin-openrc.sh
  sed -i -- 's/$OS_PASSWORD_INPUT/openstack/g' ~/admin-openrc.sh
  cp ~/admin-openrc.sh ~/congress
else
  # Centos
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
  source ~/congress/env.sh
  CTLUSER="heat-admin"
  ssh -x -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $CTLUSER@$CONTROLLER_HOST1 "mkdir ~/congress; exit"
  scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ~/congress/env.sh $CTLUSER@$CONTROLLER_HOST1:/home/$CTLUSER/congress
  echo "Setup env for overcloud API access and copy to congress server"
  source ~/overcloudrc
  export OS_REGION_NAME=$(openstack endpoint list | awk "/ nova / { print \$4 }")
  cp ~/overcloudrc ~/congress/admin-openrc.sh
  # sed command below is a workaound for a bug - region shows up twice for some reason
  cat <<EOF | sed '$d' >>~/admin-openrc.sh
export OS_REGION_NAME=$OS_REGION_NAME
EOF
  scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ~/admin-openrc.sh $CTLUSER@$CONTROLLER_HOST1:/home/$CTLUSER/congress
  echo "Copy install_congress_2.sh to the congress server and execute"
  scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ~/install_congress_2.sh $CTLUSER@$CONTROLLER_HOST1:/home/$CTLUSER/congress
  ssh -x -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $CTLUSER@$CONTROLLER_HOST1 "source ~/congress/install_congress_2.sh; exit"
  echo "Install jumphost dependencies"
  echo "install pip"
  yum install python-pip -y
  echo "install other dependencies"
  yum install apg git gcc libxml2 python-devel libzip-devel libxslt-devel -y
  pip install --upgrade pip virtualenv setuptools pbr tox
  source ~/admin-openrc.sh
fi

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

echo "Install Congress client"
cd ~/congress
git clone https://github.com/openstack/python-congressclient.git
cd python-congressclient
if [ $# -eq 1 ]; then git checkout $1; fi
pip install -r requirements.txt
pip install .

echo "Install Keystone client"
cd ~/congress
git clone https://github.com/openstack/python-keystoneclient.git
cd python-keystoneclient
if [ $# -eq 1 ]; then git checkout $1; fi
pip install -r requirements.txt
pip install .

echo "Install Glance client"
cd ~/congress
git clone https://github.com/openstack/python-glanceclient.git
cd python-glanceclient
if [ $# -eq 2 ]; then git checkout $2; fi
pip install -r requirements.txt
pip install .

echo "Install Neutron client"
cd ~/congress
git clone https://github.com/openstack/python-neutronclient.git
cd python-neutronclient
if [ $# -eq 2 ]; then git checkout $2; fi
pip install -r requirements.txt
pip install .

echo "Install Nova client"
cd ~/congress
git clone https://github.com/openstack/python-novaclient.git
cd python-novaclient
if [ $# -eq 2 ]; then git checkout $2; fi
pip install -r requirements.txt
pip install .

echo "setup Congress user. TODO: needs update in http://congress.readthedocs.org/en/latest/readme.html#installing-congress"
pip install cliff --upgrade
export ADMIN_ROLE=$(openstack role list | awk "/ admin / { print \$2 }")
export SERVICE_TENANT=$(openstack project list | awk "/ admin / { print \$2 }")
openstack user create --password congress --project admin --email "congress@example.com" congress
export CONGRESS_USER=$(openstack user list | awk "/ congress / { print \$2 }")
openstack role add --user $CONGRESS_USER --project $SERVICE_TENANT $ADMIN_ROLE 

echo "Create Congress service"
openstack service create congress --type "policy" --description "Congress Service"
export CONGRESS_SERVICE=$(openstack service list | awk "/ congress / { print \$2 }")

echo "Create Congress endpoint"
openstack endpoint create $CONGRESS_SERVICE \
  --region $OS_REGION_NAME \
  --publicurl http://$CONGRESS_HOST:1789/ \
  --adminurl http://$CONGRESS_HOST:1789/ \
  --internalurl http://$CONGRESS_HOST:1789/

echo "Start the Congress service"
ssh -x -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $CTLUSER@$CONGRESS_HOST "source ~/congress/venv/bin/activate; ~/congress/congress/bin/congress-server &>/dev/null &"

echo "Wait 30 seconds for Congress service to startup"
sleep 30

echo "Create data sources"
# To remove datasources: openstack congress datasource delete <name> 
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

echo "Install tox test dependencies"
if [ "$dist" == "Ubuntu" ]; then
  apt-get install -y libffi-dev libssl-dev
else
  yum install -y libffi-devel openssl-devel
fi

echo "Run Congress tox Tests"
cd ~/congress/congress
tox -epy27

set +x #echo off
