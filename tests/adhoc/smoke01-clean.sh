#!/bin/bash
# Copyright 2015 Open Platform for NFV Project, Inc. and its contributors
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

# What this is: Cleanup script for a basic test to validate an OPNFV install. 
#
# Status: this is a work in progress, under test. 
#
# How to use:
#   Install test server per https://wiki.opnfv.org/copper/academy/congress/test
#   $ source ~/git/copper/tests/adhoc/smoke01.sh
#   After test, cleanup with
#   $ source ~/git/copper/tests/adhoc/smoke01-clean.sh

set -x #echo on

instance=$(nova list | awk "/ cirros1 / { print \$2 }")
if [ "$instance" != "" ]; then nova delete $instance
fi

instance=$(nova list | awk "/ cirros2 / { print \$2 }")
if  [ "$instance" != "" ]; then nova delete $instance
fi

router=$(neutron router-list | awk "/ external / { print \$2 }")

internal_interface=$(neutron router-port-list $router | grep 10.0.0.1 | awk '{print $2}')

if [ "$internal_interface" != "" ]; then neutron router-interface-delete $router port=$internal_interface
fi

public_interface=$(neutron router-port-list $router | grep 191.168.10.2 | awk '{print $2}')

if [ "$public_interface" != "" ]; then neutron router-interface-delete $router port=$public_interface
fi

neutron router-interface-delete $router $internal_interface

neutron router-gateway-clear external

neutron router-delete external

port=$(neutron port-list | awk "/ 10.0.0.1 / { print \$2 }")

if [ "$port" != "" ]; then neutron port-delete $port
fi

port=$(neutron port-list | awk "/ 10.0.0.2 / { print \$2 }")

if [ "$port" != "" ]; then neutron port-delete $port
fi

neutron subnet-delete internal

neutron net-delete internal

neutron subnet-delete public

neutron net-delete public

set +x #echo off
