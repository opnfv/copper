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
# $ wget https://git.opnfv.org/cgit/copper/plain/components/congress/test-webapp/setup/install_congress_testserver.sh
# $ bash install_congress_testserver.sh [copper-branch]
#   optionally specifying the branch identifier to use for copper

set -x

if [ $# -eq 1 ]; then cubranch=$1; fi

echo "Install prerequisites"
dist=`grep DISTRIB_ID /etc/*-release | awk -F '=' '{print $2}'`

if [ ! -d /tmp/copper ]; then mkdir /tmp/copper; fi

if [ "$dist" == "Ubuntu" ]; then
  # Docker setup procedure from https://docs.docker.com/engine/installation/linux/ubuntulinux/
  echo "Install docker and prerequisites"
  sudo apt-get update
  sudo apt-get install -y apt-transport-https ca-certificates
  sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
  sudo tee /etc/apt/sources.list.d/docker.list <<- 'EOF'
deb https://apt.dockerproject.org/repo ubuntu-trusty main
EOF
  sudo apt-get update
  sudo apt-get purge lxc-docker
  apt-cache policy docker-engine
  sudo apt-get install -y linux-image-extra-$(uname -r)
  sudo apt-get install -y docker docker-engine
  echo "Copy copper environment files"
  cp ~/congress/env.sh /tmp/copper/
  cp ~/congress/admin-openrc.sh /tmp/copper/
else
  sudo tee /etc/yum.repos.d/docker.repo <<-'EOF'
[dockerrepo]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/centos/$releasever/
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg
EOF
  echo "Copy copper environment files" 
  sudo scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no stack@192.0.2.1:/home/stack/congress/*.sh /tmp/copper
fi

echo "Clone copper"
if [ ! -d /tmp/copper/copper ]; then 
  cd /tmp/copper
  git clone https://gerrit.opnfv.org/gerrit/copper
  cd copper
  if [ $# -eq 1 ]; then git checkout $1; fi 
else
  echo "/tmp/copper exists: run 'rm -rf /tmp/copper' to start clean if needed"
fi

sudo service docker start

echo "Setup copper environment"
source /tmp/copper/env.sh

echo "Setup webapp files"
if [ ! -d /tmp/copper/log ]; then 
  mkdir /tmp/copper/log
  chmod 777 /tmp/copper/log
fi
source /tmp/copper/env.sh
echo "Point proxy.php to the Congress server"
sed -i -- "s/CONGRESS_HOST/$CONGRESS_HOST/g" /tmp/copper/copper/components/congress/test-webapp/www/proxy/index.php

echo "Start webapp container"
sudo docker build -t copper-webapp /tmp/copper/copper/components/congress/test-webapp/
CID=$(sudo docker run -v /tmp/copper/log:/tmp -p 8080:80 -d copper-webapp)
CIP=$(sudo docker inspect $CID | grep IPAddress | cut -d '"' -f 4 | tail -1)
echo "Copper Webapp IP address: $CIP"

set +x
