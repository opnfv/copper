#!/bin/bash
# Copyright 2015-2017 AT&T Intellectual Property, Inc
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

# What this is: Cleanup script for the test dmz01.sh
#
# Status: this is a work in progress, under test. 
#
# Prerequisite: 
# - OpenStack deployment with Congress service activated.
# - OpenStack CLI environment variables setup e.g. via admin-openrc.sh script.
# How to use:
#   Install Congress test server per https://wiki.opnfv.org/copper/academy
#   # Create Congress policy and resources that exercise policy
#   $ bash dmz.sh
#   # After test, cleanup
#   $ bash dmz-clean.sh

trap 'fail' ERR

pass() {
  echo "Hooray!"
  set +x #echo off
  exit 0
}

# Use this to trigger fail() at the right places
# if [ "$RESULT" == "Test Failed!" ]; then fail; fi
fail() {
  echo "Test Failed!"
  set +x
  exit 1
}

if [  $# -eq 1 ]; then
  if [ $1 == "debug" ]; then 
    set -x #echo on
  fi
fi

echo "Get Congress policy 'test' ID"
test_policy_ID=$(openstack congress policy show test | awk "/ id / { print \$4 }")

echo "Delete Congress policy 'test' if it exists"
if [ "$test_policy_ID" != "" ]; then 
  openstack congress policy delete $test_policy_ID
  echo "Existing policy 'test' deleted"
fi

echo "Delete cirros1 instance"
instance=$(nova list | awk "/ cirros1 / { print \$2 }")
if [ "$instance" != "" ]; then nova delete $instance; fi

# FLOATING_IP_ID was saved by dmz.sh
source /tmp/TEST_VARS.sh
rm /tmp/TEST_VARS.sh
echo "Delete floating ip"
neutron floatingip-delete $FLOATING_IP_ID

echo "Delete cirros2 instance"
instance=$(nova list | awk "/ cirros2 / { print \$2 }")
if  [ "$instance" != "" ]; then nova delete $instance; fi

echo "Wait for cirros1 and cirros2 to terminate"
COUNTER=5
RESULT="Wait!"
until [[ $COUNTER -eq 0  || $RESULT == "Go!" ]]; do
  cirros1_id=$(openstack server list | awk "/ cirros1 / { print \$4 }")
  cirros2_id=$(openstack server list | awk "/ cirros2 / { print \$4 }")
  if [[ "$cirros1_id" == "" && "$cirros2_id" == "" ]]; then RESULT="Go!"; fi
  let COUNTER-=1
  sleep 5
done

echo "Delete 'dmz' security group"
sg=$(neutron security-group-list | awk "/ dmz / { print \$2 }")
neutron security-group-delete $sg

echo "Get 'test_router' ID"
router=$(neutron router-list | awk "/ test_router / { print \$2 }")

echo "Get internal port ID with subnet 10.0.0.1 on 'test_router'"
test_internal_interface=$(neutron router-port-list $router | grep 10.0.0.1 | awk '{print $2}')

echo "If found, delete the port with subnet 10.0.0.1 on 'test_router'"
if [ "$test_internal_interface" != "" ]; then neutron router-interface-delete $router port=$test_internal_interface; fi

echo "Clear the router gateway"
neutron router-gateway-clear test_router

echo "Delete the router"
neutron router-delete test_router

echo "Delete neutron port with fixed_ip 10.0.0.1"
port=$(neutron port-list | awk "/ 10.0.0.1 / { print \$2 }")
if [ "$port" != "" ]; then neutron port-delete $port; fi

echo "Delete neutron port with fixed_ip 10.0.0.2"
port=$(neutron port-list | awk "/ 10.0.0.2 / { print \$2 }")
if [ "$port" != "" ]; then neutron port-delete $port; fi

echo "Delete internal subnet"
neutron subnet-delete test_internal

echo "Delete internal network"
neutron net-delete test_internal

set +x #echo off

pass

