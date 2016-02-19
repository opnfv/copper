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

# This is a cleanup script for installation of the Congress testserver
# on an Ubuntu 14.04 LXC container in the jumphost.
# Presumably something has failed, and any record of the testserver
# needs to be removed, so you can try the install again.

source ~/admin-openrc.sh <<EOF
openstack
EOF
source ~/env.sh
set -x
sudo lxc-stop --name trusty-copper
sudo lxc-destroy --name trusty-copper
rm -rf ~/coppertest
set +x
