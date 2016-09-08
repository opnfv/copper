.. This work is licensed under a
.. Creative Commons Attribution 4.0 International License.
.. http://creativecommons.org/licenses/by/4.0
.. (c) 2015-2016 AT&T Intellectual Property, Inc

Use Cases
=========

Implemented as of this release
------------------------------

DMZ Deployment
..............

As a service provider, I need to ensure that applications which have not been
designed for exposure in a DMZ zone, are not attached to DMZ networks.

An example implementation is shown in the Congress use case test "DMZ Placement"
(dmz.sh) in the Copper repo under the tests folder. This test:
  * Identifies VMs connected to a DMZ (currently identified through a
    specifically-named security group)
  * Identifes VMs connected to a DMZ, which are by policy not allowed to be
    (currently implemented through an image tag intended to identify images
    that are "authorized" i.e. tested and secure, to be DMZ-connected)
  * Reactively enforces the dmz placement rule by pausing VMs found to be in
    violation of the policy.

As implemented through OpenStack Congress:

.. code::

   dmz_server(x) :-
   nova:servers(id=x,status='ACTIVE'),
   neutronv2:ports(id, device_id, status='ACTIVE'),
   neutronv2:security_group_port_bindings(id, sg),
   neutronv2:security_groups(sg,name='dmz')"

   dmz_placement_error(id) :-
   nova:servers(id,name,hostId,status,tenant_id,user_id,image,flavor,az,hh),
   not glancev2:tags(image,'dmz'),
   dmz_server(id)"

   execute[nova:servers.pause(id)] :-
   dmz_placement_error(id),
   nova:servers(id,status='ACTIVE')"

Configuration Auditing
......................

As a service provider or tenant, I need to periodically verify that resource
configuration requirements have not been violated, as a backup means to proactive
or reactive policy enforcement.

An example implementation is shown in the Congress use case test "SMTP Ingress"
(smtp_ingress.sh) in the Copper repo under the tests folder. This test:
  * Detects that a VM is associated with a security group that allows SMTP
    ingress (TCP port 25)
  * Adds a policy table row entry for the VM, which can be later investigated
    for appropriate use of the security group, etc

As implemented through OpenStack Congress:

.. code::

   smtp_ingress(x) :-
   nova:servers(id=x,status='ACTIVE'),
   neutronv2:ports(port_id, status='ACTIVE'),
   neutronv2:security_groups(sg, tenant_id, sgn, sgd),
   neutronv2:security_group_port_bindings(port_id, sg),
   neutronv2:security_group_rules(sg, rule_id, tenant_id, remote_group_id,
    'ingress', ethertype, 'tcp', port_range_min, port_range_max, remote_ip),
   lt(port_range_min, 26),
   gt(port_range_max, 24)

Reserved Resources
..................

As an NFVI provider, I need to ensure that my admins do not inadvertently
enable VMs to connect to reserved subnets.

An example implementation is shown in the Congress use case test "Reserved
Subnet" (reserved_subnet.sh) in the Copper repo under the tests folder. This
test:
  * Detects that a subnet has been created in a reserved range
  * Reactively deletes the subnet

As implemented through OpenStack Congress:

.. code::

   reserved_subnet_error(x) :-
   neutronv2:subnets(id=x, cidr='10.7.1.0/24')

   execute[neutronv2:delete_subnet(x)] :-
   reserved_subnet_error(x)


For further analysis and implementation
---------------------------------------

Affinity
........

Ensures that the VM instance is launched "with affinity to" specific resources,
e.g. within a compute or storage cluster. Examples include: "Same Host Filter",
i.e. place on the same compute node as a given set of instances, e.g. as defined
in a scheduler hint list.

As implemented by OpenStack Heat using server groups:

*Note: untested example...*

.. code::

  resources:
    servgrp1:
    type: OS::Nova::ServerGroup
    properties:
      policies:
      - affinity
      serv1:
      type: OS::Nova::Server
      properties:
        image: { get_param: image }
        flavor: { get_param: flavor }
        networks:
          - network: {get_param: network}
      serv2:
      type: OS::Nova::Server
      properties:
        image: { get_param: image }
        flavor: { get_param: flavor }
        networks:
          - network: {get_param: network}

Anti-Affinity
.............

Ensures that the VM instance is launched "with anti-affinity to" specific resources,
e.g. outside a compute or storage cluster, or geographic location. Examples
include: "Different Host Filter", i.e. ensures that the VM instance is launched
on a different compute node from a given set of instances, as defined in a
scheduler hint list.

As implemented by OpenStack Heat using scheduler hints:

*Note: untested example...*

.. code::

  heat template version: 2013-05-23
  parameters:
    image:
    type: string
    default: TestVM
    flavor:
    type: string
    default: m1.micro
    network:
    type: string
    default: cirros_net2
  resources:
    serv1:
    type: OS::Nova::Server
    properties:
      image: { get_param: image }
      flavor: { get_param: flavor }
      networks:
        - network: {get_param: network}
      scheduler_hints: {different_host: {get_resource: serv2}}
    serv2:
    type: OS::Nova::Server
    properties:
      image: { get_param: image }
      flavor: { get_param: flavor }
      networks:
        - network: {get_param: network}
      scheduler_hints: {different_host: {get_resource: serv1}}

Network Access Control
......................

Networks connected to VMs must be public, or owned by someone in the VM owner's
group.

This use case captures the intent of the following sub-use-cases:

  * Link Mirroring: As a troubleshooter,
    I need to mirror traffic from physical or virtual network ports so that I
    can investigate trouble reports.
  * Link Mirroring: As a NFVaaS tenant,
    I need to be able to mirror traffic on my virtual network ports so that I
    can investigate trouble reports.
  * Unauthorized Link Mirroring Prevention: As a NFVaaS tenant,
    I need to be able to prevent other tenants from mirroring traffic on my
    virtual network ports so that I can protect the privacy of my service users.
  * Link Mirroring Delegation: As a NFVaaS tenant,
    I need to be able to allow my NFVaaS SP customer support to mirror traffic
    on my virtual network ports so that they can assist in investigating trouble
    reports.

As implemented through OpenStack Congress:

*Note: untested example...*

.. code::

   error :-
   nova:vm(vm),
   neutron:network(network),
   nova:network(vm, network),
   neutron:private(network),
   nova:owner(vm, vm-own),
   neutron:owner(network, net-own),
   -same-group(vm-own, net-own)

   same-group(user1, user2) :-
   ldap:group(user1, g),
   ldap:group(user2, g)


Storage Access Control
......................

Storage resources connected to VMs must be owned by someone in the VM owner's group.

As implemented through OpenStack Congress:

*Note: untested example...*

.. code::

  error :-
  nova:vm(vm),
  cinder:volumes(volume),
  nova:volume(vm, volume),
  nova:owner(vm, vm-own),
  neutron:owner(volume, vol-own),
  -same-group(vm-own, vol-own)

  same-group(user1, user2) :-
  ldap:group(user1, g),
  ldap:group(user2, g)

Resource Reclamation
....................

As a service provider or tenant, I need to be informed of VMs that are
under-utilized so that I can reclaim the VI resources. (example from
`RuleYourCloud blog <http://ruleyourcloud.com/2015/03/12/scaling-up-congress.html>`_)

As implemented through OpenStack Congress:

*Note: untested example...*

.. code::

  reclaim_server(vm) :-
  ceilometer:stats("cpu_util",vm, avg_cpu),
  lessthan(avg_cpu, 1)

  error(user_id, email, vm_name) :-
  reclaim_server(vm),
  nova:servers(vm, vm_name, user_id),
  keystone:users(user_id, email)

Resource Use Limits
...................

As a tenant or service provider, I need to be automatically terminate an
instance that has run for a pre-agreed maximum duration.

As implemented through OpenStack Congress:

*Note: untested example...*

.. code::

  terminate_server(vm) :-
  ceilometer:statistics("duration",vm, avg_cpu),
  lessthan(avg_cpu, 1)

  error(user_id, email, vm_name) :-
  reclaim_server(vm),
  nova:servers(vm, vm_name, user_id),
  keystone:users(user_id, email)

