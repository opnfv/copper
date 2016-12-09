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
# 1) Detecting that a VM is connected to two networks of different 'security
#    levels'. 'Security levels' in this example means that the service
#    provider assigns distinct sensitivity/risk to connections over those
#    networks, e.g. a public network (e.g. DMZ) and an internal/private network 
#    (e.g. service provider admin network
# 2) Identifying VMs connected per (1), which are by policy not allowed to be
#    (currently implemented through an image tag intended to identify images
#    that are "authorized" i.e. tested and secure, to bridge such networks).
#
# Status: this is a work in progress, under test.
#
# Prequisite: OPFNV installed per JOID or Apex installer
# - OpenStack CLI environment variables setup
# How to use:
#   # Create Congress policy and resources that exercise policy
#   $ bash network_bridging.sh
#   # After test, cleanup
#   $ bash network_bridging-clean.sh

trap 'fail' ERR

pass() {
  echo "$0: $(date) Hooray!"
  set +x #echo off
  exit 0
}

# Use this to trigger fail() at the right places
# if [ "$RESULT" == "Test Failed!" ]; then fail; fi
fail() {
  echo "$0: $(date) Test Failed!"
  set +x
  exit 1
}

unclean() {
  echo "$0: $(date) Unclean environment!"
  fail
}

if [  $# -eq 1 ]; then
  if [ $1 == "debug" ]; then 
    set -x #echo on
  fi
fi

echo "$0: $(date) Create Congress policy 'test'"
if [ $(openstack congress policy show test | awk "/ id / { print \$4 }") ]; then unclean; fi
openstack congress policy create test

echo "$0: $(date) Create sp_dmz_connected rule in policy 'test'"
openstack congress policy rule create test 'sp_dmz_connected(x) :- nova:servers(id=x), neutronv2:ports(device_owner=x), neutronv2:networks(id=z, tenant_id=w, name="test_dmz"), keystone:tenants(enabled, name="admin", id=w)' --name sp_dmz_connected

echo "$0: $(date) Create sp_admin_connected rule in policy 'test'"
openstack congress policy rule create test 'sp_dmz_connected(x) :- nova:servers(id=x), neutronv2:ports(device_owner=x), neutronv2:networks(id=z, tenant_id=w, name="test_admin"), keystone:tenants(enabled, name="admin", id=w)' --name sp_admin_connected

echo "$0: $(date) Create dmz_admin_connnected rule in policy 'test'"
openstack congress policy rule create test 'dmz_admin_connnected(x) :- sp_dmz_connected(x), sp_admin_connected(x)' --name dmz_admin_connnected

echo "$0: $(date) Create dmz_admin_bridging_error rule in policy 'test'"
openstack congress policy rule create test 'dmz_admin_bridging_error(id) :- nova:servers(id,name,hostId,status,tenant_id=x), not keystone:tenants(enabled, name="SP", id=x)' --name dmz_admin_bridging_error

echo "$0: $(date) Create dmz_admin_bridging_error rule in policy 'test'"
openstack congress policy rule create test 'execute[nova:servers.pause(id)] :- dmz_admin_bridging_error(id), nova:servers(id,status="ACTIVE")' --name paused_dmz_admin_bridging_error

echo "$0: $(date) Create image cirros1 as non-briding-authorized image"
image=$(openstack image list | awk "/ cirros-0.3.3-x86_64 / { print \$2 }")
if [ -z $image ]; then glance --os-image-api-version 1 image-create --name cirros-0.3.3-x86_64 --disk-format qcow2 --location http://download.cirros-cloud.net/0.3.3/cirros-0.3.3-x86_64-disk.img --container-format bare
fi

echo "$0: $(date) Create image cirros2 as briding-authorized image"
image=$(openstack image list | awk "/ cirros-0.3.3-x86_64 / { print \$2 }")
if [ -z $image ]; then glance --os-image-api-version 1 image-create --name cirros-0.3.3-x86_64-dmz --disk-format qcow2 --location http://download.cirros-cloud.net/0.3.3/cirros-0.3.3-x86_64-disk.img --container-format bare
fi

echo "$0: $(date) Get image ID of cirros2 image"
IMAGE_ID=$(glance image-list | awk "/ cirros-0.3.3-x86_64-bridging / { print \$2 }")

echo "$0: $(date) Add 'bridging-authorized' image tag to the cirros2 image"
glance --os-image-api-version 2 image-tag-update $IMAGE_ID "bridging-authorized"

echo "$0: $(date) Create admin network"
if [ $(neutron net-list | awk "/ test_admin / { print \$2 }") ]; then unclean; fi
neutron net-create test_dmz

echo "$0: $(date) Create dmz subnet"
neutron subnet-create test_dmz 10.0.0.0/24 --name test_dmz --gateway 10.0.0.1 --enable-dhcp --allocation-pool start=10.0.0.2,end=10.0.0.254 --dns-nameserver 8.8.8.8

echo "$0: $(date) Create dmz network"
if [ $(neutron net-list | awk "/ test_dmz / { print \$2 }") ]; then unclean; fi
neutron net-create test_dmz

echo "$0: $(date) Create dmz subnet"
neutron subnet-create test_dmz 10.0.1.0/24 --name test_dmz --gateway 10.0.1.1 --enable-dhcp --allocation-pool start=10.0.1.2,end=10.0.1.254 --dns-nameserver 8.8.8.8

echo "$0: $(date) Boot cirros1"
nova boot --flavor m1.tiny --image cirros-0.3.3-x86_64 --nic net-name="test_dmz"  net-name="test_admin" cirros1
test_cirros1_ID=$(nova list | awk "/ cirros1 / { print \$2 }")

echo "$0: $(date) Boot cirros2"
nova boot --flavor m1.tiny --image cirros-0.3.3-x86_64-bridging --nic net-name="test_dmz"  net-name="test_admin" cirros2
test_cirros2_ID=$(nova list | awk "/ cirros2 / { print \$2 }")

echo "$0: $(date) Wait 5 seconds for Congress polling to occur at least once"
sleep 5

echo "$0: $(date) Verify cirros1 and cirros2 IDs are in the Congress policy 'test' table 'sp_dmz_connected'"
COUNTER=5
RESULT="Test Failed!"
until [[ $COUNTER -eq 0  || $RESULT == "Test Success!" ]]; do
  openstack congress policy row list test sp_dmz_connected
  dmz_cirros1=$(openstack congress policy row list test sp_dmz_connected | awk "/ $test_cirros1_ID / { print \$2 }")
  dmz_cirros2=$(openstack congress policy row list test sp_dmz_connected | awk "/ $test_cirros2_ID / { print \$2 }")
  if [[ "$dmz_cirros1" == "$test_cirros1_ID" && "$dmz_cirros2" == "$test_cirros2_ID" ]]; then RESULT="Test Success!"; fi
  let COUNTER-=1
  sleep 5
done
echo "$0: $(date) sp_dmz_connected table entries present for cirros1, cirros2:" $RESULT
if [ "$RESULT" == "Test Failed!" ]; then fail; fi

echo "$0: $(date) Verify cirros1 and cirros2 IDs are in the Congress policy 'test' table 'sp_admin_connected'"
COUNTER=5
RESULT="Test Failed!"
until [[ $COUNTER -eq 0  || $RESULT == "Test Success!" ]]; do
  openstack congress policy row list test sp_admin_connected
  dmz_cirros1=$(openstack congress policy row list test sp_admin_connected | awk "/ $test_cirros1_ID / { print \$2 }")
  dmz_cirros2=$(openstack congress policy row list test sp_admin_connected | awk "/ $test_cirros2_ID / { print \$2 }")
  if [[ "$dmz_cirros1" == "$test_cirros1_ID" && "$dmz_cirros2" == "$test_cirros2_ID" ]]; then RESULT="Test Success!"; fi
  let COUNTER-=1
  sleep 5
done
echo "$0: $(date) sp_admin_connected table entries present for cirros1, cirros2:" $RESULT
if [ "$RESULT" == "Test Failed!" ]; then fail; fi

echo "$0: $(date) Verify cirros1 and cirros2 IDs are in the Congress policy 'test' table 'dmz_admin_connected'"
COUNTER=5
RESULT="Test Failed!"
until [[ $COUNTER -eq 0  || $RESULT == "Test Success!" ]]; do
  openstack congress policy row list test dmz_admin_connected
  dmz_cirros1=$(openstack congress policy row list test dmz_admin_connected | awk "/ $test_cirros1_ID / { print \$2 }")
  dmz_cirros2=$(openstack congress policy row list test dmz_admin_connected | awk "/ $test_cirros2_ID / { print \$2 }")
  if [[ "$dmz_cirros1" == "$test_cirros1_ID" && "$dmz_cirros2" == "$test_cirros2_ID" ]]; then RESULT="Test Success!"; fi
  let COUNTER-=1
  sleep 5
done
echo "$0: $(date) dmz_admin_connected table entries present for cirros1, cirros2:" $RESULT
if [ "$RESULT" == "Test Failed!" ]; then fail; fi

echo "$0: $(date) Verify cirros1 ID is in the Congress policy 'test' table 'dmz_admin_bridging_error'"
COUNTER=5
RESULT="Test Failed!"
until [[ $COUNTER -eq 0  || $RESULT == "Test Success!" ]]; do
  openstack congress policy row list test dmz_admin_bridging_error
  dmz_cirros1=$(openstack congress policy row list test dmz_admin_bridging_error | awk "/ $test_cirros1_ID / { print \$2 }")
  if [ "$dmz_cirros1" == "$test_cirros1_ID" ]; then RESULT="Test Success!"; fi
  let COUNTER-=1
  sleep 5
done
echo "$0: $(date) dmz_admin_bridging_error table entry present for cirros1:" $RESULT
if [ "$RESULT" == "Test Failed!" ]; then fail; fi

echo "$0: $(date) Verify cirros1 is paused"
COUNTER=5
RESULT="Test Failed!"
until [[ $COUNTER -eq 0  || $RESULT == "Test Success!" ]]; do
  nova list
  cirros1_status=$(nova list | awk "/ cirros1 / { print \$6 }")
  if [ "$cirros1_status" == "PAUSED" ]; then RESULT="Test Success!"; fi
  let COUNTER-=1
  sleep 5
done
echo "$0: $(date) Verify cirros1 is paused:" $RESULT
if [ "$RESULT" == "Test Failed!" ]; then fail; fi

set +x #echo off

pass
