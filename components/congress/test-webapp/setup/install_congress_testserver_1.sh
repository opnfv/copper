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
# What this is: script 1 of 2 for installation of a test server for Congress.
# Status: this is a work in progress, under test.
#
# Prequisite: OPFNV install per https://wiki.opnfv.org/copper/academy/joid
# On jumphost:
# - Congress installed through install_congress_1.sh
# - ~/env.sh created as part of Congress install (install_congress_1.sh)
# How to use:
#   $ source install_congress_testserver_1.sh  <controller_hostname> <user>
# <controller_hostname> is the name of the controller node in MAAS
# and <user> is the name of the account where you are installing this

# Create and Activate the Container
# Earlier versions of the JOID installer installed lxc and created local templates
# but now we have to get the ubuntu template from the controller
set -x 

sudo apt-get install -y lxc
juju scp ubuntu@$1:/usr/share/lxc/templates/lxc-ubuntu ~/lxc-ubuntu
sudo cp ~/lxc-ubuntu /usr/share/lxc/templates/lxc-ubuntu
sudo lxc-create -n trusty-copper -t /usr/share/lxc/templates/lxc-ubuntu -l DEBUG -- -b $2 ~/$2
sudo lxc-start -n trusty-copper -d
if (($? > 0)); then
  echo Error starting trusty-copper lxc container
  return
fi

# Get the CONGRESS_HOST value from env.sh
source ~/env.sh

# Get the copper server address
sleep 5
export COPPER_HOST=""
while [ "$COPPER_HOST" == "" ]; do 
  sleep 5
  export COPPER_HOST=$(sudo lxc-info --name trusty-copper | grep IP | awk "/ / { print \$2 }")
done
echo COPPER_HOST = $COPPER_HOST

# Create the environment file 
cat <<EOF >~/env.sh
export COPPER_HOST=$COPPER_HOST
export CONGRESS_HOST=$CONGRESS_HOST
export KEYSTONE_HOST=$(juju status --format=short | awk "/keystone\/0/ { print \$3 }")
export CEILOMETER_HOST=$(juju status --format=short | awk "/ceilometer\/0/ { print \$3 }")
export CINDER_HOST=$(juju status --format=short | awk "/cinder\/0/ { print \$3 }")
export GLANCE_HOST=$(juju status --format=short | awk "/glance\/0/ { print \$3 }")
export NEUTRON_HOST=$(juju status --format=short | awk "/neutron-api\/0/ { print \$3 }")
export NOVA_HOST=$(juju status --format=short | awk "/nova-cloud-controller\/0/ { print \$3 }")
EOF

# Invoke install_congress_testserver_2.sh
ssh -t -x -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $2@$COPPER_HOST "source ~/git/copper/components/congress/test-webapp/setup/install_congress_testserver_2.sh; exit"

set +x
