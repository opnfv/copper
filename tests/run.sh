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
# - Congress installed through OPNFV installer or install_congress_1.sh
# - OpenStack CLI clients installed 
#   python-openstackclient
#   python-congressclient
#   python-keystoneclient
#   python-glanceclient
#   python-neutronclient
#   python-novaclient
# How to use:
#   $ bash run.sh
#

if [ $# -eq 1 ]; then cd $1; fi

start=`date +%s`
tests="dmz smtp_ingress reserved_subnet"
overall_result=0

n=0
for test in $tests; do
  echo "============"
  echo "Test: $test.sh"
  echo "============"
  bash $test.sh  
	result=$?
	n+=1
  if (($result == 0)); then test_result[$n]="Passed"
  else 
	  test_result[$n]="Failed"
		overall_result=1
	fi
  bash $test-clean.sh
done

end=`date +%s`
runtime=$((end-start))
runtime=$((runtime/60))
echo "======================"
echo "Test Execution Summary"
echo "======================"
echo "Test Duration = $runtime minutes"
n=0
for test in $tests; do
	n+=1
  echo "${test_result[$n]} : $test"
done
if (($overall_result == 0)); then echo "Test run overall: PASSED";
else echo "Test run overall: FAILED"
fi
exit $overall_result
