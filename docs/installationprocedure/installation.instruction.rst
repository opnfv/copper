.. This work is licensed under a
.. Creative Commons Attribution 4.0 International License.
.. http://creativecommons.org/licenses/by/4.0
.. (c) 2015-2017 AT&T Intellectual Property, Inc

Copper Post Installation Procedures
===================================

This section describes optional procedures for verifying that the Congress
service is operational as well as additional test tools developed for the Colorado
release.

Copper Functional Tests
-----------------------

This release includes the following test cases which are integrated into OPNFV
Functest for the JOID and Apex installers:
  * DMZ Placement: dmz.sh
  * SMTP Ingress: smtp_ingress.sh
  * Reserved Subnet: reserved_subnet.sh

These scripts, related scripts that clean up the OpenStack environment afterward,
and a combined test runner (run.sh) are in the Copper repo under the "tests"
folder. Instructions for using the tests are provided as script comments.

Further description of the tests is provided on the Copper wiki at
https://wiki.opnfv.org/display/copper/testing.


Congress Test Webapp
--------------------

This release also provides a webapp that can be automatically installed in a
Docker container on the OPNFV jumphost. This script is in the Copper repo at:
  * components/congress/test-webapp/setup/install_congress_testserver.sh

Prerequisites for using this script:
  * OPFNV installed per JOID or Apex installer
  * For Apex installs, on the jumphost, ssh to the undercloud VM and "su stack"

To invoke the procedure, enter the following shell commands, optionally
specifying the branch identifier to use for Copper:

.. code::

   wget https://git.opnfv.org/cgit/copper/plain/components/congress/test-webapp/setup/install_congress_testserver.sh
   bash install_congress_testserver.sh [copper-branch]

Using the Test Webapp
.....................

Browse to the webapp IP address provided at the end of the install
procedure.

Interactive options are meant to be self-explanatory given a basic familiarity
with the Congress service and data model.

Removing the Test Webapp
........................

The webapp can be removed by running this script from the Copper repo:
  * components/congress/test-webapp/setup/clean_congress_testserver.sh

