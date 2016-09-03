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
# 1) Identifying VMs connected to a DMZ (currently identified through a 
#    specifically-named security group)
# 2) Identifying VMs connected per (1), which are by policy not allowed to be
#    (currently implemented through an image tag intended to identify images
#    that are "authorized" i.e. tested and secure, to be DMZ-connected)
# 3) Reactively enforce the dmz placement rule by pausing VMs found to be in
#    violation of the policy.
#
# Status: this is a work in progress, under test.
#
# Prequisite: OPFNV installed per JOID or Apex installer
# - OpenStack CLI environment variables setup
# How to use:
#   # Create Congress policy and resources that exercise policy
#   $ bash dmz.sh
#   # After test, cleanup
#   $ bash dmz-clean.sh

#VARS
TEST_FAIL='Test Failed!'
TEST_PASS='Test Success!'

pass() {
  echo "Hooray!"
  set +x #echo off
  exit 0
}

# Use this to trigger fail() at the right places
# if [ "$RESULT" == "Test Failed!" ]; then fail; fi
fail() {
  echo ${TEST_FAIL}
  set +x
  exit 1
}

unclean() {
  echo "Unclean environment!"
  fail
}

if [  $# -eq 1 ]; then
  if [ $1 == "debug" ]; then 
    set -x #echo on
  fi
fi

# Find external network if any, and details
function get_external_net () {
  network_ids=($(neutron net-list|grep -v "+"|grep -v name|awk '{print $2}'))
  for id in ${network_ids[@]}; do
      [[ $(neutron net-show ${id}|grep 'router:external'|grep -i "true") != "" ]] && ext_net_id=${id}
  done
  if [[ $ext_net_id ]]; then 
    EXTERNAL_NETWORK_NAME=$(openstack network show $ext_net_id | awk "/ name / { print \$4 }")
    EXTERNAL_SUBNET_ID=$(openstack network show $EXTERNAL_NETWORK_NAME | awk "/ subnets / { print \$4 }")
  else
    echo "External network not found"
    echo "Create external network"
    neutron net-create public --router:external
    EXTERNAL_NETWORK_NAME="public"
    echo "Create external subnet"
    neutron subnet-create public 192.168.10.0/24 --name public --enable_dhcp=False --allocation_pool start=192.168.10.6,end=192.168.10.49 --gateway 192.168.10.1
    EXTERNAL_SUBNET_ID=$(openstack subnet show public | awk "/ id / { print \$4 }")
  fi
}

trap 'fail' ERR

echo "Create Congress policy 'test'"
if openstack congress policy list | grep test; then unclean; fi
openstack congress policy create test

sleep 5

echo "Create dmz_server rule in policy 'test'"
openstack congress policy rule create test "dmz_server(x) :- nova:servers(id=x,status='ACTIVE'), neutronv2:ports(id, device_id, status='ACTIVE'),  neutronv2:security_group_port_bindings(id, sg), neutronv2:security_groups(sg,name='dmz')" --name dmz_server

echo "Create dmz_placement_error rule in policy 'test'"
openstack congress policy rule create test "dmz_placement_error(id) :- nova:servers(id,name,hostId,status,tenant_id,user_id,image,flavor,az,hh), not glancev2:tags(image,'dmz'), dmz_server(id)" --name dmz_placement_error

echo "Create non-dmz cirros image"
if ! openstack image show cirros-0.3.3-x86_64 2>/dev/null; then
  glance --os-image-api-version 1 image-create --name cirros-0.3.3-x86_64 --disk-format qcow2 --copy-from 'http://download.cirros-cloud.net/0.3.3/cirros-0.3.3-x86_64-disk.img' --container-format bare
fi

echo "Create image cirros dmz image"
if ! openstack image show cirros-0.3.3-x86_64-dmz 2>/dev/null; then
  glance --os-image-api-version 1 image-create --name cirros-0.3.3-x86_64-dmz --disk-format qcow2 --location http://download.cirros-cloud.net/0.3.3/cirros-0.3.3-x86_64-disk.img --container-format bare
fi

echo "Get image ID of cirros dmz image"
IMAGE_ID=$(openstack image show cirros-0.3.3-x86_64-dmz -c id | grep id | awk '{ print $4 }')

echo "Add 'dmz' image tag to the cirros dmz image"
glance --os-image-api-version 2 image-tag-update $IMAGE_ID "dmz"

get_external_net

echo "Create floating IP for external subnet"
FLOATING_IP_ID=$(neutron floatingip-create $EXTERNAL_NETWORK_NAME | awk "/ id / { print \$4 }")
FLOATING_IP=$(neutron floatingip-show $FLOATING_IP_ID | awk "/ floating_ip_address / { print \$4 }" | cut -d - -f 1)
# Save ID to pass to cleanup script
echo "FLOATING_IP_ID=$FLOATING_IP_ID" >/tmp/TEST_VARS.sh

echo "Create internal network"
if neutron net-list | grep test_internal; then
  unclean
else
  neutron net-create test_internal
fi

echo "Create internal subnet"
neutron subnet-create test_internal 10.0.0.0/24 --name test_internal --gateway 10.0.0.1 --enable-dhcp --allocation-pool start=10.0.0.2,end=10.0.0.254

echo "Create router"
if neutron router-list | grep test_router; then
  unclean
else
  neutron router-create test_router
fi

echo "Create router gateway"
neutron router-gateway-set test_router $EXTERNAL_NETWORK_NAME

echo "Add router internal for internal network"
neutron router-interface-add test_router subnet=test_internal

COUNTER=1
RESULT="Failed!"
until [[ "$COUNTER" -gt 6  || "$RESULT" == "Success!" ]]; do
  echo "Get the internal network ID: try" $COUNTER 
  test_internal_NET=$(neutron net-list | awk "/ test_internal / { print \$2 }")
  if [ "$test_internal_NET" != "" ]; then RESULT="Success!"; fi
  let COUNTER+=1
  sleep 10
done
if [ "$RESULT" == "$TEST_FAIL" ]; then fail; fi

echo "Create a security group 'dmz'"
if neutron security-group-list | grep dmz; then unclean; fi
if ! neutron security-group-create dmz; then
  echo "Unable to create security group"
  fail
fi

echo "Create security group ingress rule for 'dmz'"
neutron security-group-rule-create --direction ingress dmz

echo "Boot cirros1 with non-dmz image"
nova boot --flavor m1.tiny --image cirros-0.3.3-x86_64 --nic net-id=$test_internal_NET --security-groups dmz cirros1

echo "Get cirros1 instance ID"
test_cirros1_ID=$(openstack server list | awk "/ cirros1 / { print \$2 }")

echo "Wait for cirros1 to go ACTIVE"
COUNTER=5
RESULT=${TEST_FAIL}
until [[ $COUNTER -eq 0  || $RESULT == "$TEST_PASS" ]]; do
  status=$(openstack server show $test_cirros1_ID | awk "/ status / { print \$4 }")
  if [[ "$status" == "ACTIVE" ]]; then RESULT="$TEST_PASS"; fi
  let COUNTER-=1
  sleep 5
done
if [ "$RESULT" == "$TEST_FAIL" ]; then fail; fi

echo "Associate floating IP to cirros1"
nova floating-ip-associate cirros1 $FLOATING_IP

echo "Boot cirros2 with dmz image"
nova boot --flavor m1.tiny --image cirros-0.3.3-x86_64-dmz --nic net-id=$test_internal_NET  --security-groups dmz cirros2
test_cirros2_ID=$(nova list | awk "/ cirros2 / { print \$2 }")
if [ -z $test_cirros2_ID ]; then
  echo "Unable to boot cirros2"
  fail
fi

echo "Wait 5 seconds for Congress polling to occur at least once"
sleep 5

echo "Verify cirros1 and cirros2 IDs are in the Congress policy 'test' table 'dmz_server'"
COUNTER=5
RESULT=${TEST_FAIL}
until [[ $COUNTER -eq 0  || $RESULT == "$TEST_PASS" ]]; do
  openstack congress policy row list test dmz_server
  dmz_cirros1=$(openstack congress policy row list test dmz_server | awk "/ $test_cirros1_ID / { print \$2 }")
  dmz_cirros2=$(openstack congress policy row list test dmz_server | awk "/ $test_cirros2_ID / { print \$2 }")
  if [[ "$dmz_cirros1" == "$test_cirros1_ID" && "$dmz_cirros2" == "$test_cirros2_ID" ]]; then RESULT="$TEST_PASS"; fi
  let COUNTER-=1
  sleep 5
done
echo "dmz_server table entries present for cirros1, cirros2:" $RESULT
if [ "$RESULT" == "$TEST_FAIL" ]; then fail; fi

echo "Verify cirros1 ID is in the Congress policy 'test' table 'dmz_placement_error'"
COUNTER=5
RESULT="$TEST_FAIL"
until [[ $COUNTER -eq 0  || $RESULT == "$TEST_PASS" ]]; do
  openstack congress policy row list test dmz_placement_error
  dmz_cirros1=$(openstack congress policy row list test dmz_placement_error | awk "/ $test_cirros1_ID / { print \$2 }")
  if [ "$dmz_cirros1" == "$test_cirros1_ID" ]; then RESULT=${TEST_PASS}; fi
  let COUNTER-=1
  sleep 5
done
echo "dmz_placement_error table entry present for cirros2:" $RESULT
if [ "$RESULT" == "$TEST_FAIL" ]; then fail; fi

echo "Create reactive 'paused_dmz_placement_error' rule in policy 'test'"
openstack congress policy rule create test "execute[nova:servers.pause(id)] :- dmz_placement_error(id), nova:servers(id,status='ACTIVE')" --name paused_dmz_placement_error

echo "Verify cirros1 is paused"
COUNTER=5
RESULT=${TEST_FAIL}
until [[ $COUNTER -eq 0  || $RESULT == "$TEST_PASS" ]]; do
  nova list
  cirros1_status=$(nova list | awk "/ cirros1 / { print \$6 }")
  if [ "$cirros1_status" == "PAUSED" ]; then RESULT="$TEST_PASS"; fi
  let COUNTER-=1
  sleep 5
done
echo "Verify cirros1 is paused: ${RESULT}"
if [ "$RESULT" == "$TEST_FAIL" ]; then fail; fi

set +x #echo off

pass
