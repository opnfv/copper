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
# What this is: script 1 of 2 for installation of a test server for Congress.
# Status: this is a work in progress, under test.
#
# Prequisite: OPFNV install per https://wiki.opnfv.org/copper/academy/joid
# On jumphost:
# - Congress installed through install_congress_1/2/3/4.sh
# - ~/env.sh created as part of Congress install (install_congress_3.sh)
# How to use:
#   Install OPNFV per https://wiki.opnfv.org/copper/academy/joid
#   $ source install_congress_testserver_1.sh <opnfv password>

# Following are notes on creating a container as test driver for Congress. 
# This is based upon an Ubuntu host as installed by JOID.

# === Create and Activate the Container ===

# <code>
# On the jumphost
# Earlier versions of the JOID installer installed lxc and created local templates
# but now we have to get the ubuntu template from the controller
set -x 
sudo apt-get install -y lxc
juju scp ubuntu@node1-control:/usr/share/lxc/templates/lxc-ubuntu ~/lxc-ubuntu
sudo cp ~/lxc-ubuntu /usr/share/lxc/templates/lxc-ubuntu
sudo lxc-create -n trusty-copper -t /usr/share/lxc/templates/lxc-ubuntu -l DEBUG -- -b opnfv ~/opnfv
sudo lxc-start -n trusty-copper -d
sudo lxc-info --name trusty-copper
if (($? > 0)); then
  return
fi
export COPPER_HOST=""
while [ "$COPPER_HOST" == "" ]; do 
  sleep 5
  export COPPER_HOST=$(sudo lxc-info --name trusty-copper | grep IP | awk "/ / { print \$2 }")
done
echo COPPER_HOST = $COPPER_HOST
echo export COPPER_HOST=$COPPER_HOST >>~/env.sh
ssh -t -x -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no opnfv@$COPPER_HOST "source ~/git/copper/components/congress/test-webapp/setup/install_congress_testserver_2.sh; exit" <<EOF
$1
EOF
set +x
# </code>
