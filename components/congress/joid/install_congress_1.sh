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
# This is script 1 of 2 for installation of Congress on an Ubuntu 14.04 
# LXC container in the OPNFV Controller node.
# Prequisite: OPFNV install per https://wiki.opnfv.org/copper/academy/joid
#
# On jumphost:
# Download admin-openrc.sh from Horizon and save in ~
# source install_congress_1.sh <host>
# (copies install_congress_2.sh to <host> and executes it)
# <hostname> is the name of the host in which to install Congress.
# 
# If "horizon", Congress will be installed in the same LXC as Horizon,
# as necessary for the OpenStack Dashboard Policy plugins to work.
# Otherwise provide the node name of the controller node, where Congress
# will be installed in an LXC (NOTE: Policy plugin for OpenStack dashboard
# does not currently get installed for the LXC-based Congress deploy)

if [ $# -gt 1 ] && [ $2 == "debug" ]; then set -x #echo on
fi

source ~/admin-openrc.sh <<EOF
openstack
EOF

if [ $1 == "horizon" ]; then 
  echo "Set CONGRESS_HOST to HORIZON_HOST"
  CONGRESS_HOST=$(juju status --format=short | awk "/openstack-dashboard/ { print \$3 }")
else
  echo "Create the congress container"
  juju ssh ubuntu@$1 "sudo lxc-clone -o juju-trusty-lxc-template -n juju-trusty-congress; sudo lxc-start -n juju-trusty-congress -d; exit"

  echo "Get the congress server address"
  CONGRESS_HOST=""
  while [ "$CONGRESS_HOST" == "" ]; do 
    sleep 5
    CONGRESS_HOST=$(juju ssh ubuntu@$1 "sudo lxc-info --name juju-trusty-congress | grep IP" | awk "/ / { print \$2 }" | tr -d '\r')
  done
fi
  
echo "Create the environment file and copy to the congress server"
cat <<EOF >~/env.sh
export CONGRESS_HOST=$CONGRESS_HOST
export HORIZON_HOST=$(juju status --format=short | awk "/openstack-dashboard/ { print \$3 }")
export KEYSTONE_HOST=$(juju status --format=short | awk "/keystone\/0/ { print \$3 }")
export CEILOMETER_HOST=$(juju status --format=short | awk "/ceilometer\/0/ { print \$3 }")
export CINDER_HOST=$(juju status --format=short | awk "/cinder\/0/ { print \$3 }")
export GLANCE_HOST=$(juju status --format=short | awk "/glance\/0/ { print \$3 }")
export NEUTRON_HOST=$(juju status --format=short | awk "/neutron-api\/0/ { print \$3 }")
export NOVA_HOST=$(juju status --format=short | awk "/nova-cloud-controller\/0/ { print \$3 }")
EOF
source ~/env.sh
juju scp ~/admin-openrc.sh ubuntu@$CONGRESS_HOST:/home/ubuntu
juju scp ~/env.sh ubuntu@$CONGRESS_HOST:/home/ubuntu

echo "Copy install_congress_2.sh to the congress server and execute"
juju scp ~/git/copper/components/congress/joid/install_congress_2.sh ubuntu@$CONGRESS_HOST:/home/ubuntu
ssh -x -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ubuntu@$CONGRESS_HOST "source ~/install_congress_2.sh; exit"

echo "Install jumphost dependencies"

echo "Update package repos"
sudo apt-get update

echo "install pip"
sudo apt-get install python-pip -y

echo "install other dependencies"
sudo apt-get install apg git gcc python-dev libxml2 libxslt1-dev libzip-dev -y
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

echo "Install and test OpenStack client"
cd ~/git
git clone https://github.com/openstack/python-openstackclient.git
cd python-openstackclient
git checkout stable/liberty
~/git/congress/bin/pip install -r requirements.txt
~/git/congress/bin/pip install .
openstack service list

echo "Install and test Congress client"
cd ~/git
git clone https://github.com/openstack/python-congressclient.git
cd python-congressclient
git checkout stable/liberty
~/git/congress/bin/pip install -r requirements.txt
~/git/congress/bin/pip install .
openstack congress driver list

echo "Install and test Keystone client"
cd ~/git
git clone https://github.com/openstack/python-keystoneclient.git
cd python-keystoneclient
git checkout stable/liberty
~/git/congress/bin/pip install -r requirements.txt
~/git/congress/bin/pip install .

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
ssh -x -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ubuntu@$CONGRESS_HOST "~/git/congress/bin/congress-server &>/dev/null &"

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
sudo apt-get install -y libffi-dev libssl-dev

echo "Run Congress tox Tests"
cd ~/git/congress
bin/tox -epy27

set +x #echo off
