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

wget https://git.opnfv.org/cgit/copper/plain/components/congress/install/bash/setenv.sh -O ~/setenv.sh
source ~/setenv.sh

echo "Create cirros-0.3.3-x86_64 image"
image=$(openstack image list | awk "/ cirros-0.3.3-x86_64 / { print \$2 }")
if [ -z $image ]; then glance --os-image-api-version 1 image-create --name cirros-0.3.3-x86_64 --disk-format qcow2 --location http://download.cirros-cloud.net/0.3.3/cirros-0.3.3-x86_64-disk.img --container-format bare
fi

echo "Create external network"
neutron net-create public --router:external

echo "Create external subnet"
neutron subnet-create public 192.168.10.0/24 --name public --enable_dhcp=False --allocation_pool start=192.168.10.6,end=192.168.10.49 --gateway 192.168.10.1

echo "Create floating IP for external subnet"
neutron floatingip-create public

echo "Create internal network"
neutron net-create internal

echo "Create internal subnet"
neutron subnet-create internal 10.0.0.0/24 --name internal --gateway 10.0.0.1 --enable-dhcp --allocation-pool start=10.0.0.2,end=10.0.0.254 --dns-nameserver 8.8.8.8

echo "Create router"
neutron router-create public_router

echo "Create router gateway"
neutron router-gateway-set public_router public

echo "Add router interface for internal network"
neutron router-interface-add public_router subnet=internal
# add a delay since the previous command takes the neutron-api offline for a while (?)
sleep 30

echo "Create ssh_ingress security group"
neutron security-group-create ssh_ingress

echo "Add rule to ssh_ingress security group"
neutron security-group-rule-create --direction ingress --protocol=TCP --port-range-min=22 --port-range-max=22 ssh_ingress

echo "Wait up to a minute as 'neutron router-interface-add' blocks the neutron-api for some time..."
# add a delay since the previous command takes the neutron-api offline for a while (?)
COUNTER=1
RESULT="Failed!"
until [[ "$COUNTER" -gt 6  || "$RESULT" == "Success!" ]]; do
  echo "Get the internal network ID: try" $COUNTER 
  internal_NET=$(neutron net-list | awk "/ internal / { print \$2 }")
  if [ "$internal_NET" != "" ]; then RESULT="Success!"; fi
  let COUNTER+=1
  sleep 10
done

echo "Boot cirros1"
nova boot --flavor m1.tiny --image cirros-0.3.3-x86_64 --nic net-id=$internal_NET --security-groups ssh_ingress cirros1

echo "Boot cirros1"
nova boot --flavor m1.tiny --image cirros-0.3.3-x86_64 --nic net-id=$internal_NET cirros2

echo "Associate floating IP to cirros1"
nova floating-ip-associate cirros1 192.168.10.6
