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
# This is script 1 of 2 for installation of Congress on the Centos 7 based
# OPNFV Controller node as installed per the OPNFV Apex project.
# Prequisites: 
#   OPFNV install per https://wiki.opnfv.org/display/copper/Apex
#   On the jumphost, logged in as stack on the undercloud VM:
#     su stack
#   Clone the Copper repo and run the install script:
#     git clone https://gerrit.opnfv.org/gerrit/copper
#     source  copper/components/install/bash/centos/install_congress_1.sh

if [ $# -gt 1 ] && [ $2 == "debug" ]; then set -x #echo on
fi

cd ~
source ~/stackrc

# Get addresses of Controller node(s)
export CONTROLLER_HOST1=$(openstack server list | awk "/overcloud-controller-0/ { print \$8 }" | sed 's/ctlplane=//g')
export CONTROLLER_HOST2=$(openstack server list | awk "/overcloud-controller-1/ { print \$8 }" | sed 's/ctlplane=//g')

# puppet apply -e "user { 'congress': ensure => present, password => sha1('congress'), }"
# ssh -x -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ssh heat-admin@$CONTROLLER_HOST1 "useradd congress; exit"

echo "Create the environment file and copy to the congress server"
cat <<EOF >~/env.sh
export CONGRESS_HOST=$CONTROLLER_HOST1
export KEYSTONE_HOST=$CONTROLLER_HOST1
export CEILOMETER_HOST=$CONTROLLER_HOST1
export CINDER_HOST=$CONTROLLER_HOST1
export GLANCE_HOST=$CONTROLLER_HOST1
export NEUTRON_HOST=$CONTROLLER_HOST1
export NOVA_HOST=$CONTROLLER_HOST1
EOF
source ~/env.sh
scp ~/stackrc heat-admin@$CONTROLLER_HOST1:/home/heat-admin/admin-openrc.sh
scp ~/env.sh heat-admin@$CONTROLLER_HOST1:/home/heat-admin

echo "Copy install_congress_2.sh to the congress server and execute"
scp ~/git/copper/components/congress/joid/install_congress_2.sh heat-admin@$CONTROLLER_HOST1:/home/heat-admin
ssh -x -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no heat-admin@$CONTROLLER_HOST1 "source ~/install_congress_2.sh; exit"

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
tox -epy27

set +x #echo off
