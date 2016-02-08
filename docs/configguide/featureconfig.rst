Copper configuration
====================
This release focused on use of the OpenStack Congress service for managing
configuration policy. The Congress install procedure described here is largely
manual. This procedure, as well as the longer-term goal of automated installer
support, is a work in progress. The procedure is further specific to one OPNFV
installer (JOID, i.e. MAAS/JuJu) based environment. Support for other OPNFV
installer deployed environments is also a work in progress.

Pre-configuration activities
----------------------------
This procedure assumes OPNFV has been installed via the JOID installer.

Hardware configuration
----------------------
There is no specific hardware configuration required for the Copper project.

Feature configuration
---------------------
Following are instructions for installing Congress on an Ubuntu 14.04 LXC
container in the OPNFV Controller node, as installed by the JOID installer.
This guide uses instructions from the `Congress intro guide on readthedocs <http://congress.readthedocs.org/en/latest/readme.html#installing-congress|Congress>`_.
Specific values below will need to be modified if you intend to repeat this
procedure in your JOID-based install environment.

Install base VM for congress on controller node
...............................................

.. code::

  sudo juju ssh ubuntu@192.168.10.21

Clone the container
...................

.. code::

  sudo lxc-clone -o juju-trusty-lxc-template -n juju-trusty-congress

Start the container
...................

.. code::

  sudo lxc-start -n juju-trusty-congress -d

Get the container IP address
............................

.. code::

  sudo lxc-info -n juju-trusty-congress

If you need to start over
.........................

.. code::

  sudo lxc-destroy --name juju-trusty-congress

Exit from controller (back to jumphost) and login to congress container
.......................................................................

.. code::

  sudo juju ssh ubuntu@192.168.10.117

Update package repos
....................

.. code::

  sudo apt-get update

Setup environment variables
...........................

.. code::

  export CONGRESS_HOST=192.168.10.106
  export KEYSTONE_HOST=192.168.10.119
  export CEILOMETER_HOST=192.168.10.116
  export CINDER_HOST=192.168.10.117
  export GLANCE_HOST=192.168.10.118
  export NEUTRON_HOST=192.168.10.125
  export NOVA_HOST=192.168.10.121

Install pip
...........

.. code::

  sudo apt-get install python-pip -y

Install java
............

.. code::

  sudo apt-get install default-jre -y

Install other dependencies
..........................

.. code::

  # when prompted, set and remember mysql root user password
  sudo apt-get install git gcc python-dev libxml2 libxslt1-dev libzip-dev \
  mysql-server python-mysqldb -y
  sudo pip install virtualenv

Clone congress
..............

.. code::

  git clone https://github.com/openstack/congress.git
  cd congress
  git checkout stable/liberty

Create virtualenv
.................

.. code::

  virtualenv ~/congress
  source bin/activate

Setup Congress
..............

.. code::

  sudo mkdir -p /etc/congress
  sudo mkdir -p /etc/congress/snapshot
  sudo mkdir /var/log/congress
  sudo chown ubuntu /var/log/congress
  sudo cp etc/api-paste.ini /etc/congress
  sudo cp etc/policy.json /etc/congress

Install requirements.txt and tox dependencies
.............................................

The need for this stepo was detected by errors during "tox -egenconfig".

.. code::

  sudo apt-get install libffi-dev -y
  sudo apt-get install openssl -y
  sudo apt-get install libssl-dev -y

Install dependencies in virtualenv
..................................

.. code::

  pip install -r requirements.txt
  python setup.py install

Install tox
...........

.. code::

  pip install tox

Generate congress.conf.sample
.............................

.. code::

  tox -egenconfig

Edit congress.conf.sample as needed
...................................

.. code::

  sed -i -- 's/#verbose = true/verbose = true/g' etc/congress.conf.sample
  sed -i -- 's/#log_file = <None>/log_file = congress.log/g' \
  etc/congress.conf.sample
  sed -i -- 's/#log_dir = <None>/log_dir = \/var\/log\/congress/g' \
  etc/congress.conf.sample
  sed -i -- 's/#bind_host = 0.0.0.0/bind_host = 192.168.10.117/g' \
  etc/congress.conf.sample
  sed -i -- 's/#policy_path = <None>/policy_path = \
  \/etc\/congress\/snapshot/g' etc/congress.conf.sample
  sed -i -- 's/#auth_strategy = keystone/auth_strategy = noauth/g' \
  etc/congress.conf.sample
  sed -i -- 's/#drivers =/drivers =\
  congress.datasources.neutronv2_driver.NeutronV2Driver,\
  congress.datasources.glancev2_driver.GlanceV2Driver,\
  congress.datasources.nova_driver.NovaDriver,\
  congress.datasources.keystone_driver.KeystoneDriver,\
  congress.datasources.ceilometer_driver.CeilometerDriver,\
  congress.datasources.cinder_driver.CinderDriver/g' etc/congress.conf.sample
  sed -i -- 's/#auth_host = 127.0.0.1/auth_host = 192.168.10.108/g' \
  etc/congress.conf.sample
  sed -i -- 's/#auth_port = 35357/auth_port = 35357/g' etc/congress.conf.sample
  sed -i -- 's/#auth_protocol = https/auth_protocol = http/g' \
  etc/congress.conf.sample
  sed -i -- 's/#admin_tenant_name = admin/admin_tenant_name = admin/g' \
  etc/congress.conf.sample
  sed -i -- 's/#admin_user = <None>/admin_user = congress/g' \
  etc/congress.conf.sample
  sed -i -- 's/#admin_password = <None>/admin_password = congress/g' \
  etc/congress.conf.sample
  sed -i -- 's/#connection = <None>/connection = mysql:\/\/ubuntu:\
  <mysql password>@localhost:3306\/congress/g' etc/congress.conf.sample

Copy congress.conf.sample to /etc/congress
..........................................

.. code::

  sudo cp etc/congress.conf.sample /etc/congress/congress.conf

Create congress database
........................

.. code::

  sudo mysql -u root -p
  CREATE DATABASE congress;
  GRANT ALL PRIVILEGES ON congress.* TO 'ubuntu'@'localhost' \
  IDENTIFIED BY '<mysql password>';
  GRANT ALL PRIVILEGES ON congress.* TO 'ubuntu'@'%' IDENTIFIED \
  BY '<mysql password>';
  exit

Install congress-db-manage dependencies
.......................................

The need for this step was detected by errors in subsequent steps.

.. code::

  sudo apt-get build-dep python-mysqldb -y
  pip install MySQL-python

Create database schema
......................

.. code::

  congress-db-manage --config-file /etc/congress/congress.conf upgrade head

Install dependencies of OpenStack, Congress, Keystone client operations
.......................................................................

.. code::

  pip install python-openstackclient
  pip install python-congressclient
  pip install python-keystoneclient

Execute admin-openrc.sh as downloaded from Horizon
..................................................

.. code::

  source ~/admin-openrc.sh

Setup Congress user
...................

TODO: needs update in `Congress intro in readthedocs < http://congress.readthedocs.org/en/latest/readme.html#installing-congress>`_.

.. code::

  pip install cliff --upgrade
  export ADMIN_ROLE=$(openstack role list | \
  awk "/ Admin / { print \$2 }")
  export SERVICE_TENANT=$(openstack project list | \
  awk "/ admin / { print \$2 }")
  openstack user create --password congress --project admin \
  --email "congress@example.com" congress
  export CONGRESS_USER=$(openstack user list | \
  awk "/ congress / { print \$2 }")
  openstack role add $ADMIN_ROLE --user $CONGRESS_USER \
  --project $SERVICE_TENANT

Create Congress service
.......................

.. code::

  openstack service create congress --type "policy" \
  --description "Congress Service"
  export CONGRESS_SERVICE=$(openstack service list | \
  awk "/ congress / { print \$2 }")

Create Congress endpoint
........................

.. code::

  openstack endpoint create $CONGRESS_SERVICE \
  --region $OS_REGION_NAME \
  --publicurl http://$CONGRESS_HOST:1789/ \
  --adminurl http://$CONGRESS_HOST:1789/ \
  --internalurl http://$CONGRESS_HOST:1789/

Start the Congress service in the background
............................................

.. code::

  bin/congress-server &
  # disown the process (so it keeps running if you get disconnected)
  disown -h %1

Create data sources
...................

To remove datasources: openstack congress datasource delete <name>

It's probably good to do these commands in a new terminal tab, as the
congress server log from the last command will be flooding your original
terminal screen.

.. code::

  openstack congress datasource create nova "nova" \
  --config username=$OS_USERNAME \
  --config tenant_name=$OS_TENANT_NAME \
  --config password=$OS_PASSWORD \
  --config auth_url=http://$KEYSTONE_HOST:5000/v2.0
  openstack congress datasource create neutronv2 "neutronv2" \
  --config username=$OS_USERNAME \
  --config tenant_name=$OS_TENANT_NAME \
  --config password=$OS_PASSWORD \
  --config auth_url=http://$KEYSTONE_HOST:5000/v2.0
  openstack congress datasource create ceilometer "ceilometer" \
  --config username=$OS_USERNAME \
  --config tenant_name=$OS_TENANT_NAME \
  --config password=$OS_PASSWORD \
  --config auth_url=http://$KEYSTONE_HOST:5000/v2.0
  openstack congress datasource create cinder "cinder" \
  --config username=$OS_USERNAME \
  --config tenant_name=$OS_TENANT_NAME \
  --config password=$OS_PASSWORD \
  --config auth_url=http://$KEYSTONE_HOST:5000/v2.0
  openstack congress datasource create glancev2 "glancev2" \
  --config username=$OS_USERNAME \
  --config tenant_name=$OS_TENANT_NAME \
  --config password=$OS_PASSWORD \
  --config auth_url=http://$KEYSTONE_HOST:5000/v2.0
  openstack congress datasource create keystone "keystone" \
  --config username=$OS_USERNAME \
  --config tenant_name=$OS_TENANT_NAME \
  --config password=$OS_PASSWORD \
  --config auth_url=http://$KEYSTONE_HOST:5000/v2.0

Run Congress Tempest Tests
..........................

.. code::

  tox -epy27

Restarting after server power loss etc
......................................

Currently this install procedure is manual. Automated install and restoral
after host recovery is TBD. For now, this procedure will get the Congress
service running again.

.. code::

  # On jumphost, SSH to Congress server
  sudo juju ssh ubuntu@192.168.10.117
  # If that fails
    # On jumphost, SSH to controller node
    sudo juju ssh ubuntu@192.168.10.119
    # Start the Congress container
    sudo lxc-start -n juju-trusty-congress -d
    # Verify the Congress container status
    sudo lxc-ls -f juju-trusty-congress
    NAME                  STATE    IPV4            IPV6  GROUPS  AUTOSTART
    ----------------------------------------------------------------------
    juju-trusty-congress  RUNNING  192.168.10.117  -     -       NO
    # exit back to the Jumphost, wait a minute, and go back to the \
    "SSH to Congress server" step above
  # On the Congress server that you have logged into
  source ~/admin-openrc.sh
  cd congress
  source bin/activate
  bin/congress-server &
  disown -h  %1
