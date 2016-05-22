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
# What this is: Installer for an OpenStack API test environment for Congress.
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
# $ wget https://git.opnfv.org/cgit/copper/plain/components/congress/test-webapp/setup/install_congress_cli_test_environment.sh
# $ source install_congress_cli_test_environment.sh [copper-branch]
#   optionally specifying the branch identifier to use for copper

set -x

if [ $# -eq 1 ]; then cubranch=$1; fi

echo "Copy environment files to /tmp/copper"
if [ ! -d /tmp/copper ]; then mkdir /tmp/copper; fi
dist=`grep DISTRIB_ID /etc/*-release | awk -F '=' '{print $2}'`
if [ "$dist" == "Ubuntu" ]; then
  cp ~/congress/env.sh /tmp/copper/
  cp ~/congress/admin-openrc.sh /tmp/copper/
else
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

cd /tmp/copper/copper/tests
ls

echo "You can run tests individually, or as a collection with run.sh"

set +x

