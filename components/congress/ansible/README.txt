# Copyright 2015-2016 AT&T Intellectual Property, Inc
# This file contains instructions for installing Congress on a Centos7 OPNFV jumphost using Ansible
# Details are sparse so far - a user guide will be written
# Some of these instructions may already have been completed in the copper git Ansible installer files

# INSTALLING

# update
sudo yum -y update

# install ansible (likely already installed)
sudo yum install ansible

# if you got a Dropbox-related error in ansible installation, disable dropbox and repeat ansible install
sudo yum-config-manager --disable Dropbox

# install sshpass (needed for ansible-playbook call with password authentication)
sudo yum install sshpass

# download https://launchpad.net/congress/kilo/2015.1.0/+download/congress-2015.1.0.tar.gz and save in /tmp/congress-2015.1.0.tar.gz
wget https://launchpad.net/congress/kilo/2015.1.0/+download/congress-2015.1.0.tar.gz -O /tmp/congress-2015.1.0.tar.gz

# clone copper
mkdir ~/git
cd ~/git
git clone https://gerrit.opnfv.org/gerrit/copper

# edit hosts.ini and add your controller IP address
gedit ~/git/copper/components/congress/ansible/hosts.ini
[congress_prod_host]
(your controller IP)

# edit deploy_congress.yml and add your controller IP address
# note: this should not be needed, unless the "congress_prod_host" setting in hosts.ini is not picked up for some reason (?)
gedit ~/git/copper/components/congress/ansible/deploy_congress.yml
- hosts: (your controller IP)

# edit config.yml and set authRegion per your openstack install, your controller IP address where needed, publicEndpoint = http:// (not https://)
gedit ~/git/copper/components/congress/ansible/config.yml
authRegion: RegionOne
publicEndpoint = http://(your controller IP):1789/
internalEndpoint = http://(your controller IP):1789/
adminEndpoint = http://(your controller IP):1789/
mysqlDBIP: (your controller IP)

# edit congress.conf and set 
#   bind_host to controller IP address
#   "auth_strategy = noauth" for testing
#   drivers per the list to test (leave out swift due to issues below)
# TODO: auth_strategy noauth is needed to overcome some issue with keystone auth (debug needed)
gedit ~/git/copper/components/congress/ansible/roles/deploy/templates/congress.conf
bind_host = (your controller IP)
auth_strategy = noauth
drivers = congress.datasources.neutronv2_driver.NeutronV2Driver,congress.datasources.glancev2_driver.GlanceV2Driver,congress.datasources.nova_driver.NovaDriver,congress.datasources.keystone_driver.KeystoneDriver,congress.datasources.ceilometer_driver.CeilometerDriver,congress.datasources.cinder_driver.CinderDriver,congress.datasources.swift_driver.SwiftDriver

# add controller host IP to /etc/ansible/hosts
sudo vi /etc/ansible/hosts

# run the ansible playbook
ansible-playbook -vvv -u root -k deploy_congress.yml

# use --start-at-task="task" when restarting to avoid idempotency errors (steps which fail because they have already completed and can't be completed successfully twice)
ansible-playbook -vvv -u root -k deploy_congress.yml --start-at-task="install datasource drivers"

# install congress API test driver
# install lamp server: see https://www.digitalocean.com/community/tutorials/how-to-install-linux-apache-mysql-php-lamp-stack-on-centos-7
sudo yum -y install httpd
sudo yum -y install php
sudo cp -r ~/git/copper/test/congress/driver/www/html/ /var/www/
sudo cp ~/git/copper/test/congress/driver/www/httpd.conf /etc/httpd/conf
sudo systemctl start httpd.service

# UNINSTALLING
# Ansible uninstaller will be developed... for now manual uninstall
# On the controller
openstack endpoint list --os-username=admin --os-tenant-name=admin --os-password=octopus --os-auth-url=http://localhost:35357/v2.0
openstack endpoint delete <id> --os-username=admin --os-tenant-name=admin --os-password=octopus --os-auth-url=http://localhost:35357/v2.0
openstack service list --os-username=admin --os-tenant-name=admin --os-password=octopus --os-auth-url=http://localhost:35357/v2.0
openstack service delete <id> --os-username=admin --os-tenant-name=admin --os-password=octopus --os-auth-url=http://localhost:35357/v2.0
systemctl stop congress-api
sudo rm /etc/init/congress-api.conf
sudo rm -r /opt/congress
sudo rm -r /opt/congress-2015.1.0 
sudo rm -r /var/log/congress
sudo rm -r /usr/lib/python2.7/site-packages/python_congressclient-2015.1.0.dist-info
sudo rm -r /usr/lib/python2.7/site-packages/congressclient/
sudo rm -r /usr/lib/python2.7/site-packages/congress-2015.1.0-py2.7.egg-info
sudo rm -r /etc/congress
sudo rm -r /tmp/congress-2015.1.0.tar.gz
sudo rm -r /tmp/congress.tar.gz
sudo rm -r /var/lib/mysql/congress
sudo rm -r /var/spool/mail/congress
sudo rm -r /usr/bin/congress-server
sudo rm -r /usr/bin/congress-db-manage
sudo rm -r /usr/lib/python2.7/site-packages/congress
sudo rm /usr/lib/systemd/system/congress-api.service
sudo userdel -r congress
find / | grep congress

# find ID of the installed congress services, and remove
openstack service list --os-username=admin --os-tenant-name=admin --os-password=octopus --os-auth-url=http://localhost:35357/v2.0
openstack service delete <id> --os-username=admin --os-tenant-name=admin --os-password=octopus --os-auth-url=http://localhost:35357/v2.0


# DEBUGGING RAW NOTES

# various attempts to get a auth token (failed)
# found SSL issues with creating datasources; set config.yml publicEndpoint to http:// to fix
# to remove endpoints (to cleanup from incorrectly provisoned endpoints)
keystone endpoint-list
keystone endpoint-delete <id> fa7c4b72faef402a919d50e5374705a9

# various issues resulted from trying to create the swift datasource driver. removed for now (see congress.conf notes above)
# server errors reading datasources
2015-11-20 20:02:59.398 17478 ERROR congress.api.application [-] Traceback (most recent call last):
  File "/opt/congress/congress/api/application.py", line 47, in __call__
    response = handler.handle_request(request)
  File "/opt/congress/congress/api/webservice.py", line 351, in handle_request
    return self.list_members(request)
  File "/opt/congress/congress/api/webservice.py", line 375, in list_members
    context=self._get_context(request))
  File "/opt/congress/congress/api/datasource_model.py", line 52, in get_items
    datasources = self.datasource_mgr.get_datasources(filter_secret=True)
  File "/opt/congress/congress/managers/datasource.py", line 138, in get_datasources
    hide_fields = cls.get_driver_info(result['driver'])['secret']
KeyError: 'secret'

vi /opt/congress/congress/managers/datasource.py
remove 
            if filter_secret:
                hide_fields = cls.get_driver_info(result['driver'])['secret']
                for hide_field in hide_fields:
                    result['config'][hide_field] = "<hidden>"
(didn't help)

2015-11-20 19:58:13.021 17478 ERROR congress.api.application [-] Traceback (most recent call last):
  File "/opt/congress/congress/api/application.py", line 47, in __call__
    response = handler.handle_request(request)
  File "/opt/congress/congress/api/webservice.py", line 351, in handle_request
    return self.list_members(request)
  File "/opt/congress/congress/api/webservice.py", line 375, in list_members
    context=self._get_context(request))
  File "/opt/congress/congress/api/datasource_model.py", line 52, in get_items
    datasources = self.datasource_mgr.get_datasources(filter_secret=True)
  File "/opt/congress/congress/managers/datasource.py", line 138, in get_datasources
    return results
KeyError: 'secret'

openstack congress datasource create ceilometer "ceilometer" --debug --os-username=admin --os-tenant-name=admin --os-password=octopus --os-auth-url=http://localhost:35357/v2.0 --config username=admin --config tenant_name=admin --config password=octopus --config auth_url=http://localhost:35357/v2.0

openstack congress datasource create cinder "cinder" --debug --os-username=admin --os-tenant-name=admin --os-password=octopus --os-auth-url=http://localhost:35357/v2.0 --config username=admin --config tenant_name=admin --config password=octopus --config auth_url=http://localhost:35357/v2.0

openstack congress datasource create glancev2 "glancev2" --debug --os-username=admin --os-tenant-name=admin --os-password=octopus --os-auth-url=http://localhost:35357/v2.0 --config username=admin --config tenant_name=admin --config password=octopus --config auth_url=http://localhost:35357/v2.0

openstack congress datasource create keystone "keystone" --debug --os-username=admin --os-tenant-name=admin --os-password=octopus --os-auth-url=http://localhost:35357/v2.0 --config username=admin --config tenant_name=admin --config password=octopus --config auth_url=http://localhost:35357/v2.0

openstack congress datasource create neutronv2 "neutronv2" --debug --os-username=admin --os-tenant-name=admin --os-password=octopus --os-auth-url=http://localhost:35357/v2.0 --config username=admin --config tenant_name=admin --config password=octopus --config auth_url=http://localhost:35357/v2.0

openstack congress datasource create nova "nova" --debug --os-username=admin --os-tenant-name=admin --os-password=octopus --os-auth-url=http://localhost:35357/v2.0 --config username=admin --config tenant_name=admin --config password=octopus --config auth_url=http://localhost:35357/v2.0

openstack congress datasource create swift "swift" --debug --os-username=admin --os-tenant-name=admin --os-password=octopus --os-auth-url=http://localhost:35357/v2.0 --config username=admin --config tenant_name=admin --config password=octopus --config auth_url=http://localhost:35357/v2.0


+++++++++++++++++++
curl -s -X POST http://192.168.1.204:5000/v2.0/tokens \
            -H "Content-Type: application/json" \
            -d '{"auth": {"tenantName": "'"$OS_TENANT_NAME"'", "passwordCredentials":
            {"username": "'"$OS_USERNAME"'", "password": "'"$OS_PASSWORD"'"}}}' \
            | python -m json.tool

export OS_TOKEN=(token from the response)

curl -d '{"auth":{"passwordCredentials":{"username": "admin", "password": "octopus"}}}' -H "Content-type: application/json" http://192.168.1.204:35357/v2.0/tokens | python -m json.tool

curl -d '{"auth":{"passwordCredentials":{"username": "admin", "password": "octopus"}}}' -H "Content-type: application/json" http://192.168.1.204:5000/v2.0/tokens

curl -v -s -X POST http://192.168.1.204:5000/v2.0/tokens -H "Content-Type: application/json" -d '{"auth":{"passwordCredentials":{"username": "admin", "password": "octopus"}}}'

curl -v -d '{"auth":{"passwordCredentials":{"username": "admin", "password": "octopus"}}}' http://192.168.1.204:1789/v1/policies

curl -v -d '{"auth": {"tenantName": "'"$OS_TENANT_NAME"'", "passwordCredentials":
            {"username": "'"$OS_USERNAME"'", "password": "'"$OS_PASSWORD"'"}}}' http://192.168.1.204:1789/v1/policies


curl -i \
  -H "Content-Type: application/json" \
  -H "X-Auth-Token: $OS_TOKEN" \
  -d '
{ "auth": {
    "identity": {
      "methods": ["token"],
      "token": {
        "id": "'$OS_TOKEN'"
      }
    }
  }
}' \
http://192.168.1.204:1789/v1/policies ; echo


