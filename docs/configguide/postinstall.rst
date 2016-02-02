Copper post installation procedures
===================================
This release focused on use of the OpenStack Congress service for managing
configuration policy. The Congress install verify procedure described here
is largely manual. This procedure, as well as the longer-term goal of
automated verification support, is a work in progress. The procedure is
further specific to one OPNFV installer (JOID, i.e. MAAS/JuJu) based
environment.

Automated post installation activities
--------------------------------------
No automated procedures are provided at this time.

Copper post configuration procedures
------------------------------------
No configuration procedures are required beyond the basic install procedure.

Platform components validation
------------------------------

Following are notes on creating a container as test driver for Congress.
This is based upon an Ubuntu host as installed by JOID.

Create and Activate the Container
.................................
On the jumphost:

.. code::

  sudo lxc-create -n trusty-copper -t /usr/share/lxc/templates/lxc-ubuntu \
  -- -b ubuntu ~/opnfv
  sudo lxc-start -n trusty-copper -d
  sudo lxc-info --name trusty-copper
  (typical output)
  Name:           trusty-copper
  State:          RUNNING
  PID:            4563
  IP:             10.0.3.44
  CPU use:        28.77 seconds
  BlkIO use:      522.79 MiB
  Memory use:     559.75 MiB
  KMem use:       0 bytes
  Link:           vethDMFOAN
   TX bytes:      2.62 MiB
   RX bytes:      88.48 MiB
   Total bytes:   91.10 MiB

Login and configure the test server
...................................

.. code::

  ssh ubuntu@10.0.3.44
  sudo apt-get update
  sudo apt-get upgrade -y

  # Install pip
  sudo apt-get install python-pip -y

  # Install java
  sudo apt-get install default-jre -y

  # Install other dependencies
  sudo apt-get install git gcc python-dev libxml2 libxslt1-dev \
  libzip-dev php5-curl -y

  # Setup OpenStack environment variables per your OPNFV install
  export CONGRESS_HOST=192.168.10.117
  export KEYSTONE_HOST=192.168.10.108
  export CEILOMETER_HOST=192.168.10.105
  export CINDER_HOST=192.168.10.101
  export GLANCE_HOST=192.168.10.106
  export HEAT_HOST=192.168.10.107
  export NEUTRON_HOST=192.168.10.111
  export NOVA_HOST=192.168.10.112
  source ~/admin-openrc.sh

  # Install and test OpenStack client
  mkdir ~/git
  cd git
  git clone https://github.com/openstack/python-openstackclient.git
  cd python-openstackclient
  git checkout stable/liberty
  sudo pip install -r requirements.txt
  sudo python setup.py install
  openstack service list
  (typical output)
  +----------------------------------+------------+----------------+
  | ID                               | Name       | Type           |
  +----------------------------------+------------+----------------+
  | 2f8799ae50f24c928c021fabf8a50f5f | keystone   | identity       |
  | 351b13f56d9a4e25849406ec1d5a2726 | cinder     | volume         |
  | 5129510c3143454f9ba8ec7e6735e267 | cinderv2   | volumev2       |
  | 5ee1e220460f41dea9be06921400ce9b | congress   | policy         |
  | 78e73a7789a14f56a5d248a0cd141201 | quantum    | network        |
  | 9d5a00fb475a45b2ae6767528299ed6b | ceilometer | metering       |
  | 9e4b1624ef0b434abc0b82f607c5045c | heat       | orchestration  |
  | b6c01ceb5023442d9f394b83f2a18e01 | heat-cfn   | cloudformation |
  | ba6199e3505045ad87e2a7175bd0c57f | glance     | image          |
  | d753f304a0d541dbb989780ae70328a8 | nova       | compute        |
  +----------------------------------+------------+----------------+

  # Install and test Congress client
  cd ~/git
  git clone https://github.com/openstack/python-congressclient.git
  cd python-congressclient
  git checkout stable/liberty
  sudo pip install -r requirements.txt
  sudo python setup.py install
  openstack congress driver list
  (typical output)
  +------------+--------------------------------------------------------------------------+
  | id         | description                                                              |
  +------------+--------------------------------------------------------------------------+
  | ceilometer | Datasource driver that interfaces with ceilometer.                       |
  | neutronv2  | Datasource driver that interfaces with OpenStack Networking aka Neutron. |
  | nova       | Datasource driver that interfaces with OpenStack Compute aka nova.       |
  | keystone   | Datasource driver that interfaces with keystone.                         |
  | cinder     | Datasource driver that interfaces with OpenStack cinder.                 |
  | glancev2   | Datasource driver that interfaces with OpenStack Images aka Glance.      |
  +------------+--------------------------------------------------------------------------+

  # Install and test Glance client
  cd ~/git
  git clone https://github.com/openstack/python-glanceclient.git
  cd python-glanceclient
  git checkout stable/liberty
  sudo pip install -r requirements.txt
  sudo python setup.py install
  glance image-list
  (typical output)
  +--------------------------------------+---------------------+
  | ID                                   | Name                |
  +--------------------------------------+---------------------+
  | 6ce4433e-65c0-4cd8-958d-b06e30c76241 | cirros-0.3.3-x86_64 |
  +--------------------------------------+---------------------+

  # Install and test Neutron client
  cd ~/git
  git clone https://github.com/openstack/python-neutronclient.git
  cd python-neutronclient
  git checkout stable/liberty
  sudo pip install -r requirements.txt
  sudo python setup.py install
  neutron net-list
  (typical output)
  +--------------------------------------+----------+------------------------------------------------------+
  | id                                   | name     | subnets                                              |
  +--------------------------------------+----------+------------------------------------------------------+
  | dc6227df-af41-439f-bd2c-c2c2f0fe7fc5 | public   | 5745846c-dd79-4900-a7da-bf506348ceac 192.168.10.0/24 |
  | a3f9f13a-5de9-4d3b-98c8-d2e40a2ef8e9 | internal | 5e0be862-90da-44ab-af43-56d5c65aa049 10.0.0.0/24     |
  +--------------------------------------+----------+------------------------------------------------------+

  # Install and test Nova client
  cd ~/git
  git clone https://github.com/openstack/python-novaclient.git
  cd python-novaclient
  git checkout stable/liberty
  sudo pip install -r requirements.txt
  sudo python setup.py install
  nova hypervisor-list
  (typical output)
  +----+---------------------+-------+---------+
  | ID | Hypervisor hostname | State | Status  |
  +----+---------------------+-------+---------+
  | 1  | compute1.maas       | up    | enabled |
  +----+---------------------+-------+---------+

  # Install and test Keystone client
  cd ~/git
  git clone https://github.com/openstack/python-keystoneclient.git
  cd python-keystoneclient
  git checkout stable/liberty
  sudo pip install -r requirements.txt
  sudo python setup.py install

Setup the Congress Test Webapp
..............................

.. code::

  # Clone Copper (if not already cloned in user home)
  cd ~/git
  if [ ! -d ~/git/copper ]; then \
  git clone https://gerrit.opnfv.org/gerrit/copper; fi

  # Copy the Apache config
  sudo cp ~/git/copper/components/congress/test-webapp/www/ubuntu-apache2.conf \
  /etc/apache2/apache2.conf

  # Point proxy.php to the Congress server per your install
  sed -i -- "s/192.168.10.117/$CONGRESS_HOST/g" \
  ~/git/copper/components/congress/test-webapp/www/html/proxy/index.php

  # Copy the webapp to the Apache root directory and fix permissions
  sudo cp -R ~/git/copper/components/congress/test-webapp/www/html /var/www
  sudo chmod 755 /var/www/html -R

  # Make webapp log directory and set permissions
  mkdir ~/logs
  chmod 777 ~/logs

  # Restart Apache
  sudo service apache2 restart

Using the Test Webapp
.....................
Browse to the trusty-copper server IP address.

Interactive options are meant to be self-explanatory given a basic familiarity with the Congress service and data model. But the app will be developed with additional features and UI elements.
