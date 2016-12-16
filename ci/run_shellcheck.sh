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

echo "--------------------------------------------------------"
echo "This is the Copper shellcheck job"
echo "--------------------------------------------------------"

# this script lives in copper/ci so move to tests directory
cd ../tests

# invoke shellcheck on all scripts in tests directory
# output to tty (human readable text) or checkstyle (xml)
shellcheck -f tty ./*.sh

echo
echo "--------------------------------------------------------"
echo "Done!"
