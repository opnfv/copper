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
# How to use:
#   Install Congress test server per https://wiki.opnfv.org/copper/academy
#   # Create Congress policy and resources that exercise policy
#   $ source reserved_subnet.sh
#   After test, cleanup
#   $ source reserved_subnet-clean.sh

if [ $1 == "debug" ]; then set -x #echo on
fi

source ~/admin-openrc.sh <<EOF
openstack
EOF

echo "Delete Congress policy 'test' if it exists"
test_policy_ID=$(openstack congress policy show test | awk "/ id / { print \$4 }")

if [ "$test_policy_ID" != "" ]; then 
# TODO: report bug - should be able to delete by name
  openstack congress policy delete $test_policy_ID
  echo "Existing policy 'test' deleted"
fi

echo "Create Congress policy 'test'"
openstack congress policy create test

echo "Create smtp_ingress rule in policy 'test'"
openstack congress policy rule create test "reserved_subnet_error(x) :- neutronv2:subnets(id=x, cidr='10.7.1.0/24')" --name rsv_subnet_adm
openstack congress policy rule create test "reserved_subnet_error(x) :- neutronv2:subnets(id=x, cidr='10.7.12.0/24')" --name rsv_subnet_prv
openstack congress policy rule create test "reserved_subnet_error(x) :- neutronv2:subnets(id=x, cidr='10.7.13.0/24')" --name rsv_subnet_stg
openstack congress policy rule create test "reserved_subnet_error(x) :- neutronv2:subnets(id=x, cidr='10.7.14.0/24')" --name rsv_subnet_mgm

echo "Create external network"
neutron net-create test_public --router:external=true --provider:network_type=flat --provider:physical_network=physnet1

echo "Create external subnet"
neutron subnet-create --disable-dhcp test_public 10.7.1.0/24 --name test_public

echo "Get the external subnet ID"
test_public_SUBNET=$(neutron subnet-list | awk "/ test_public / { print \$2 }")

echo "Create internal network"
neutron net-create test_internal

echo "Create internal subnet"
neutron subnet-create test_internal 10.7.12.0/24 --name test_internal --gateway 10.7.12.1 --enable-dhcp --allocation-pool start=10.7.12.2,end=10.7.12.254 --dns-nameserver 8.8.8.8

echo "Get the internal subnet ID"
test_internal_SUBNET=$(neutron subnet-list | awk "/ test_internal / { print \$2 }")

echo "Verify test_public subnet ID is in the Congress policy 'test' table 'reserved_subnet_error'"
COUNTER=5
RESULT="Test Failed!"
until [[ $COUNTER -eq 0  || $RESULT == "Test Success!" ]]; do
  test_public_ID=$(openstack congress policy row list test reserved_subnet_error | awk "/ $test_public_SUBNET / { print \$2 }")
  if [ "$test_public_SUBNET" == "$test_public_ID" ]; then RESULT="Test Success!"
  fi
  let COUNTER-=1
  sleep 5
done
echo "Verify test_public subnet ID is in the Congress policy 'test' table 'reserved_subnet_error':" $RESULT

echo "Verify test_internal subnet ID is in the Congress policy 'test' table 'reserved_subnet_error'"
COUNTER=5
RESULT="Test Failed!"
until [[ $COUNTER -eq 0  || $RESULT == "Test Success!" ]]; do
  test_internal_ID=$(openstack congress policy row list test reserved_subnet_error | awk "/ $test_internal_SUBNET / { print \$2 }")
  if [ "$test_internal_SUBNET" == "$test_internal_ID" ]; then RESULT="Test Success!"
  fi
  let COUNTER-=1
  sleep 5
done
echo "Verify test_internal subnet ID is in the Congress policy 'test' table 'reserved_subnet_error':" $RESULT

echo "Create reactive 'deleted_reserved_subnet_error' rule in policy 'test'"
openstack congress policy rule create test "execute[neutronv2:delete_subnet(x)] :- reserved_subnet_error(x)" --name deleted_reserved_subnet_error

echo "Verify test_internal subnet is deleted"
COUNTER=5
RESULT="Test Failed!"
until [[ $COUNTER -eq 0  || $RESULT == "Test Success!" ]]; do
  test_internal_ID=$(neutron subnet-list | awk "/ test_internal / { print \$2 }")
  if [ "$test_internal_SUBNET" != "$test_internal_ID" ]; then RESULT="Test Success!"
  fi
  let COUNTER-=1
  sleep 5
done
echo "Verify test_internal subnet is deleted:" $RESULT

echo "Verify test_public subnet is deleted"
COUNTER=5
RESULT="Test Failed!"
until [[ $COUNTER -eq 0  || $RESULT == "Test Success!" ]]; do
  test_public_ID=$(neutron subnet-list | awk "/ test_public / { print \$2 }")
  if [ "$test_public_SUBNET" != "$test_public_ID" ]; then RESULT="Test Success!"
  fi
  let COUNTER-=1
  sleep 5
done
echo "Verify test_internal subnet is deleted:" $RESULT

set +x #echo off
