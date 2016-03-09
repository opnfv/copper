#!/bin/bash
# Copyright 2015-2016 Open Platform for NFV Project, Inc. and its contributors
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
# source ~/git/copper/components/congress/joid/install_congress_1.sh <controller_hostname>
# <controller_hostname> is the name of the controller node in MAAS.

set -x

# Create the congress container
juju ssh ubuntu@node1-control "sudo lxc-clone -o juju-trusty-lxc-template -n juju-trusty-congress; sudo lxc-start -n juju-trusty-congress -d; exit"

# Get the congress server address
CONGRESS_HOST=""
while [ "$CONGRESS_HOST" == "" ]; do 
  sleep 5
  CONGRESS_HOST=$(juju ssh ubuntu@$1 "sudo lxc-info --name juju-trusty-congress | grep IP" | awk "/ / { print \$2 }" | tr -d '\r')
done

# Create the environment file and copy to the congress server
cat <<EOF >~/env.sh
export CONGRESS_HOST=$CONGRESS_HOST
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

# Copy the install script to the congress server and execute
juju scp ~/git/copper/components/congress/joid/install_congress_2.sh ubuntu@$CONGRESS_HOST:/home/ubuntu
ssh -x -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ubuntu@$CONGRESS_HOST "source ~/install_congress_2.sh; exit"

set +x
