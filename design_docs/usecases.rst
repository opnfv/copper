Use Cases
=========

NFVI Self-Service Constraints
-----------------------------

As an NFVI provider, I need to ensure that my self-service tenants are not able to configure their VNFs in ways that would impact other tenants or the reliability, security, etc of the NFVI.

Example: Network Access Control
...............................

Networks connected to VMs must be public, or owned by someone in the VM owner's group.

This use case captures the intent of the following sub-use-cases:

  * Link Mirroring: As a troubleshooter, I need to mirror traffic from physical or virtual network ports so that I can investigate trouble reports.
  * Link Mirroring: As a NFVaaS tenant, I need to be able to mirror traffic on my virtual network ports so that I can investigate trouble reports.
  * Unauthorized Link Mirroring Prevention: As a NFVaaS tenant, I need to be able to prevent other tenants from mirroring traffic on my virtual network ports so that I can protect the privacy of my service users.
  * Link Mirroring Delegation: As a NFVaaS tenant, I need to be able to allow my NFVaaS SP customer support to mirror traffic on my virtual network ports so that they can assist in investigating trouble reports.

As implemented through OpenStack Congress: 

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
--------------------

As a service provider or tenant, I need to be informed of VMs that are under-utilized so that I can reclaim the VI resources. (example from `RuleYourCloud blog <http://ruleyourcloud.com/2015/03/12/scaling-up-congress.html>`_) 

As implemented through OpenStack Congress: 

.. code:: 

  reclaim_server(vm) :-
  ceilometer:stats("cpu_util",vm, avg_cpu),
  lessthan(avg_cpu, 1)

  error(user_id, email, vm_name) :-
  reclaim_server(vm),
  nova:servers(vm, vm_name, user_id),
  keystone:users(user_id, email)

Workload Placement
------------------

Affinity
........

Ensures that the VM instance is launched "with affinity to" specific resources, e.g. within a compute or storage cluster. This is analogous to the affinity rules in `VMWare vSphere DRS <https://pubs.vmware.com/vsphere-50/topic/com.vmware.vsphere.resmgmt.doc_50/GUID-FF28F29C-8B67-4EFF-A2EF-63B3537E6934.html>`_. Examples include: "Same Host Filter", i.e. place on the same compute node as a given set of instances, e.g. as defined in a scheduler hint list.

Anti-Affinity
.............

Ensures that the VM instance is launched "with anti-affinity to" specific resources, e.g. outside a compute or storage cluster, or geographic location. This filter is analogous to the anti-affinity rules in vSphere DRS. Examples include: "Different Host Filter", i.e. ensures that the VM instance is launched on a different compute node from a given set of instances, as defined in a scheduler hint list.

Configuration Auditing
----------------------

As a service provider or tenant, I need to periodically verify that resource configuration requirements have not been violated, as a backup means to proactive or reactive policy enforcement.

