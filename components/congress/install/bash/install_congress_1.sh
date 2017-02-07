#!/bin/bash
# Copyright 2015-2017 AT&T Intellectual Property, Inc
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
# This is script 1 of 2 for installation of OpenStack Congress. This install 
# procedure is intended to deploy Congress for testing purposes only.
# Prerequisites: 
# - OpenStack base deployment.
# Usage:
# $ bash install_congress_1.sh <openrc> <target> [branch]
#   <openrc>: location of OpenStack openrc file
#   <target>: "localhost" or IP/hostname of the target
#             for localhost, installs congress in a docker container
#   branch: branch identifier to use for OpenStack
#     

trap 'fail' ERR

pass() {
  echo "$0: $(date) Install Succeeded!"
  exit 0
}

fail() {
  echo "$0: $(date) Install Failed!"
  exit 1
}

function create_container () {
  echo "$0: $(date) Setup container"
  if [ "$dist" == "Ubuntu" ]; then
    echo "$0: $(date) install docker-engine"
    sudo apt-get update
    sudo apt-get install curl linux-image-extra-$(uname -r) linux-image-extra-virtual
    sudo apt-get install apt-transport-https ca-certificates
    curl -fsSL https://yum.dockerproject.org/gpg | sudo apt-key add -
    sudo add-apt-repository "deb https://apt.dockerproject.org/repo/  ubuntu-$(lsb_release -cs) \       main"
    sudo apt-get update
    sudo apt-get -y install docker-engine
    # xenial is needed for python 3.5
    sudo docker pull ubuntu:xenial
    sudo service docker start
    echo "$0: $(date) start the congress container"
    sudo docker run -it -d -v /opt/congress/:/opt/congress/ --name congress ubuntu:xenial /bin/bash
  else 
    # Centos
    sudo tee /etc/yum.repos.d/docker.repo <<-'EOF'
[dockerrepo]
name=Docker Repository--parents 
baseurl=https://yum.dockerproject.org/repo/main/centos/7/
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg 
EOF
    sudo yum install -y docker-engine
    # xenial is needed for python 3.5
    sudo service docker start
    sudo docker pull ubuntu:xenial
    echo "$0: $(date) start the congress container"
    sudo docker run -i -t -d -v /opt/congress/:/opt/congress/ --name congress ubuntu:xenial /bin/bash
  fi
}

install_client () {
  echo "$0: $(date) Install $1"
  git clone https://github.com/openstack/$1.git
  cd $1
  if [ $# -eq 2 ]; then git checkout $2; fi
  pip install .
  cd ..
}

openrc=$1
target=$2
if [ $# -eq 3 ]; then branch=$3; fi

echo "$0: $(date) create shared folder /opt/congress"
if [ -d /opt/congress ]; then sudo rm -rf /opt/congress; fi
sudo mkdir /opt/congress
sudo chown $USER /opt/congress
cp $openrc /opt/congress/admin-openrc.sh
cp `dirname $0`/install_congress_2.sh /opt/congress/.
cp `dirname $0`/congress.conf.sample /opt/congress/.

echo "$0: $(date) setup OpenStack CLI environment"
source $openrc

echo "$0: $(date) OS-specific prerequisite steps"
dist=`grep DISTRIB_ID /etc/*-release | awk -F '=' '{print $2}'`

if [[ "$dist" == "Ubuntu" ]]; then
  echo "$0: $(date) Ubuntu-based install"
  CTLUSER="ubuntu"
  echo "$0: $(date) Install jumphost dependencies"
  echo "$0: $(date) install pip"
  sudo apt-get install -y python-pip
  echo "$0: $(date) install other dependencies"
  sudo apt-get install apg git gcc python-dev libxml2 libxslt1-dev libzip-dev -y
else 
  echo "$0: $(date) Centos-based install"
  CTLUSER="heat-admin"
  echo "$0: $(date) Install jumphost dependencies"
  echo "$0: $(date) install pip"
  sudo yum install python-pip -y
  echo "$0: $(date) install other dependencies"
  sudo yum install apg git gcc libxml2 python-devel libzip-devel libxslt-devel -y
fi

if [[ "$target" == "localhost" ]]; then
  create_container
  target=$(sudo docker inspect congress | grep IPAddress | cut -d '"' -f 4 | tail -1)
  sudo docker exec congress /bin/bash /opt/congress/install_congress_2.sh $target $branch
  if [ $? -eq 1 ]; then fail; fi
else
  echo "$0: $(date) Copy $0 to the congress server"
  ssh -x -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $CTLUSER@$target "mkdir ~/congress; exit"
  scp $openrc $CTLUSER@$target:/home/$CTLUSER/congress
  echo "$0: $(date) Copy install_congress_2.sh to the congress server and execute"
  scp `dirname $0`/install_congress_2.sh $CTLUSER@$target:/home/ubuntu/congress
  ssh -x -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $CTLUSER@$target "source ~/congress/install_congress_2.sh $target $branch; exit"
  if [ $? -eq 1 ]; then fail; fi
fi

sudo pip install --upgrade pip virtualenv setuptools pbr tox

echo "Create virtualenv"
virtualenv /opt/congress/venv
source /opt/congress/venv/bin/activate

echo "$0: $(date) Install OpenStack clients"
cd /opt/congress/
install_client python-openstackclient $branch
install_client python-neutronclient $branch
install_client python-congressclient $branch

echo "$0: $(date) setup Congress user. TODO: needs update in http://congress.readthedocs.org/en/latest/readme.html#installing-congress"
pip install cliff --upgrade
export ADMIN_ROLE=$(openstack role list | awk "/ admin / { print \$2 }")
export SERVICE_TENANT=$(openstack project list | awk "/ admin / { print \$2 }")
openstack user create --password congress --project admin --email "congress@example.com" congress
export CONGRESS_USER=$(openstack user list | awk "/ congress / { print \$2 }")
openstack role add --user $CONGRESS_USER --project $SERVICE_TENANT $ADMIN_ROLE 

echo "$0: $(date) Create Congress service"
openstack service create congress --type "policy" --description "Congress Service"
export CONGRESS_SERVICE=$(openstack service list | awk "/ congress / { print \$2 }")

echo "$0: $(date) Create Congress endpoint"
openstack endpoint create congress \
  --region $OS_REGION_NAME \
  --publicurl http://$target:1789/ \
  --adminurl http://$target:1789/ \
  --internalurl http://$target:1789/

echo "$0: $(date) Start the Congress service"
if [[ ! -z $(sudo docker inspect congress | grep IPAddress | cut -d '"' -f 4 | tail -1) ]]; then
  sudo docker exec congress /opt/congress/congress/bin/congress-server &>/dev/null &
  disown
else
  ssh -x -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $CTLUSER@$target "/opt/congress/congress/bin/congress-server &>/dev/null &"
fi

echo "$0: $(date) Wait 30 seconds for Congress service to startup"
sleep 30

echo "$0: $(date) Create data sources"
# To remove datasources: openstack congress datasource delete <name> 
openstack congress datasource create nova "nova" \
  --config username=$OS_USERNAME \
  --config tenant_name=$OS_TENANT_NAME \
  --config password=$OS_PASSWORD \
  --config auth_url=$OS_AUTH_URL
openstack congress datasource create neutronv2 "neutronv2" \
  --config username=$OS_USERNAME \
  --config tenant_name=$OS_TENANT_NAME \
  --config password=$OS_PASSWORD \
  --config auth_url=$OS_AUTH_URL
openstack congress datasource create ceilometer "ceilometer" \
  --config username=$OS_USERNAME \
  --config tenant_name=$OS_TENANT_NAME \
  --config password=$OS_PASSWORD \
  --config auth_url=$OS_AUTH_URL
openstack congress datasource create cinder "cinder" \
  --config username=$OS_USERNAME \
  --config tenant_name=$OS_TENANT_NAME \
  --config password=$OS_PASSWORD \
  --config auth_url=$OS_AUTH_URL
openstack congress datasource create glancev2 "glancev2" \
  --config username=$OS_USERNAME \
  --config tenant_name=$OS_TENANT_NAME \
  --config password=$OS_PASSWORD \
  --config auth_url=$OS_AUTH_URL
openstack congress datasource create keystone "keystone" \
  --config username=$OS_USERNAME \
  --config tenant_name=$OS_TENANT_NAME \
  --config password=$OS_PASSWORD \
  --config auth_url=$OS_AUTH_URL
openstack congress datasource create keystone "heat" \
  --config username=$OS_USERNAME \
  --config tenant_name=$OS_TENANT_NAME \
  --config password=$OS_PASSWORD \
  --config auth_url=$OS_AUTH_URL

echo "$0: $(date) Install tox test dependencies"
if [ "$dist" == "Ubuntu" ]; then
  sudo apt-get install -y libffi-dev libssl-dev
else
  sudo yum install -y libffi-devel openssl-devel
fi

echo "$0: $(date) Run Congress tox Tests"
cd /opt/congress/congress
sudo tox -epy27

set +x #echo off
