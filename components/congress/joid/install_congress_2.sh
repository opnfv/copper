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
# This is script 2 of 5 for installation of Congress on an Ubuntu 14.04 
# LXC container in the OPNFV Controller node.
# Prequisite: OPFNV install per https://wiki.opnfv.org/copper/academy/joid
#
# On jumphost:
# Download admin-openrc.sh from Horizon and save in ~
# source ~/git/copper/components/congress/joid/install_congress_1.sh
# (copies install_congress_2.sh to node1-control and executes it)

set -x #echo on
sudo lxc-clone -o juju-trusty-lxc-template -n juju-trusty-congress
sudo lxc-start -n juju-trusty-congress -d
sleep 10
sudo lxc-info -n juju-trusty-congress
set -x #echo off
