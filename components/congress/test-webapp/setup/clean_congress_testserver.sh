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
# This is a cleanup script for installation of the Congress testserver
# as installed under JOID or Apex (Fuel and Compass not yet verified).
# Prequisite: OPFNV installed per JOID or Apex installer
# On jumphost:
# - Congress installed through install_congress_1.sh
# How to use:
#   Retrieve the testserver uninstall script as below
# $ wget https://git.opnfv.org/cgit/copper/plain/components/congress/test-webapp/setup/clean_congress_testserver.sh
# $ bash clean_congress_testserver.sh
set -x
echo "Get copper-webapp container ID"
CID=$(sudo docker ps | awk "/copper-webapp/ { print \$1 }")
echo "Stop copper-webapp container"
sudo docker stop $CID
echo "Remove copper-webapp container"
sudo docker rm $CID
# Use this if the server is not running
# docker rm `docker ps -aq`
set +x
