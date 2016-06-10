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

# What this is: An OpenStack Congress policy test. Sets up and validates policy
# creation and execution for:
# 1) Detecting that a reserved subnet has been created, by mistake. "Reserved"
#    in this example means e.g. not intended for use by VMs.
#
# Status: this is a work in progress, under test. 
#
# Prequisite: OPFNV installed per JOID or Apex installer
# - OpenStack CLI environment variables setup
# How to use:
#   Install Congress test server per https://wiki.opnfv.org/copper/academy
#   # Create Congress policy and resources that exercise policy
#   $ bash reserved_subnet.sh
#   After test, cleanup
#   $ bash reserved_subnet-clean.sh

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

echo "Delete internal subnet"
neutron subnet-delete test_internal

echo "Delete internal network"
neutron net-delete test_internal

echo "Delete public network"
neutron subnet-delete test_public

echo "Delete public network"
neutron net-delete test_public

set +x #echo off
