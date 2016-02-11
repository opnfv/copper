#!/bin/bash
# Copyright 2015-2016 Open Platform for NFV Project, Inc. and its contributors
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
# public and private networks, a router, and launches two VMs connected to the 
# private network and thru the router, to the internet.
#
# Status: this is a work in progress, under test. Automated ping test to the 
# internet and between VMs has not yet been implemented.
#
# How to use:
#   Install test server per https://wiki.opnfv.org/copper/academy/congress/test
#   $ source ~/git/copper/tests/adhoc/smoke01.sh
#   After test, cleanup with
#   $ source ~/git/copper/tests/adhoc/smoke01-clean.sh

set -x #echo on

source ~/admin-openrc.sh <<EOF
openstack
EOF

openstack service list

image=$(openstack image list | awk "/ cirros-0.3.3-x86_64 / { print \$2 }")
if [ "$image" == "" ]; then glance --os-image-api-version 1 image-create --name cirros-0.3.3-x86_64 --disk-format qcow2 --location http://download.cirros-cloud.net/0.3.3/cirros-0.3.3-x86_64-disk.img --container-format bare
fi

neutron net-create public --router:external=true --provider:network_type=flat --provider:physical_network=physnet1

neutron subnet-create --disable-dhcp public 192.168.10.0/24

neutron net-create internal

neutron subnet-create internal 10.0.0.0/24 --name internal --gateway 10.0.0.1 --enable-dhcp --allocation-pool start=10.0.0.2,end=10.0.0.254 --dns-nameserver 8.8.8.8

neutron router-create external

neutron router-gateway-set external public

neutron router-interface-add external subnet=internal
# add a delay since the previous command takes the neutron-api offline for a while (?)
sleep 30

INTERNAL_NET=$(neutron net-list | awk "/ internal / { print \$2 }")

nova boot --flavor m1.tiny --image cirros-0.3.3-x86_64 --nic net-id=$INTERNAL_NET cirros1

nova boot --flavor m1.tiny --image cirros-0.3.3-x86_64 --nic net-id=$INTERNAL_NET cirros2

set +x #echo off
