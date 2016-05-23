#!/bin/bash
# CCopyright 2015-2016 AT&T Intellectual Property, Inc
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
# This is a cleanup script for installation of Congress on the OPNFV Controller
# node as installed via JOID or Apex (Fuel and Compass not yet verified).
# Presumably something has failed, and any record of the Congress feature
# in OpenStack needs to be removed, so you can try the install again.
# Prerequisites: 
# - OPFNV installed via JOID or Apex
# - For Apex installs, on the jumphost, ssh to the undercloud VM and
#     $ su stack
# - For JOID installs, admin-openrc.sh saved from Horizon to ~/admin-openrc.sh
# - Retrieve the copper remova script as below
# $ cd ~
# $ wget https://git.opnfv.org/cgit/copper/plain/components/congress/install/bash/clean_congress.sh
# $ bash clean_congress.sh

echo "OS-specific prerequisite steps"
dist=`grep DISTRIB_ID /etc/*-release | awk -F '=' '{print $2}'`

source ~/congress/env.sh

if [ "$dist" == "Ubuntu" ]; then
  # Ubuntu
  echo "Ubuntu-based install"
  export CTLUSER="ubuntu"
  echo "Stop the Congress service"
  # Have to use "python" here as congress-server does not show up in the process list (?)
  ssh -x -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $CTLUSER@$CONGRESS_HOST "pkill python; exit"
  source ~/admin-openrc.sh <<EOF
openstack
EOF
else 
  export CTLUSER="heat-admin"
  echo "Stop the Congress service"
  ssh -x -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $CTLUSER@$CONGRESS_HOST "pkill congress-server; exit"
  source ~/admin-openrc.sh 
fi

cd ~

echo "Remove the Congress virtualenv and code"
ssh -x -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $CTLUSER@$CONGRESS_HOST "rm -rf ~/congress; exit"

echo "Delete Congress user"
export CONGRESS_USER=$(openstack user list | awk "/ congress / { print \$2 }")
if [ "$CONGRESS_USER" != "" ]; then
  openstack user delete $CONGRESS_USER
fi

echo "Delete Congress service"
export CONGRESS_SERVICE=$(openstack service list | awk "/ congress / { print \$2 }")
if [ "$CONGRESS_SERVICE" != "" ]; then
  openstack service delete $CONGRESS_SERVICE
fi

echo "Delete Congress database"
ssh -x -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $CTLUSER@$CONGRESS_HOST "sudo mysql -e \"DROP DATABASE congress\"; exit"

echo "Deactivate virtualenv"
deactivate

echo "Delete Congress and other installed code in virtualenv"
rm -rf ~/congress

