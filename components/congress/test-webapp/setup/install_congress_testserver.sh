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
# What this is: script 1 of 2 for installation of a test server for Congress.
# Status: this is a work in progress, under test.
#
# Prequisite: OPFNV installed per JOID or Apex installer
# On jumphost:
# - Congress installed through install_congress_1.sh
# - admin-openrc.sh downloaded from Horizon
# - env.sh and admin-openrc.sh in the current folder
# How to use:
#   Retrieve the copper install script as below, optionally specifying the 
#   branch to use as a URL parameter, e.g. ?h=stable%2Fbrahmaputra
# $ wget https://git.opnfv.org/cgit/copper/tree/components/congress/test-webapp/setup/install_congress_testserver.sh
# $ source install_congress_testserver.sh [copper-branch]
#   optionally specifying the branch identifier to use for copper

set -x

if [ $# -eq 1 ]; then cubranch=$1; fi

echo "Install prerequisites"
dist=`grep DISTRIB_ID /etc/*-release | awk -F '=' '{print $2}'`

if [ "$dist" == "Ubuntu" ]; then
  sudo apt-get install -y docker
  cp env.sh /tmp/copper/
  cp admin-openrc.sh /tmp/copper/
else
  sudo tee /etc/yum.repos.d/docker.repo <<-'EOF'
[dockerrepo]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/centos/$releasever/
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg
EOF
  sudo scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no stack@192.0.2.1:/home/stack/congress/*.sh /tmp/copper
fi

echo "Clone copper"
if [ ! -d /tmp/copper ]; then mkdir /tmp/copper; fi
cd /tmp/copper
if [ -d copper ]; then rm -rf copper 
git clone https://gerrit.opnfv.org/gerrit/copper; fi
cd copper
if [ $# -eq 1 ]; then git checkout $1; fi

sudo service docker start

echo "Setup webapp files"
if [ ! -d /tmp/copper/log ]; then mkdir /tmp/copper/log; fi
source /tmp/copper/env.sh
echo "Point proxy.php to the Congress server"
sed -i -- "s/CONGRESS_HOST/$CONGRESS_HOST/g" /tmp/copper/copper/components/congress/test-webapp/www/proxy/index.php

echo "Start webapp container"
sudo docker build -t copper-webapp /tmp/copper/copper/components/congress/test-webapp/
CID=$(sudo docker run -p 8080:80 -d copper-webapp)
CIP=$(sudo docker inspect $CID | grep IPAddress | cut -d '"' -f 4 | tail -1)
echo "Copper Webapp IP address: $CIP"

set +x

