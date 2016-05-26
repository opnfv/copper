#!/bin/sh
##############################################################################
# Copyright (c) 2016 Dan Radez (Red Hat) and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

pushd ../rpm > /dev/null

############################
# Build OpenStack Congress
############################

#clean up incase dir exists
rm -rf congress

#clone congress from upstream
git clone https://github.com/openstack/congress

# add service script and build tarball
cp ../rpm/openstack-congress.service congress
pushd congress > /dev/null
git checkout stable/mitaka
git add openstack-congress.service
git commit -m 'adding service script'
git archive --format=tar.gz --prefix=openstack-congress-2016.1/ stable/mitaka > ../openstack-congress.tar.gz
popd > /dev/null

#cleanup after tarball build
rm -rf congress

#build the rpm
rpmbuild -ba ../rpm/openstack-congress.spec

###############################
# Build Python Congress Client
###############################

#clean up incase dir exists
rm -rf python-congressclient

#clone congress from upstream
git clone https://github.com/openstack/python-congressclient

# build tarball
pushd python-congressclient > /dev/null
git checkout stable/mitaka
git archive --format=tar.gz --prefix=python-congressclient-2016.1/ stable/mitaka > ../python-congressclient.tar.gz
popd > /dev/null

#cleanup after tarball build
rm -rf python-congressclient

#build the rpm
rpmbuild -ba ../rpm/python-congressclient.spec

popd > /dev/null
