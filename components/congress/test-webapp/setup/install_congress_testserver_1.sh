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
# Prequisite: OPFNV installed per JOID or Apex installer
# On jumphost:
# - Congress installed through install_congress_1.sh
# - ~/env.sh created as part of Congress install (install_congress_1.sh)
# How to use:
#   $ source install_congress_testserver_1.sh  [<controller_hostname>]
# If provided, <controller_hostname> is the name of the controller node in MAAS
# (the parameter is not used for Apex-based installs)

set -x

echo "Install prerequisites"
dist=`grep DISTRIB_ID /etc/*-release | awk -F '=' '{print $2}'`

if [ "$dist" == "Ubuntu" ]; then
  # Create and Activate the Container
  # Earlier versions of the JOID installer installed lxc and created local templates
  # but now we have to get the ubuntu template from the controller

  if [ $# -lt 1 ]; then
    echo 1>&2 "$0: arguments required <controller_hostname>"
    set +x
    return 2
  fi

  sudo apt-get install -y lxc
  echo "Copy lxc-ubuntu container from the controller"
  juju scp ubuntu@$1:/usr/share/lxc/templates/lxc-ubuntu ~/lxc-ubuntu
  sudo cp ~/lxc-ubuntu /usr/share/lxc/templates/lxc-ubuntu
  echo "Create the copper container"
  sudo lxc-create -n copper -t /usr/share/lxc/templates/lxc-ubuntu -l DEBUG -- -b $USER ~/$USER
else
  sudo yum install -y epel-release
  sudo yum install -y debootstrap perl
  sudo yum install -y lxc lxc-templates
  sudo systemctl start lxc.service
  echo "Create the copper container"
  brctl addbr virbr0
  # TODO: this is not yet working - need additional config
  sudo lxc-create -t download -n copper -- -d ubuntu -r trusty -a amd64 -- -b $USER ~/$USER
fi

echo "Start copper"
sudo lxc-start -n copper -d
if (($? > 0)); then
  echo Error starting copper lxc container
  return
fi

echo "Get the CONGRESS_HOST value from env.sh"
source ~/env.sh

echo "Get copper address"
sleep 5
export COPPER_HOST=""
while [ "$COPPER_HOST" == "" ]; do 
  sleep 5
  export COPPER_HOST=$(sudo lxc-info --name copper | grep IP | awk "/ / { print \$2 }")
done
echo COPPER_HOST = $COPPER_HOST

echo "Create the environment file"
cat <<EOF >~/env.sh
export COPPER_HOST=$COPPER_HOST
export CONGRESS_HOST=$CONGRESS_HOST
export KEYSTONE_HOST=$KEYSTONE_HOST
export CEILOMETER_HOST=$CEILOMETER_HOST
export CINDER_HOST=$CINDER_HOST
export GLANCE_HOST=$GLANCE_HOST
export NEUTRON_HOST=$NEUTRON_HOST
export NOVA_HOST=$NOVA_HOST
EOF

echo "Invoke install_congress_testserver_2.sh on copper"
ssh -t -x -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $USER@$COPPER_HOST "source ~/git/copper/components/congress/test-webapp/setup/install_congress_testserver_2.sh; exit"

set +x
