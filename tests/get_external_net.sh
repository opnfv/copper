#!/bin/bash
# Copyright 2017 AT&T Intellectual Property, Inc
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

# What this is: An OpenStack client script to find the name of the external 
# network, or create one if not found.
#
# Status: this is a work in progress, under test.
#
# Prequisite: 
# - OpenStack CLI environment variables setup
# How to use:
#   source get_external_net
#   (sets two shell variables: EXTERNAL_NETWORK_NAME and EXTERNAL_SUBNET_ID)

 network_ids=($(neutron net-list|grep -v "+"|grep -v name|awk '{print $2}'))
 for id in ${network_ids[@]}; do
     [[ $(neutron net-show ${id}|grep 'router:external'|grep -i "true") != "" ]] && ext_net_id=${id}
 done
 if [[ $ext_net_id ]]; then 
# Workaround for bug https://bugs.launchpad.net/manila/+bug/1652317 which
# blocks use of openstack network show
#   EXTERNAL_NETWORK_NAME=$(openstack network show $ext_net_id | awk "/ name / { print \$4 }")
#   EXTERNAL_SUBNET_ID=$(openstack network show $EXTERNAL_NETWORK_NAME | awk "/ subnets / { print \$4 }")
   EXTERNAL_NETWORK_NAME=$(neutron net-show $ext_net_id | awk "/ name / { print \$4 }")
   EXTERNAL_SUBNET_ID=$(neutron net-show $EXTERNAL_NETWORK_NAME | awk "/ subnets / { print \$4 }")
 else
   echo "External network not found"
   echo "Create external network"
   neutron net-create public --router:external
   EXTERNAL_NETWORK_NAME="public"
   echo "Create external subnet"
   neutron subnet-create public 192.168.10.0/24 --name public --enable_dhcp=False --allocation_pool start=192.168.10.6,end=192.168.10.49 --gateway 192.168.10.1
   EXTERNAL_SUBNET_ID=$(openstack subnet show public | awk "/ id / { print \$4 }")
 fi

