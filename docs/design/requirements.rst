Requirements
============
This section outlines general requirements for configuration policies,
per the two main aspects in the Copper project scope:
  * Ensuring resource requirements of VNFs and services are applied per VNF designer, service, and tenant intent
  * Ensuring that generic policies are not violated,
    e.g. *networks connected to VMs must either be public or owned by the VM owner*

Resource Requirements
+++++++++++++++++++++
Resource requirements describe the characteristics of virtual resources (compute, storage, network) that are needed for
VNFs and services, and how those resources should be managed over the lifecycle of a VNF/service. Upstream projects
already include multiple ways in which resource requirements can be expressed and fulfilled, e.g.:
  * OpenStack Nova
    * the `image <http://docs.openstack.org/openstack-ops/content/user_facing_images.html>`_ feature, enabling
      "VM templates" to be defined for NFs, and referenced by name as a specific NF version to be used
    * the `flavor <http://docs.openstack.org/openstack-ops/content/flavors.html>`_ feature, addressing basic compute
      and storage requirements, with extensibility for custom attributes
  * OpenStack Heat
    * the `Heat Orchestration Template <http://docs.openstack.org/developer/heat/template_guide/index.html>`_ feature,
      enabling a variety of VM aspects to be defined and managed by Heat throughout the VM lifecycle, notably
      * alarm handling (requires `Ceilometer <https://wiki.openstack.org/wiki/Ceilometer>`_)
      * attached volumes (requires `Cinder <https://wiki.openstack.org/wiki/Cinder>`_)
      * domain name assignment (requires `Designate <https://wiki.openstack.org/wiki/Designate>`_)
      * images (requires `Glance <https://wiki.openstack.org/wiki/Glance>`_)
      * autoscaling
      * software configuration associated with VM "lifecycle hooks (CREATE, UPDATE, SUSPEND, RESUME, DELETE"
      * wait conditions and signaling for sequencing orchestration steps
      * orchestration service user management (requires `Keystone <http://docs.openstack.org/developer/keystone/>`_)
      * shared storage (requires `Manila <https://wiki.openstack.org/wiki/Manila>`_)
      * load balancing (requires Neutron `LBaaS <http://docs.openstack.org/admin-guide-cloud/content/section_lbaas-overview.html>`_)
      * firewalls (requires Neutron `FWaaS <http://docs.openstack.org/admin-guide-cloud/content/install_neutron-fwaas-agent.html>`_)
      * various Neutron-based network and security configuration items
      * Nova flavors
      * Nova server attributes including access control
      * Nova server group affinity and anti-affinity
      * "Data-intensive application clustering" (requires `Sahara <https://wiki.openstack.org/wiki/Sahara>`_)
      * DBaaS (requires `Trove <http://docs.openstack.org/developer/trove/>`_)
      * "multi-tenant cloud messaging and notification service" (requires `Zaqar <http://docs.openstack.org/developer/zaqar/>`_)
  * OpenStack `Group-Based Policy <https://wiki.openstack.org/wiki/GroupBasedPolicy>`_
    * API-based grouping of endpoints with associated contractual expectations for data flow processing and
      service chaining
  * OpenStack `Tacker <https://wiki.openstack.org/wiki/Tacker>`_
    * "a fully functional ETSI MANO based general purpose NFV Orchestrator and VNF Manager for OpenStack"
  * OpenDaylight `Group-Based Policy <https://wiki.opendaylight.org/view/Group_Based_Policy_(GBP)>`_
    * model-based grouping of endpoints with associated contractual expectations for data flow processing
  * OpenDaylight `Service Function Chaining (SFC) <https://wiki.opendaylight.org/view/Service_Function_Chaining:Main>`_
    * model-based management of "service chains" and the infrastucture that enables them
  * Additional projects that are commonly used for configuration management, implemented as client-server frameworks using model-based, declarative, or scripted configuration management data.
    * `Puppet <https://puppetlabs.com/puppet/puppet-open-source>`_
    * `Chef <https://www.chef.io/chef/>`_
    * `Ansible <http://docs.ansible.com/ansible/index.html>`_
    * `Salt <http://saltstack.com/community/>`_

Generic Policy Requirements
+++++++++++++++++++++++++++
Generic policy requirements address conditions related to resource state and events which need to be monitored for,
and optionally responded to or prevented. These conditions are typically expected to be VNF/service-independent,
as VNF/service-dependent condition handling (e.g. scale in/out) are considered to be addressed by VNFM/NFVO/VIM
functions as described under Resource Requirements or as FCAPS related functions. However the general capabilities
below can be applied to VNF/service-specific policy handling as well, or in particular to invocation of
VNF/service-specific management/orchestration actions. The high-level required capabilities include:
  * Polled monitoring: Exposure of state via request-response APIs.
  * Notifications: Exposure of state via pub-sub APIs.
  * Realtime/near-realtime notifications: Notifications that occur in actual or near realtime.
  * Delegated policy: CRUD operations on policies that are distributed to specific components for local handling,
    including one/more of monitoring, violation reporting, and enforcement.
  * Violation reporting: Reporting of conditions that represent a policy violation.
  * Reactive enforcement: Enforcement actions taken in response to policy violation events.
  * Proactive enforcement: Enforcement actions taken in advance of policy violation events,
    e.g. blocking actions that could result in a policy violation.
  * Compliance auditing: Periodic auditing of state against policies.

Upstream projects already include multiple ways in which configuration conditions can be monitored and responded to:
  * OpenStack `Congress <https://wiki.openstack.org/wiki/Congress>`_ provides a table-based mechanism for state monitoring and proactive/reactive policy enforcement, including (as of the Kilo release) data obtained from internal databases of Nova, Neutron, Ceilometer, Cinder, Glance, Keystone, and Swift. The Congress design approach is also extensible to other VIMs (e.g. SDNCs) through development of data source drivers for the new monitored state information. See `Stackforge Congress Data Source Translators <https://github.com/stackforge/congress/tree/master/congress/datasources>`_, `congress.readthedocs.org <http://congress.readthedocs.org/en/latest/cloudservices.html#drivers>`_, and the `Congress specs <https://github.com/stackforge/congress-specs>`_ for more info.
  * OpenStack `Ceilometer <https://wiki.openstack.org/wiki/Ceilometer>`_ provides means to trigger alarms upon a wide variety of conditions derived from its monitored OpenStack analytics.
  * `Nagios <https://www.nagios.org/#/>`_ "offers complete monitoring and alerting for servers, switches, applications, and services".

Requirements Validation Approach
++++++++++++++++++++++++++++++++
The Copper project will assess the completeness of the upstream project solutions for requirements in scope though
a process of:
  * developing configuration policy use cases to focus solution assessment tests
  * integrating the projects into the OPNFV platform for testing
  * executing functional and performance tests for the solutions
  * assessing overall requirements coverage and gaps in the most complete upstream solutions

Depending upon the priority of discovered gaps, new requirements will be submitted to upstream projects for the next
available release cycle.
