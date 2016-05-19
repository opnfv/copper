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
# How to use:
#   Install Congress test server per https://wiki.opnfv.org/copper/academy
#   # Create Congress policy and resources that exercise policy
#   $ source ~/git/copper/tests/adhoc/dmz01.sh
#   After test, cleanup
#   $ source ~/git/copper/tests/adhoc/dmz01-clean.sh

if [ $1 == "debug" ]; then set -x #echo on
fi

source /opt/copper/admin-openrc.sh

echo "Delete Congress policy 'test' if it exists"
test_policy_ID=$(openstack congress policy show test | awk "/ id / { print \$4 }")

if [ "$test_policy_ID" != "" ]; then 
# TODO: report bug - should be able to delete by name
  openstack congress policy delete $test_policy_ID
  echo "Existing policy 'test' deleted"
fi

echo "Create Congress policy 'test'"
openstack congress policy create test

echo "Create dmz_server rule in policy 'test'"
openstack congress policy rule create test "dmz_server(x) :- nova:servers(id=x,status='ACTIVE'), neutronv2:ports(id, device_id, status='ACTIVE'),  neutronv2:security_group_port_bindings(pid, sg), neutronv2:security_groups(sg,name='dmz')" --name dmz_server

echo "Create dmz_placement_error rule in policy 'test'"
openstack congress policy rule create test "dmz_placement_error(id) :- nova:servers(id,name,hostId,status,tenant_id,user_id,image), not glancev2:tags(image,'dmz'), dmz_server(id)" --name dmz_placement_error

echo "Create image cirros1 with non-dmz image"
image=$(openstack image list | awk "/ cirros-0.3.3-x86_64 / { print \$2 }")
if [ "$image" == "" ]; then glance --os-image-api-version 1 image-create --name cirros-0.3.3-x86_64 --disk-format qcow2 --location http://download.cirros-cloud.net/0.3.3/cirros-0.3.3-x86_64-disk.img --container-format bare
fi

echo "Create image cirros2 with dmz image"
image=$(openstack image list | awk "/ cirros-0.3.3-x86_64-dmz / { print \$2 }")
if [ "$image" == "" ]; then glance --os-image-api-version 1 image-create --name cirros-0.3.3-x86_64-dmz --disk-format qcow2 --location http://download.cirros-cloud.net/0.3.3/cirros-0.3.3-x86_64-disk.img --container-format bare
fi

echo "Get image ID of cirros dmz image"
IMAGE_ID=$(glance image-list | awk "/ cirros-0.3.3-x86_64-dmz / { print \$2 }")

echo "Add 'dmz' image tag to the cirros dmz image"
glance --os-image-api-version 2 image-tag-update $IMAGE_ID "dmz"

echo "Create external network"
neutron net-create test_public --router:external=true --provider:network_type=flat --provider:physical_network=physnet1

echo "Create external subnet"
neutron subnet-create --disable-dhcp test_public 192.168.10.0/24

echo "Create internal network"
neutron net-create test_internal

echo "Create internal subnet"
neutron subnet-create test_internal 10.0.0.0/24 --name test_internal --gateway 10.0.0.1 --enable-dhcp --allocation-pool start=10.0.0.2,end=10.0.0.254 --dns-nameserver 8.8.8.8

echo "Create router"
neutron router-create test_router

echo "Create router gateway"
neutron router-gateway-set test_router test_public

echo "Add router internal for internal network"
neutron router-interface-add test_router subnet=test_internal

echo "Wait up to a minute for as 'neutron router-interface-add' blocks the neutron-api for some time..."
# add a delay since the previous command takes the neutron-api offline for a while (?)
COUNTER=1
RESULT="Failed!"
until [[ $COUNTER -gt 6  || $RESULT == "Success!" ]]; do
  echo "Get the internal network ID: try" $COUNTER 
  test_internal_NET=$(neutron net-list | awk "/ test_internal / { print \$2 }")
  if [ "$test_internal_NET" != "" ]; then RESULT="Success!"
  fi
  let COUNTER+=1
  sleep 10
done

echo "Create a security group 'dmz'"
neutron security-group-create dmz

echo "Create security group ingress rule for 'dmz'"
neutron security-group-rule-create --direction ingress dmz

echo "Boot cirros1 with non-dmz image"
nova boot --flavor m1.tiny --image cirros-0.3.3-x86_64 --nic net-id=$test_internal_NET --security-groups dmz cirros1

echo "Boot cirros2 with non-dmz image"
nova boot --flavor m1.tiny --image cirros-0.3.3-x86_64-dmz --nic net-id=$test_internal_NET  --security-groups dmz cirros2

echo "Wait 5 seconds for Congress polling to occur at least once"
sleep 5

echo "Get cirros1 instance ID"
test_cirros1_ID=$(openstack server list | awk "/ cirros1 / { print \$2 }")

echo "Get cirros2 instance ID"
test_cirros2_ID=$(openstack server list | awk "/ cirros2 / { print \$2 }")

echo "Verify cirros1 and cirros2 IDs are in the Congress policy 'test' table 'dmz_server'"
COUNTER=5
RESULT="Test Failed!"
until [[ $COUNTER -eq 0  || $RESULT == "Test Success!" ]]; do
  dmz_cirros1=$(openstack congress policy row list test dmz_server | awk "/ $test_cirros1_ID / { print \$2 }")
  dmz_cirros2=$(openstack congress policy row list test dmz_server | awk "/ $test_cirros2_ID / { print \$2 }")
  if [ "$dmz_cirros1" == "$test_cirros1_ID" ] &&  [ "$dmz_cirros2" == "$test_cirros2_ID" ]; then RESULT="Test Success!"
  fi
  let COUNTER-=1
  sleep 5
done
echo "dmz_server table entries present for cirros1, cirros2:" $RESULT

echo "Verify cirros1 ID is in the Congress policy 'test' table 'dmz_placement_error'"
COUNTER=5
RESULT="Test Failed!"
until [[ $COUNTER -eq 0  || $RESULT == "Test Success!" ]]; do
  dmz_cirros1=$(openstack congress policy row list test dmz_placement_error | awk "/ $test_cirros1_ID / { print \$2 }")
  if [ "$dmz_cirros1" == "$test_cirros1_ID" ]; then RESULT="Test Success!"
  fi
  let COUNTER-=1
  sleep 5
done
echo "dmz_placement_error table entry present for cirros2:" $RESULT

echo "Create reactive 'paused_dmz_placement_error' rule in policy 'test'"
openstack congress policy rule create test "execute[nova:servers.pause(id)] :- dmz_placement_error(id), nova:servers(id,status='ACTIVE')" --name paused_dmz_placement_error

echo "Verify cirros1 is paused"
COUNTER=5
RESULT="Test Failed!"
until [[ $COUNTER -eq 0  || $RESULT == "Test Success!" ]]; do
  cirros1_status=$(nova list | awk "/ cirros1 / { print \$6 }")
  if [ "$cirros1_status" == "PAUSED" ]; then RESULT="Test Success!"
  fi
  let COUNTER-=1
  sleep 5
done
echo "Verify cirros1 is paused:" $RESULT

set +x #echo off
