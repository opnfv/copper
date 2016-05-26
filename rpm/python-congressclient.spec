%define debug_package %{nil}

Name:		python-congressclient
Version:	2016.1
Release:	1%{?dist}
Summary:	OpenStack policy manager client

Group:		Applications/Internet
License:	Apache 2.0
URL:		https://wiki.openstack.org/wiki/Congress/Installation
Source0:	python-congressclient.tar.gz

BuildArch:	noarch
BuildRequires:	python-setuptools
 #antlr-python python2-oslo-config python2-debtcollector
#Requires:	pbr>=0.8 Paste PasteDeploy>=1.5.0 Routes>=1.12.3!=2.0 anyjson>=0.3.3 argparse
#Requires:	Babel>=1.3 eventlet>=0.16.1!=0.17.0 greenlet>=0.3.2 httplib2>=0.7.5 requests>=2.2.0!=2.4.0
#Requires:	iso8601>=0.1.9 kombu>=2.5.0 netaddr>=0.7.12 SQLAlchemy<1.1.0>=0.9.7
#Requires:	WebOb>=1.2.3 python-heatclient>=0.3.0 python-keystoneclient>=1.1.0 alembic>=0.7.2 six>=1.9.0
#Requires:	stevedore>=1.5.0 http oslo.config>=1.11.0 oslo.messaging!=1.17.0!=1.17.1>=1.16.0 oslo.rootwrap>=2.0.0 python-novaclient>=2.22.0 

%description
OpenStack policy manager client

%prep
#git archive --format=tar.gz --prefix=python-congressclient-%{version}/ HEAD > python-congressclient.tar.gz
%setup -q


%build
rm requirements.txt
#/usr/bin/python setup.py build


%install
/usr/bin/python setup.py install --prefix=%{buildroot} --install-lib=%{buildroot}/usr/lib/python2.7/site-packages

%files

#%config /etc/congress/congress.conf
#/etc/congress/policy.json
#/etc/congress/api-paste.ini
#/bin/congress-server
#/bin/congress-db-manage
/usr/lib/python2.7/site-packages/congressclient/*
/usr/lib/python2.7/site-packages/python_congressclient-*
#/usr/lib/python2.7/site-packages/congress_tempest_tests/*
#/usr/lib/python2.7/site-packages/antlr3runtime/*

%changelog

