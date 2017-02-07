#!/bin/bash
# CCopyright 2015-2016 AT&T Intellectual Property, Inc
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
# This is a cleanup script for installation of Congress on the OPNFV Controller
# node as installed via JOID or Apex (Fuel and Compass not yet verified).
# Presumably something has failed, and any record of the Congress feature
# in OpenStack needs to be removed, so you can try the install again.
# This is script 2 of 2 for installation of OpenStack Congress.
# Prerequisites: 
# - OpenStack base deployment.
# Usage:
# $ bash clean_congress.sh <target> <user>
#   <target>: IP/hostname where Congress is being installed
#             localhost: install in a docker container on the current host
#             IP address: install in a virtualenv
#   <user>: IP/hostname where Congress is being installed
# 
target=$1
user=$2

source /opt/congress/admin-openrc.sh
source /opt/congress/venv/bin/activate

if [[ "$target" == "localhost" ]]; then
  sudo docker stop congress
  sudo docker rm -v congress
else
  echo "Remove systemd integration"
  ssh -x -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $user@$target "sudo rm -f /usr/lib/systemd/system/openstack-congress.service; sudo rm -f /etc/init.d/congress-server; exit"

  echo "Remove the Congress virtualenv and code"
  ssh -x -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $user@$target "rm -rf /opt/congress; exit"

  echo "Delete Congress database"
  ssh -x -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $user@$target "sudo mysql -e \"DROP DATABASE congress\"; exit"
fi

echo "Delete Congress user"
openstack user delete congress

echo "Delete Congress service"
openstack service delete congress

echo "Delete Congress and other installed code in virtualenv"
sudo rm -rf /opt/congress

