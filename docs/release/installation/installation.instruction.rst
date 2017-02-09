.. This work is licensed under a Creative Commons Attribution 4.0 International License.
.. http://creativecommons.org/licenses/by/4.0

===============================
OPNFV Copper Installation Guide
===============================

This document describes how to install Copper, its dependencies and required system resources.

.. contents::
   :depth: 3
   :local:

Version History
---------------

+--------------------+--------------------+--------------------+--------------------+
| **Date**           | **Ver.**           | **Author**         | **Comment**        |
|                    |                    |                    |                    |
+--------------------+--------------------+--------------------+--------------------+
| 2017 Feb 7         | 1.0                | Bryan Sullivan     |                    |
|                    |                    |                    |                    |
+--------------------+--------------------+--------------------+--------------------+

Introduction
------------
The Congress service is automatically configured as required by the JOID and
Apex installers, including creation of datasources per the installed datasource
drivers. This release includes default support for the following datasource drivers:

  * nova
  * neutronv2
  * ceilometer
  * cinder
  * glancev2
  * keystone

For JOID, Congress is installed through a JuJu Charm, and for Apex through a
Puppet Module. Both the Charm and Module are being upstreamed to OpenStack for
future maintenance.

Other project installer support (e.g. Doctor) may install additional datasource
drivers once Congress is installed.

Manual Installation
-------------------

NOTE: This section describes a manual install procedure that had been tested
under the JOID and Apex base installs prior to the integration of native
installer support through JuJu (JOID) and Puppet (Apex). This procedure is being
maintained as a basis for additional installer support in future releases.
However, since Congress is pre-installed for JOID and Apex, this procedure is not
necessary and not recommended for use if Congress is already installed.

Copper provides a set of bash scripts to automatically install Congress based
upon a JOID or Apex install which does not already have Congress installed.
These scripts are in the Copper repo at:

  * components/congress/install/bash/install_congress_1.sh
  * components/congress/install/bash/install_congress_2.sh

Prerequisites to using these scripts:

  * OPFNV installed via JOID or Apex
  * For Apex installs, on the jumphost, ssh to the undercloud VM and "su stack".
  * For JOID installs, admin-openrc.sh saved from Horizon to ~/admin-openrc.sh
  * Retrieve the copper install script as below, optionally specifying the branch
    to use as a URL parameter, e.g. ?h=stable%2Fbrahmaputra

To invoke the procedure, enter the following shell commands, optionally
specifying the branch identifier to use for OpenStack.

.. code::

   cd ~
   wget https://git.opnfv.org/cgit/copper/plain/components/congress/install/bash/install_congress_1.sh
   wget https://git.opnfv.org/cgit/copper/plain/components/congress/install/bash/install_congress_2.sh
   bash install_congress_1.sh [openstack-branch]
