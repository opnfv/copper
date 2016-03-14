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

# What this is: An OpenStack Congress policy test. Sets up and validates policy
# creation and execution for:
# 1) Identifying VMs connected to a DMZ (currently identified through a 
#    specifically-named security group)
# 2) Identifying VMs connected per (1), which are by policy not allowed to be
#    (currently implemented through an image tag intended to identify images
#    that are "authorized" i.e. tested and secure, to be DMZ-connected) 
#
# Status: this is a work in progress, under test. Test (1) has been verified, 
# Test (2) is still in development.
#
# How to use:
#   Install test server per https://wiki.opnfv.org/copper/academy/congress/test
#   # Create Congress policy
#   $ source ~/git/copper/tests/adhoc/dmz01_1.sh
#   # Create VMs etc that exercise policy
#   $ source ~/git/copper/tests/adhoc/dmz01_2.sh
#   After test, cleanup with (not yet implemented)
#   $ source ~/git/copper/tests/adhoc/dmz01-clean.sh

set -x #echo on

source ~/admin-openrc.sh <<EOF
openstack
EOF

image=$(openstack image list | awk "/ cirros-0.3.3-x86_64 / { print \$2 }")
if [ "$image" == "" ]; then glance --os-image-api-version 1 image-create --name cirros-0.3.3-x86_64 --disk-format qcow2 --location http://download.cirros-cloud.net/0.3.3/cirros-0.3.3-x86_64-disk.img --container-format bare
fi

image=$(openstack image list | awk "/ cirros-0.3.3-x86_64-dmz / { print \$2 }")
if [ "$image" == "" ]; then glance --os-image-api-version 1 image-create --name cirros-0.3.3-x86_64-dmz --disk-format qcow2 --location http://download.cirros-cloud.net/0.3.3/cirros-0.3.3-x86_64-disk.img --container-format bare
fi

IMAGE_ID=$(glance image-list | awk "/ cirros-0.3.3-x86_64-dmz / { print \$2 }")

glance --os-image-api-version 2 image-tag-update $IMAGE_ID "dmz"

neutron net-create test_public --router:external=true --provider:network_type=flat --provider:physical_network=physnet1

neutron subnet-create --disable-dhcp test_public 192.168.10.0/24

neutron net-create test_internal

neutron subnet-create test_internal 10.0.0.0/24 --name test_internal --gateway 10.0.0.1 --enable-dhcp --allocation-pool start=10.0.0.2,end=10.0.0.254 --dns-nameserver 8.8.8.8

neutron router-create test_router

neutron router-gateway-set test_router test_public

neutron router-interface-add test_router subnet=test_internal
# add a delay since the previous command takes the neutron-api offline for a while (?)
sleep 30

test_internal_NET=$(neutron net-list | awk "/ test_internal / { print \$2 }")

neutron security-group-create dmz

neutron security-group-rule-create --direction ingress  dmz

nova boot --flavor m1.tiny --image cirros-0.3.3-x86_64 --nic net-id=$test_internal_NET --security-groups dmz cirros1

nova boot --flavor m1.tiny --image cirros-0.3.3-x86_64-dmz --nic net-id=$test_internal_NET  --security-groups dmz cirros2

set +x #echo off
