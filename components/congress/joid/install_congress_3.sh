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
# This is script 3 of 4 for installation of Congress on an Ubuntu 14.04 
# LXC container in the OPNFV Controller node.
# Prequisite: OPFNV install per https://wiki.opnfv.org/copper/academy/joid
#
# On jumphost:
# Download admin-openrc.sh from Horizon and save in ~
# source ~/git/copper/components/congress/joid/install_congress_1.sh
# (copies install_congress_2.sh to node1-control and executes it)
# Edit install_congress_3.sh with the congress host address from lxc_info
# - Congress server IP address as discovered in lxc-info above
# source ~/git/copper/components/congress/joid/install_congress_3.sh

cat <<EOF >~/env.sh
export CONGRESS_HOST=192.168.10.125
export KEYSTONE_HOST=$(juju status --format=short | awk "/keystone\/0/ { print \$3 }")
export CEILOMETER_HOST=$(juju status --format=short | awk "/ceilometer\/0/ { print \$3 }")
export CINDER_HOST=$(juju status --format=short | awk "/cinder\/0/ { print \$3 }")
export GLANCE_HOST=$(juju status --format=short | awk "/glance\/0/ { print \$3 }")
export NEUTRON_HOST=$(juju status --format=short | awk "/neutron-api\/0/ { print \$3 }")
export NOVA_HOST=$(juju status --format=short | awk "/nova-cloud-controller\/0/ { print \$3 }")
EOF
source ~/env.sh
juju scp ~/admin-openrc.sh ubuntu@$CONGRESS_HOST:/home/ubuntu
juju scp ~/env.sh ubuntu@$CONGRESS_HOST:/home/ubuntu
juju scp ~/git/copper/components/congress/joid/install_congress_4.sh ubuntu@$CONGRESS_HOST:/home/ubuntu
juju ssh ubuntu@$CONGRESS_HOST "~/install_congress_4.sh; exit"
