.. This work is licensed under a
.. Creative Commons Attribution 4.0 International License.
.. http://creativecommons.org/licenses/by/4.0
.. (c) 2015-2016 AT&T Intellectual Property, Inc

Release Notes
=============

Copper Release 1 Scope
----------------------
OPNFV Brahmaputra was the initial OPNFV release for Copper, and achieved the
goals:
  * Add the OpenStack Congress service to OPNFV, through at least one installer
    project, through post-install configuration.
  * Provide basis tests scripts and tools to exercise the Congress service

Copper Release 2 Scope
----------------------
OPNFV Colorado includes the additional features:
  * Congress support in the the OPNFV CI/CD pipeline for the JOID and Apex
    installers, through the following projects being upstreamed to OpenStack:

    * For JOID, a JuJu Charm for Congress
    * For Apex, a Puppet Module for Congress

  * Congress use case tests integrated into Functest and as manual tests
  * Further enhancements of Congress test tools

Limitations
===========

The following features have not been verified as of this release:

  * HA deployment: Congress should be installed in OPNFV deployments in a
    non-HA mode, including in HA deployment scenarios. Basic HA support was
    implemented for Congress in the Mitaka release (see
    https://review.openstack.org/#/q/topic:bp/basic-high-availability,n,z), but
    this feature has not yet been verified on the OPNFV platform.

  * Horizon plugin: The Congress Horizon plugin (a "policy tab") has not been
    deployed in OPNFV as of this release. Installing the needed Horizon plugin
    files on the Horizon host is a future work item.
