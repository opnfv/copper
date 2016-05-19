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
# What this is: function test driver for the OPNFV Copper project.
# Status: this is a work in progress, under test.
# Prequisite: 
# - OPFNV installed per JOID or Apex installer
# On jumphost:
# - Congress installed through install_congress_1.sh
# - Copper test environment installed per 
# How to use:
#   $ source install_congress_testserver_1.sh
#

echo "============"
echo "Test: dmz.sh"
echo "============"
sh dmz.sh
sh dmz-clean.sh

echo "========================"
echo "Test: reserved_subnet.sh"
echo "========================"
sh reserved_subnet.sh
sh reserved_subnet-clean.sh

echo "====================="
echo "Test: smtp_ingress.sh"
echo "====================="
sh smtp_ingress.sh
sh smtp_ingress-clean.sh

