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

openstack congress policy create test

openstack congress policy rule create test "dmz_server(x) :- nova:servers(id=x,status='ACTIVE'), neutronv2:ports(id, device_id, status='ACTIVE'),  neutronv2:security_group_port_bindings(pid, sg), neutronv2:security_groups(sg,name='dmz')" --name dmz_server

openstack congress policy rule create test "cirros(x) :- nova:servers(id=x,image,status='ACTIVE'), glance:images(image,name='cirros')" --name cirros_server

# currently failing "Rule already exists::An unknown exception occurred. (HTTP 409)..."
# openstack congress policy rule create test "dmz_placement_error(id) :- nova:servers(id,name,hostId,status,tenant_id,user_id,image,flavor,OS1,OS2), not glance:images(image,status,gname,container_format,created_at,updated,disk_format,owner,protected,min_ram,min_disk,checksum,size,file,kernel_id,ramdisk_id,ramdisk_id,schema,visibility,tags='dmz'), dmz_server(x)" --name dmz_placement_error

# validated rules created during test development
# openstack congress policy rule create test "active_servers(x) :- nova:servers(id=x, status='ACTIVE')" --name active_servers
# openstack congress policy rule create test "dmz_port(id) :- neutronv2:security_group_port_bindings(id,sg), neutronv2:security_groups(sg,name='dmz')" --name dmz_port
#
# rules under test
# openstack congress policy rule create test "cirros(x) :- glance:images(id=x,name='cirros-0.3.3-x86_64')" --name cirros
# openstack congress policy rule create test "image_notags(x) :- glance:images(id=x,tags='')" --name image_notags
# to remove a policy rule
# openstack congress policy rule delete test nondmz_image

set +x #echo off
