# Copyright 2015 Open Platform for NFV Project, Inc. and its contributors
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

# This file contains instructions for installation and use of the Copper
# project adhoc test driver for OpenStack Congress.

#
# For Ubuntu
#
# install dependencies
sudo apt-get install lamp-server^ -y
# when prompted, set mysql root user password to "ubuntu"
sudo apt-get install php5-curl

# get Copper test driver app
cd ~
git clone https://gerrit.opnfv.org/gerrit/copper
sudo cp ~copper/components/congress/test-webapp/www/ubuntu-apache2.conf /etc/apache2/apache2.conf
sudo cp -R ~copper/components/congress/test-webapp/www/html /var/www
sudo chmod 755 /var/www/html -R
sudo service apache2 restart

# Using the app: Browse to http://localhost
# Interactive options are meant to be self-explanatory given a basic
# familiarity with the Congress service and data model. 
