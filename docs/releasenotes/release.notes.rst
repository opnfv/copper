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
