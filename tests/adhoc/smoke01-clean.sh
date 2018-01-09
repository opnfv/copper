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

# What this is: Cleanup script for a basic test to validate an OPNFV install. 
#
# Status: this is a work in progress, under test. 
#
# How to use:
#   Install Congress test server per https://wiki.opnfv.org/copper/academy
#   $ source ~/git/copper/tests/adhoc/smoke01.sh
#   After test, cleanup with
#   $ source ~/git/copper/tests/adhoc/smoke01-clean.sh


function log() {
  f=$(caller 0 | awk '{print $2}')
  l=$(caller 0 | awk '{print $1}')
  echo; echo "$f:$l ($(date)) $1"
}

function smoke01_clean() {
  log "Delete cirros1 instance"
  instance=$(nova list | awk "/ cirros1 / { print \$2 }")
  if [ "$instance" != "" ]; then nova delete $instance; fi

  log "Delete cirros2 instance"
  instance=$(nova list | awk "/ cirros2 / { print \$2 }")
  if  [ "$instance" != "" ]; then nova delete $instance; fi

  log "Wait for cirros1 and cirros2 to terminate"
  COUNTER=5
  RESULT="Wait!"
  until [[ $COUNTER -eq 0  || $RESULT == "Go!" ]]; do
    cirros1_id=$(openstack server list | awk "/ cirros1 / { print \$4 }")
    cirros2_id=$(openstack server list | awk "/ cirros2 / { print \$4 }")
    if [[ "$cirros1_id" == "" && "$cirros2_id" == "" ]]; then RESULT="Go!"; fi
    let COUNTER-=1
    sleep 5
  done

  log "Delete 'smoke01' security group"
  openstack security group delete smoke01

  log "Delete floating ip"
  # FLOATING_IP_ID was saved by smoke01.sh
  source /tmp/SMOKE01_VARS.sh
  rm /tmp/SMOKE01_VARS.sh
  openstack floating ip delete $FLOATING_IP_ID

  log "Delete Nova key pair smoke01"
  openstack keypair delete smoke01
  rm /tmp/smoke01

  log "Delete Nova flavor smoke01.tiny"
  openstack flavor delete smoke01.tiny

  log "Get 'public_router' ID"
  router=$(openstack router list | awk "/ public_router / { print \$2 }")

  log "Remove public_router_internal_port from public_router"
  openstack router remove port public_router public_router_internal_port

  log "Clear the router gateway"
  openstack router unset --external-gateway public_router

  log "Delete the router"
  openstack router delete public_router

  log "Delete port with fixed_ip 10.0.0.1"
  port=$(openstack port list | awk "/'10.0.0.1'/ { print \$2 }")
  if [ "$port" != "" ]; then openstack port delete $port; fi

  log "Delete port with fixed_ip 10.0.0.2"
  port=$(openstack port list | awk "/'10.0.0.2'/ { print \$2 }")
  if [ "$port" != "" ]; then openstack port delete $port; fi

  log "Delete internal subnet"
  openstack subnet delete internal

  log "Delete internal network"
  openstack network delete internal
}

smoke01_clean

