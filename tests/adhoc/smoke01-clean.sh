#!/bin/bash
set -x #echo on

instance=$(nova list | awk "/ cirros1 / { print \$2 }")
if [ "$instance" != "" ]; then nova delete $instance
fi

instance=$(nova list | awk "/ cirros2 / { print \$2 }")
if  [ "$instance" != "" ]; then nova delete $instance
fi

router=$(neutron router-list | awk "/ external / { print \$2 }")

internal_interface=$(neutron router-port-list $router | grep 10.0.0.1 | awk '{print $2}')

if [ "$internal_interface" != "" ]; then neutron router-interface-delete $router port=$internal_interface
fi

public_interface=$(neutron router-port-list $router | grep 191.168.10.2 | awk '{print $2}')

if [ "$public_interface" != "" ]; then neutron router-interface-delete $router port=$public_interface
fi

neutron router-interface-delete $router $internal_interface

neutron router-gateway-clear external

neutron router-delete external

port=$(neutron port-list | awk "/ 10.0.0.1 / { print \$2 }")

if [ "$port" != "" ]; then neutron port-delete $port
fi

port=$(neutron port-list | awk "/ 10.0.0.2 / { print \$2 }")

if [ "$port" != "" ]; then neutron port-delete $port
fi

neutron subnet-delete internal

neutron net-delete internal

neutron subnet-delete public

neutron net-delete public

set +x #echo off
