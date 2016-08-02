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
# What this is: A basic test to validate an OPNFV install. Creates an image,
# test_public and private networks, a router, and launches two VMs connected to the 
# private network and thru the router, to the internet.
#
# Status: this is a work in progress, under test. Automated ping test to the 
# internet and between VMs has not yet been implemented.
#
# How to use:
#   Install Congress test server per https://wiki.opnfv.org/copper/academy
#   $ bash ~/git/copper/tests/adhoc/smoke01.sh
#   After test, cleanup with
#   $ bash ~/git/copper/tests/adhoc/smoke01-clean.sh

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
  echo "Find external network"
  LINE=4
  ID=$(openstack network list | awk "NR==$LINE{print \$2}")
  while [[ $ID ]]
    do
    if [[ $(openstack network show $ID | awk "/ router/ { print \$4 }") == "External" ]]; then break; fi
    ((LINE+=1))
    ID=$(openstack network list | awk "NR==$LINE{print \$2}")
  done 
  if [[ $ID ]]; then 
    EXTERNAL_NETWORK_NAME=$(openstack network show $ID | awk "/ name / { print \$4 }")
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

wget https://git.opnfv.org/cgit/copper/plain/components/congress/install/bash/setenv.sh -O ~/setenv.sh
source ~/setenv.sh

echo "Create cirros-0.3.3-x86_64 image"
image=$(openstack image list | awk "/ cirros-0.3.3-x86_64 / { print \$2 }")
if [ -z $image ]; then glance --os-image-api-version 1 image-create --name cirros-0.3.3-x86_64 --disk-format qcow2 --location http://download.cirros-cloud.net/0.3.3/cirros-0.3.3-x86_64-disk.img --container-format bare
fi

get_external_net

echo "Create floating IP for external subnet"
FLOATING_IP_ID=$(neutron floatingip-create $EXTERNAL_NETWORK_NAME | awk "/ id / { print \$4 }")
FLOATING_IP=$(neutron floatingip-show $FLOATING_IP_ID | awk "/ floating_ip_address / { print \$4 }" | cut -d - -f 1)
# Save ID to pass to cleanup script
echo "FLOATING_IP_ID=$FLOATING_IP_ID" >/tmp/TEST_VARS.sh

echo "Create internal network"
neutron net-create internal

echo "Create internal subnet"
neutron subnet-create internal 10.0.0.0/24 --name internal --gateway 10.0.0.1 --enable-dhcp --allocation-pool start=10.0.0.2,end=10.0.0.254 --dns-nameserver 8.8.8.8

echo "Create router"
neutron router-create public_router

echo "Create router gateway"
neutron router-gateway-set public_router $EXTERNAL_NETWORK_NAME

echo "Add router interface for internal network"
neutron router-interface-add public_router subnet=internal

echo "Wait up to a minute as 'neutron router-interface-add' blocks the neutron-api for some time..."
COUNTER=1
RESULT="Failed!"
until [[ "$COUNTER" -gt 6  || "$RESULT" == "Success!" ]]; do
  echo "Get the internal network ID: try" $COUNTER 
  internal_NET=$(neutron net-list | awk "/ internal / { print \$2 }")
  if [ "$internal_NET" != "" ]; then RESULT="Success!"; fi
  let COUNTER+=1
  sleep 10
done
if [ "$RESULT" == "Test Failed!" ]; then fail; fi

echo "Create smoke01 security group"
neutron security-group-create smoke01

echo "Add rule to smoke01 security group"
neutron security-group-rule-create --direction ingress --protocol=TCP --remote-ip-prefix 0.0.0.0/0 --port-range-min=22 --port-range-max=22 smoke01
neutron security-group-rule-create --direction ingress --protocol=ICMP --remote-ip-prefix 0.0.0.0/0 smoke01
neutron security-group-rule-create --direction egress --protocol=TCP --remote-ip-prefix 0.0.0.0/0 --port-range-min=22 --port-range-max=22 smoke01
neutron security-group-rule-create --direction egress --protocol=ICMP --remote-ip-prefix 0.0.0.0/0 smoke01

echo "Create Nova key pair"
ssh-keygen -f "$HOME/.ssh/known_hosts" -R 192.168.10.6
nova keypair-add smoke01 > /tmp/smoke01
chmod 600 /tmp/smoke01

echo "Boot cirros1"
nova boot --flavor m1.tiny --image cirros-0.3.3-x86_64 --nic net-id=$internal_NET --security-groups smoke01 --key-name smoke01 cirros1

echo "Get cirros1 instance ID"
test_cirros1_ID=$(openstack server list | awk "/ cirros1 / { print \$2 }")

echo "Wait for cirros1 to go ACTIVE"
COUNTER=5
RESULT="Test Failed!"
until [[ $COUNTER -eq 0  || $RESULT == "Test Success!" ]]; do
  status=$(openstack server show $test_cirros1_ID | awk "/ status / { print \$4 }")
  if [[ "$status" == "ACTIVE" ]]; then RESULT="Test Success!"; fi
  let COUNTER-=1
  sleep 5
done
if [ "$RESULT" == "Test Failed!" ]; then fail; fi

echo "Associate floating IP to cirros1"
nova floating-ip-associate cirros1 $FLOATING_IP

echo "Boot cirros2"
nova boot --flavor m1.tiny --image cirros-0.3.3-x86_64 --nic net-id=$internal_NET --security-groups smoke01 cirros2

COUNTER=1
RESULT="Failed!"
until [[ "$COUNTER" -gt 6  || "$RESULT" == "Success!" ]]; do
  echo "Verify internal network connectivity"
  RESULT=$(ssh -i /tmp/smoke01 -x -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no cirros@$FLOATING_IP "ping -c 3 10.0.0.4; exit" | awk "/ 0% packet loss/ { print \$1 }")
  if [ "$RESULT" == "3" ]; then RESULT="Success!"; fi
  let COUNTER+=1
  sleep 10
done
if [ "$RESULT" == "Test Failed!" ]; then fail; fi

echo "Verify public network connectivity"
RESULT=$(ssh -i /tmp/smoke01 -x -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no cirros@$FLOATING_IP "ping -c 3 8.8.8.8; exit" | awk "/ 0% packet loss/ { print \$1 }")
if [ "$RESULT" != "3" ]; then fail; fi

set +x #echo off

pass
