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
# Prerequisites:
#   OpenStack installed.
#   Environment setting script (e.g. admin-openrc.sh) available.
#   OpenStack clients installed e.g. via setup_osc.sh in the OPNFV Models repo.
#
# How to use:
#   Install Congress test server per https://wiki.opnfv.org/copper/academy
#   $ bash ~/git/copper/tests/adhoc/smoke01.sh <openrc>
#     <openrc>: path to your openrc script
#   After test, cleanup with
#   $ bash ~/git/copper/tests/adhoc/smoke01-clean.sh
#
# Status: this is a work in progress, under test. 

trap 'fail' ERR

pass() {
  log "Hooray!"
  set +x #echo off
  exit 0
}

# Use this to trigger fail() at the right places
# if [ "$RESULT" == "Test Failed!" ]; then fail; fi
fail() {
  log "$1"
  set +x
  exit 1
}

function log() {
  f=$(caller 0 | awk '{print $2}')
  l=$(caller 0 | awk '{print $1}')
  echo; echo "$f:$l ($(date)) $1"
}

unclean() {
  fail "Unclean environment!"
}

# Find external network if any, and details
function get_external_net () {
  networks=($(openstack network list | grep -v "+" | grep -v ID | awk '{print $4}'))
  for name in ${networks[@]}; do
    log "Checking network \"$name\""
    external=$(openstack network show ${name} | grep 'router:external' | grep -c "External")
    if [[ $external -eq 1 ]]; then 
      log "Found external network \"$name\"" 
      EXTERNAL_NETWORK_NAME=$name
      EXTERNAL_SUBNET_ID=$(openstack network show $name | awk "/ subnets / { print \$4 }")
      break
    fi
  done
  if [[ ! $EXTERNAL_NETWORK_NAME ]]; then 
    fail "External network not found"
  fi
}

function wait_active() {
  log "Wait for $1 to go ACTIVE"
  COUNTER=10
  status=""
  until [[ $COUNTER -eq 0  || "$status" == "ACTIVE" ]]; do
    status=$(openstack server show $1 | awk "/ status / { print \$4 }")
    COUNTER=$((COUNTER-1))
    sleep 5
  done
  if [[ "$status" != "ACTIVE" ]]; then 
    fail "Timeout on $1 becoming active"
  fi
}

function smoke01() {
  source $1

  if [[ -z $(openstack image list | awk "/ cirros-0.3.3-x86_64 / { print \$2 }") ]]; then
    log "Create cirros-0.3.3-x86_64 image"
    wget http://download.cirros-cloud.net/0.3.3/cirros-0.3.3-x86_64-disk.img \
      -O ~/cirros-0.3.3-x86_64-disk.img
    glance image-create --name cirros-0.3.3-x86_64 --disk-format qcow2 \
      --container-format bare
    image_id=$(openstack image list | awk "/ cirros-0.3.3-x86_64 / { print \$2 }")
    glance image-upload --file ~/cirros-0.3.3-x86_64-disk.img $image_id
  fi

  log "Find name and subnet of external network"
  get_external_net

  log "Create floating IP for external subnet"
  FLOATING_IP_ID=$(openstack floating ip create $EXTERNAL_NETWORK_NAME | awk "/ id / { print \$4 }")
  FLOATING_IP=$(openstack floating ip show $FLOATING_IP_ID | awk "/ floating_ip_address / { print \$4 }" | cut -d - -f 1)
  # Save ID to pass to cleanup script
  echo "FLOATING_IP_ID=$FLOATING_IP_ID" >/tmp/SMOKE01_VARS.sh

  if [[ -z $(openstack network list | awk "/ internal / { print \$2 }") ]]; then 
    log "Create internal network"
    openstack network create internal

    log "Create internal subnet"
    openstack subnet create --network internal --subnet-range 10.0.0.0/24 \
      --gateway 10.0.0.1 --dhcp --allocation-pool start=10.0.0.2,end=10.0.0.254 \
      --dns-nameserver 8.8.8.8 internal
  fi

  log "Get ID of internal network"
  internal_net=$(openstack network show internal | awk '/ id / {print $4}')

  if [[ -z $(openstack router list | awk "/ public_router / { print \$2 }") ]]; then 
    log "Create router"
    openstack router create public_router

    log "Create router gateway"
    openstack router set --external-gateway $EXTERNAL_NETWORK_NAME public_router

    log "Add router interface for internal network"
    openstack port create --network internal \
      --fixed-ip subnet=internal,ip-address=10.0.0.1 \
      public_router_internal_port
    openstack router add port public_router public_router_internal_port
  fi

  log "Create smoke01 security group"
  openstack security group create smoke01

  log "Add rule to smoke01 security group"
  openstack security group rule create --ingress --protocol=TCP \
    --remote-ip 0.0.0.0/0 --dst-port 22:22 smoke01
  openstack security group rule create --ingress --protocol=ICMP \
    --remote-ip 0.0.0.0/0 smoke01
  openstack security group rule create --egress --protocol=TCP \
    --remote-ip 0.0.0.0/0 --dst-port 22:22 smoke01
  openstack security group rule create --egress --protocol=ICMP \
    --remote-ip 0.0.0.0/0 smoke01

  log "Create Nova key pair"
  if [[ -f /tmp/smoke01 ]]; then rm /tmp/smoke01; fi
  ssh-keygen -t rsa -N "" -f /tmp/smoke01 -C smokem@ifyagotem
  chmod 600 /tmp/smoke01
  openstack keypair create --public-key /tmp/smoke01.pub smoke01

  log "Create Nova flavor"
  openstack flavor create --ram 512 --disk 1 --vcpus 1 smoke01.tiny

  log "Boot cirros1"
  openstack server create --config-drive True --flavor smoke01.tiny --image cirros-0.3.3-x86_64 --nic net-id=$internal_net --security-group smoke01 --key-name smoke01 cirros1
  wait_active cirros1
  # metadata is accessible by logging into cirros1 after floating IP assignment
  # ssh -i /tmp/smoke01 -x -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no cirros@$FLOATING_IP
  # from the local metadata service, via: curl http://169.254.169.254/latest/meta-data
  # from the config drive, via
  #    sudo mount /dev/sr0 /mnt/
  #    find /mnt/openstack/latest -name *.json -exec grep -H { {} + | sed -e 's/[{}]/''/g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}'

  log "Associate floating IP to cirros1"
  openstack server add floating ip cirros1 $FLOATING_IP

  log "Boot cirros2"
  openstack server create --config-drive True --flavor smoke01.tiny --image cirros-0.3.3-x86_64 --nic net-id=$internal_net --security-group smoke01 --key-name smoke01 cirros2
  wait_active cirros2

  log "Verify public network connectivity"
  RESULT=$(ssh -i /tmp/smoke01 -x -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no cirros@$FLOATING_IP "ping -c 3 8.8.8.8; exit" | awk "/ 0% packet loss/ { print \$1 }")
  if [[ "$RESULT" != "3" ]]; then
    fail "Could not verify inter-VM pings"
  fi
}

smoke01 $1
pass

