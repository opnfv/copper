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
# This is a cleanup script for installation of Congress on the Centos 7 based
# OPNFV Controller node as installed per the OPNFV Apex project.
# Prequisites: 
# Presumably something has failed, and any record of the Congress feature
# in OpenStack needs to be removed, so you can try the install again.
#
# Prequisite: 
#  OPFNV install per https://wiki.opnfv.org/display/copper/Apex
# How to use:
#  cd ~/congress/copper/ (or wherever you cloned the copper repo)
#  source /components/congress/install/bash/centos/clean_congress.sh

cd ~
# Setup undercloud environment so we can get overcloud Controller server address
source ~/stackrc

# Get addresses of Controller node(s)
export CONTROLLER_HOST1=$(openstack server list | awk "/overcloud-controller-0/ { print \$8 }" | sed 's/ctlplane=//g')
export CONTROLLER_HOST2=$(openstack server list | awk "/overcloud-controller-1/ { print \$8 }" | sed 's/ctlplane=//g')

echo "Stop the Congress service"
ssh -x -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no heat-admin@$CONGRESS_HOST "pkill congress-server; exit"

echo "Remove the Congress virtualenv and code"
ssh -x -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no heat-admin@$CONGRESS_HOST "rm -rf ~/congress/congress; rm ~/admin-openrc.sh; rm ~/admin-openrc.sh; exit"

# Setup env for overcloud API access
source ~/overcloudrc

# Delete Congress user
export CONGRESS_USER=$(openstack user list | awk "/ congress / { print \$2 }")
if [ "$CONGRESS_USER" != "" ]; then
  openstack user delete $CONGRESS_USER
fi

# Delete Congress service
export CONGRESS_SERVICE=$(openstack service list | awk "/ congress / { print \$2 }")
if [ "$CONGRESS_SERVICE" != "" ]; then
  openstack service delete $CONGRESS_SERVICE
fi

# Delete Congress and other installed code in virtualenv
rm -rf ~/congress

