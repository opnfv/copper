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
# 1) Identifying VMs that have STMP (TCP port 25) open for ingress.
#
# Status: this is a work in progress, under test. 
#
# Prequisite: OPFNV installed per JOID or Apex installer
# - OpenStack CLI environment variables setup
# How to use:
#   Install Congress test server per https://wiki.opnfv.org/copper/academy
#   # Create Congress policy and resources that exercise policy
#   $ bash smtp_ingress.sh
#   After test, cleanup
#   $ bash smtp_ingress-clean.sh

pass() {
  echo "Hooray!"
}

# Use this to trigger fail() at the right places
# if [ "$RESULT" == "Test Failed!" ]; then fail; fi
fail() {
  echo "Test Failed!"
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

echo "Create Congress policy 'test'"
if [[ $(openstack congress policy show test | awk "/ id / { print \$4 }") ]]; then unclean; fi
openstack congress policy create test

echo "Create smtp_ingress rule in policy 'test'"
openstack congress policy rule create test "smtp_ingress(x) :- nova:servers(id=x,status='ACTIVE'), neutronv2:ports(port_id, status='ACTIVE'), neutronv2:security_groups(sg, tenant_id, sgn, sgd), neutronv2:security_group_port_bindings(port_id, sg), neutronv2:security_group_rules(sg, rule_id, tenant_id, remote_group_id, 'ingress', ethertype, 'tcp', port_range_min, port_range_max, remote_ip), lt(port_range_min, 26), gt(port_range_max, 24)" --name smtp_ingress

echo "Create image cirros1"
image=$(openstack image list | awk "/ cirros-0.3.3-x86_64 / { print \$2 }")
if [ "$image" == "" ]; then glance --os-image-api-version 1 image-create --name cirros-0.3.3-x86_64 --disk-format qcow2 --location http://download.cirros-cloud.net/0.3.3/cirros-0.3.3-x86_64-disk.img --container-format bare
fi

echo "Create external network"
if [[ $(neutron net-list | awk "/ test_public / { print \$2 }") ]]; then unclean; fi
neutron net-create test_public --router:external=true

echo "Create external subnet"
neutron subnet-create --disable-dhcp test_public 192.168.10.0/24

echo "Create internal network"
if [[ $(neutron net-list | awk "/ test_internal / { print \$2 }") ]]; then unclean; fi
neutron net-create test_internal

echo "Create internal subnet"
neutron subnet-create test_internal 10.0.0.0/24 --name test_internal --gateway 10.0.0.1 --enable-dhcp --allocation-pool start=10.0.0.2,end=10.0.0.254 --dns-nameserver 8.8.8.8

echo "Create router"
if [[ $(neutron router-list | awk "/ test_router / { print \$2 }") ]]; then unclean; fi
neutron router-create test_router

echo "Create router gateway"
neutron router-gateway-set test_router test_public

echo "Add router internal for internal network"
neutron router-interface-add test_router subnet=test_internal

echo "Wait 30 seconds as the previous command interrupts the neutron-api for some time..."
# add a delay since the previous command takes the neutron-api offline for a while (?)
sleep 30

echo "Get the internal network ID"
test_internal_NET=$(neutron net-list | awk "/ test_internal / { print \$2 }")

echo "Create a security group 'smtp_ingress'"
if [[ $(neutron security-group-list | awk "/ smtp_ingress / { print \$2 }") ]]; then unclean; fi
neutron security-group-create smtp_ingress

echo "Create security group ingress rule for 'smtp_ingress'"
neutron security-group-rule-create --direction ingress --protocol=TCP --port-range-min=25 --port-range-max=25 smtp_ingress

echo "Boot cirros1 with smtp_ingress security group"
nova boot --flavor m1.tiny --image cirros-0.3.3-x86_64 --nic net-id=$test_internal_NET --security-groups smtp_ingress cirros1

echo "Wait 30 seconds for Congress polling to occur at least once"
sleep 30

echo "Get cirros1 instance ID"
test_cirros1_ID=$(openstack server list | awk "/ cirros1 / { print \$2 }")

echo "Verify cirros1 is in the Congress policy 'test' table 'smtp_ingress'"
COUNTER=5
RESULT="Test Failed!"
until [[ $COUNTER -eq 0  || $RESULT == "Test Success!" ]]; do
  echo "Check for presence of cirros1 ID in Congress policy 'test' table 'smtp_ingress'"
  cirros1_ID=$(openstack congress policy row list test smtp_ingress | awk "/ $test_cirros1_ID / { print \$2 }")
  if [ "$cirros1_ID" == "$test_cirros1_ID" ]; then RESULT="Test Success!"
  fi
  let COUNTER-=1
  sleep 10
done
echo $RESULT
if [ "$RESULT" == "Test Failed!" ]; then fail; fi
pass
set +x #echo off
