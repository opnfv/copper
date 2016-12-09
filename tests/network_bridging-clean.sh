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

# What this is: Cleanup script for the test network_bridging.sh
#
# Status: this is a work in progress, under test. 
#
# Prequisite: OPFNV installed per JOID or Apex installer
# - OpenStack CLI environment variables setup
# How to use:
#   Install Congress test server per https://wiki.opnfv.org/copper/academy
#   # Create Congress policy and resources that exercise policy
#   $ bash network_briding.sh
#   # After test, cleanup
#   $ bash network_briding-clean.sh

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

echo "Delete test_dmz subnet"
neutron subnet-delete test_dmz

echo "Delete test_dmz network"
neutron net-delete test_dmz

echo "Delete test_admin subnet"
neutron subnet-delete test_dmz

echo "Delete test_admin network"
neutron net-delete test_dmz

set +x #echo off

